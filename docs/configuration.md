# Configuration

| Variable | Default | Description |
|---|---|---|
| `JEFF_API_KEYS` | — (required) | Comma-separated bearer keys |
| `JEFF_ALLOW_NO_AUTH` | `false` | Allow empty keys (local tests only) |
| `JEFF_DOCKER_TAG` | `latest` | GHCR tag |
| `JEFF_REF` | `main` | Upstream Jeff git ref (build) |
| `UV_EXTRAS` | `dev` | uv extras (`dev`, `onnx`) |
| `JEFF_MODEL_ID` | `knowledgator/gliformer-large-v1` | HF repo |
| `JEFF_MODEL_PATH` | `/models/gliformer-large-v1` | Model dir in volume |
| `JEFF_MODEL_REVISION` | `main` | HF revision; pin a commit for reproducibility |
| `JEFF_DOWNLOAD_MODEL` | `true` | Download when missing |
| `JEFF_FORCE_MODEL_DOWNLOAD` | `false` | Re-download on next start |
| `HF_TOKEN` | — | Optional HF token |
| `JEFF_DEVICE` | `cpu` | `cpu`, `cuda`, `mps` |
| `JEFF_BACKEND` | `torch` | `torch` or `onnx` |
| `JEFF_QUANT` | — | `int8` with ONNX |
| `JEFF_THREADS` | `6` | Torch/OMP threads |
| `JEFF_MAX_BATCH` | `8` | Dynamic batch size |
| `JEFF_MAX_WAIT_MS` | `10` | Batch wait window |
| `JEFF_WARMUP` | `1` | Warm-up at start |
| `JEFF_RATE_LIMIT_RPS` / `_BURST` | `4` / `8` | Per-key rate limit |
| `JEFF_BIND` / `JEFF_HOST_PORT` | `127.0.0.1` / `8000` | Host binding (non-Dokploy) |
| `JEFF_CPU_LIMIT` / `JEFF_MEM_LIMIT` | `8` / `10g` | Dokploy limits |

## ONNX INT8 (optional)

```bash
UV_EXTRAS=onnx docker compose build
docker compose run --rm --entrypoint python jeff scripts/export_onnx.py /models/gliformer-large-v1 --int8
```
Then `JEFF_BACKEND=onnx`, `JEFF_QUANT=int8`. Only the encoder runs in ONNX.
