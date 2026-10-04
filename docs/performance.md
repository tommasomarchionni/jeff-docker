# Performance (CPU)

Jeff on CPU is a good fit for **asynchronous or low/medium-traffic
classification**: ticket triage, email/notification routing, tagging,
Home Assistant automations, backend jobs. It is not meant for
per-keystroke UI or high-concurrency public APIs.

## Measured numbers

Measured by this project (warm server, 3 questions — score, choice, noul —
on a ~80-character text, single client):

| Hardware | Model | Backend | Latency |
|---|---|---|---|
| 2 vCPU Intel Xeon 2.9 GHz (cloud VM) | base | torch fp32 | ~190 ms |
| 2 vCPU Intel Xeon 2.9 GHz (cloud VM) | base | onnx int8 | ~110 ms |

The weekly [smoke test](testing.md) records a latency sample in the
GitHub Actions job summary on a standard 4-vCPU runner.

**Rules of thumb** (to verify on your hardware):

- `gliformer-large-v1` costs roughly **1.5–2×** the base model.
- Latency grows with text length, number of questions and labels.
- A modern 8-core CPU (e.g. Ryzen 9 8945HS) is several times faster than
  the 2-vCPU VM above.
- Model load + warm-up: ~6 s (base) to ~15 s (large) after the download.

## Tuning

| Goal | Change |
|---|---|
| Lower latency, single client | `JEFF_MAX_WAIT_MS=0`–`5`, `JEFF_THREADS` = physical cores |
| Higher throughput, many clients | `JEFF_MAX_BATCH=16`, `JEFF_MAX_WAIT_MS=10`–`20` |
| Fastest CPU path | `JEFF_BACKEND=onnx`, `JEFF_QUANT=int8` ([ONNX](onnx.md)) |
| Keep the host responsive | `JEFF_THREADS` < cores, `JEFF_CPU_LIMIT` |
| Protect from bursts | `JEFF_RATE_LIMIT_RPS`, `JEFF_MAX_QUEUE` |
| Shorter prompts | Concise `instructions` and label descriptions |

Threads: on SMT CPUs, **physical cores** usually beat logical threads.
On an 8-core/16-thread CPU start with `JEFF_THREADS=6` (leaves headroom),
then try `8`.

## Benchmark

Use [`hey`](https://github.com/rakyll/hey) or
[`oha`](https://github.com/hatoo/oha) from another machine on the LAN:

```bash
cat > req.json <<'JSON'
{"state":"The export button crashes on Safari and users cannot download reports.",
 "model":"jev-latest",
 "questions":{
   "severity":{"type":"score","instructions":"How severe?","criteria":["cosmetic","degraded","blocking"]},
   "area":{"type":"choice","criteria":{"frontend":null,"backend":null,"infra":null}}}}
JSON

for c in 1 4 8; do
  echo "== concurrency $c"
  hey -n 200 -c $c -m POST -T application/json -D req.json \
    -H "Authorization: Bearer $JEFF_KEY" http://jeff.home.lan/v1/systemone \
    | grep -E 'Requests/sec|50%|95%|99%'
done
```

Disable the rate limit while benchmarking (`JEFF_RATE_LIMIT_RPS=0`), watch
resources with `docker stats jeff`, and read server-side timings from the
`x-jeff-server-ms` header and `/stats` (`avg_infer_ms`, `avg_queue_ms`,
`avg_batch`).

Compare at least: `JEFF_THREADS` 6 vs 8, `torch` vs `onnx`+`int8`, base vs
large. Contributions of benchmark results via PR are welcome.
