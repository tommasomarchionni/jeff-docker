# ONNX backend (faster CPU inference)

Jeff can run the encoder through ONNX Runtime, optionally quantized to
**int8**. The RNN and classification heads stay in PyTorch, so this is a
partial acceleration, but the encoder is the expensive part.

The image already contains ONNX Runtime (`UV_EXTRAS=onnx`): no rebuild
needed.

## Enable it

```dotenv
JEFF_BACKEND=onnx
JEFF_QUANT=int8      # or fp32
JEFF_THREADS=6
```

Redeploy. On the **first** start Jeff exports the encoder into
`<JEFF_MODEL_PATH>/onnx/` (≈10–60 s and ~0.7–1.6 GB extra disk), then
reuses it:

```text
INFO jeff.onnx: .../onnx/encoder.int8.onnx missing; exporting the encoder now
INFO jeff.onnx: onnx encoder ready: .../encoder.int8.onnx quant=int8 providers=['CPUExecutionProvider']
```

## What to expect

Measured by this project on `gliformer-base-v1`, 2 vCPU (Intel Xeon
2.9 GHz), 3 questions on a short text, warm server:

| Backend | Latency per request |
|---|---|
| `torch` fp32 | ~190 ms |
| `onnx` int8 | ~110 ms |

int8 changes probabilities slightly (quantization): validate on your own
data before switching production traffic. Re-run the
[benchmark](performance.md#benchmark) on your hardware.

## Exporting manually (optional)

```bash
docker compose exec jeff python /app/scripts/export_onnx.py /models/gliformer-large-v1 --int8
```

## Going back

Set `JEFF_BACKEND=torch` and redeploy. The ONNX files can stay; delete them
with `docker compose exec jeff rm -rf /models/gliformer-large-v1/onnx`.
