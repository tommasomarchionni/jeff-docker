# Using the API

Jeff exposes a small HTTP API compatible with the TypeSafe **jev** wire
format. All `/v1/*` endpoints need `Authorization: Bearer <JEFF_API_KEYS
entry>`.

| Method | Path | Auth | Purpose |
|---|---|---|---|
| `POST` | `/v1/systemone` | yes | Answer classification questions about a text |
| `GET` | `/v1/models` | yes | List model name and aliases (`jev-latest`, `jev`) |
| `GET` | `/healthz` | no | Liveness/readiness (used by the Docker healthcheck) |
| `GET` | `/stats` | no | Batcher counters and active configuration |

Errors: **401** missing/invalid key, **422** validation error or request
limit exceeded, **429** rate limit (`retry-after-ms` header), **529**
queue full. Responses carry `x-typesafe-request-id`, `x-jeff-server-ms` and
`x-jeff-batcher-ms` headers.

## Request anatomy

```json
{
  "state": "The text to classify (string, or a JSON object)",
  "model": "jev-latest",
  "questions": {
    "<your-question-id>": { "type": "score | choice | noul", "instructions": "...", "criteria": ... }
  }
}
```

### `score` — ordinal scale

`criteria` is an **ordered list** of levels (low → high). The answer has a
continuous `score` (0 … n-1), per-level `probabilities`, `confidence` and a
`legend`.

```json
"severity": {"type": "score", "instructions": "How severe is this?",
             "criteria": ["cosmetic", "degraded", "blocking"]}
```

### `choice` — pick one label

`criteria` is an **object**: label → description (or `null`).

```json
"area": {"type": "choice", "instructions": "Which area is affected?",
         "criteria": {"frontend": "UI and browser", "backend": "API and server", "infra": null}}
```

### `noul` — yes/no probability

No criteria needed; returns `noul` between 0 and 1.

```json
"regression": {"type": "noul", "instructions": "Is this a regression?"}
```

### Example response

```json
{
  "model": "gliformer-large-v1",
  "answers": {
    "severity": {"type": "score", "score": 1.27, "confidence": 0.08,
                 "legend": {"0": "cosmetic", "1": "degraded", "2": "blocking"},
                 "probabilities": {"0": 0.30, "1": 0.31, "2": 0.39}},
    "area": {"type": "choice", "choice": "frontend", "confidence": 0.56,
             "probabilities": {"frontend": 0.71, "backend": 0.15, "infra": 0.14}},
    "regression": {"type": "noul", "noul": 0.15}
  },
  "usage": {"input_tokens": 77, "output_tokens": 18}
}
```

## Clients

=== "curl"

    ```bash
    curl -s https://jeff.example.com/v1/systemone \
      -H "Authorization: Bearer $JEFF_KEY" -H "Content-Type: application/json" \
      -d '{"state":"Payment page times out","model":"jev-latest",
           "questions":{"urgent":{"type":"noul","instructions":"Is this urgent?"}}}' | jq
    ```

=== "Python"

    ```python
    import os, httpx

    client = httpx.Client(
        base_url="http://127.0.0.1:8000",
        headers={"Authorization": f"Bearer {os.environ['JEFF_KEY']}"},
        timeout=30,
    )
    r = client.post("/v1/systemone", json={
        "state": "Payment page times out",
        "model": "jev-latest",
        "questions": {
            "severity": {"type": "score", "criteria": ["low", "medium", "high"]},
        },
    })
    r.raise_for_status()
    print(r.json()["answers"]["severity"]["score"])
    ```

=== "TypeScript"

    ```ts
    type ScoreAnswer = { type: "score"; score: number; confidence: number;
                         probabilities: Record<string, number> };

    const res = await fetch("http://127.0.0.1:8000/v1/systemone", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.JEFF_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        state: "Payment page times out",
        model: "jev-latest",
        questions: { severity: { type: "score", criteria: ["low", "medium", "high"] } },
      }),
    });
    if (!res.ok) throw new Error(`Jeff ${res.status}: ${await res.text()}`);
    const { answers } = (await res.json()) as { answers: { severity: ScoreAnswer } };
    console.log(answers.severity.score);
    ```

=== "Home Assistant"

    ```yaml
    # configuration.yaml
    rest_command:
      jeff_classify:
        url: "http://jeff.home.lan/v1/systemone"
        method: POST
        headers:
          Authorization: !secret jeff_bearer   # "Bearer <key>"
          Content-Type: application/json
        payload: >
          {"state": {{ text | tojson }}, "model": "jev-latest",
           "questions": {"urgent": {"type": "noul", "instructions": "Is this urgent?"}}}
        timeout: 15
    ```

    Call it from an automation with `response_variable` and branch on
    `response.content.answers.urgent.noul > 0.7`.

=== "TypeSafe SDK"

    The wire format is compatible with the official jev SDK: point the SDK
    base URL to your Jeff instance and use one of your `JEFF_API_KEYS` as the
    API key. Model behavior differs from the hosted jev service (see below).

## Differences from hosted jev

From upstream: probabilities are temperature-scaled sigmoids
(`JEFF_TEMPERATURE`, default 3.2); `noul` questions get separate encoder
passes while `choice`/`score` share one (set `JEFF_ISOLATE=all` for full
independence at extra cost); token counts are not comparable to jev billing.
Upstream also reports lower accuracy than jev on harder reasoning tasks.

## Good practices

- **Be explicit** in `instructions` and label descriptions: they are part
  of the prompt.
- **Keep `state` short** (limit: `JEFF_MAX_STATE_CHARS`, default 20 000):
  latency grows with length.
- **Group questions** about the same text in one request rather than
  sending many requests.
- **Handle 429/529** with retry and backoff (honor `retry-after-ms`).
- Use **one key per client** (comma-separated in `JEFF_API_KEYS`) so you
  can revoke them independently.
