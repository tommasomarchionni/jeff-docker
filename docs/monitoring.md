# Monitoring and logs

## Health

- `GET /healthz` → `{"ok":true,"model":"..."}` (no auth). Used by the image
  `HEALTHCHECK` (30 s interval, 300 s start period for the first download).
- `docker inspect -f '{{.State.Health.Status}}' jeff` → `starting`,
  `healthy`, `unhealthy`.

Uptime Kuma / Gatus: HTTP check on `https://jeff.example.com/healthz`,
expect `200` and keyword `"ok":true`.

## Stats

`GET /stats` returns batcher counters and the active configuration:

```json
{"batches": 42, "requests": 97, "avg_batch": 2.3, "max_batch": 8,
 "avg_infer_ms": 180.4, "avg_queue_ms": 6.1,
 "backend": {"backend": "torch", "device": "cpu", "dtype": "float32", "load_seconds": 6.0}}
```

!!! warning
    `/stats` is not authenticated upstream. It exposes configuration (no
    secrets). On a public domain you may block it at the proxy, see
    [Security](security.md#reverse-proxy-hardening).

## Logs

```bash
docker compose logs -f jeff            # Compose
docker logs -f jeff                    # plain Docker
```

Startup lines to look for:

```text
[entrypoint] Model already present: knowledgator/gliformer-large-v1@main at /models/gliformer-large-v1
[entrypoint] jeff-docker 0.2.0 | upstream Jeff 1a2b3c4d5e6f
[entrypoint] device=cpu backend=torch threads=6 max_batch=8 auth=on
... jeff ready: backend=torch model=gliformer-large-v1
```

Log rotation is preconfigured in the Compose files (`json-file`, 3 × 10 MB).

## Resources

```bash
docker stats jeff
```

Alert if memory stays close to `JEFF_MEM_LIMIT` (risk of OOM kill, exit
code 137).
