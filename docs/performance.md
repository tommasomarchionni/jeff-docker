# Performance (CPU)

No published benchmark exists for Jeff on Ryzen 9 8945HS. Expect hundreds of ms to a few
seconds per request depending on text length, number of questions and labels.

Good fit: ticket triage, email/notification classification, Home Assistant automations, async jobs.
Poor fit: per-keystroke UI, high-concurrency public APIs.

## Initial target (to be measured)

- Short text (300–800 chars), 1 question, ≤10 labels, concurrency 1
- p50 < 2 s, p95 < 4 s, no OOM

## Benchmark

```bash
# requires: hey (https://github.com/rakyll/hey)
cat > /tmp/req.json <<'J'
{"state":"Export button crashes on Safari.","model":"jev-latest",
 "questions":{"severity":{"type":"score","instructions":"How severe?",
 "criteria":["cosmetic","degraded","blocking"]}}}
J
for c in 1 4 8; do
  hey -n 100 -c $c -m POST -T application/json -D /tmp/req.json \
    -H "Authorization: Bearer $JEFF_API_KEYS" http://127.0.0.1:8000/v1/systemone
done
docker stats --no-stream
```

Compare `JEFF_THREADS` 6 vs 8 and `torch` vs `onnx`+`int8`. Record results in this page.
