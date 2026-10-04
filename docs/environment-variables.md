# Environment variables

All configuration happens through environment variables (`.env` for
Compose, the Environment tab in Dokploy, `-e` for `docker run`). Empty
values are dropped by the entrypoint so upstream defaults apply.

## jeff-docker (image and entrypoint)

| Variable | Default | Description |
|---|---|---|
| `JEFF_API_KEYS` | — **required** | Comma-separated bearer keys. Container exits if empty |
| `JEFF_ALLOW_NO_AUTH` | `false` | Allow empty keys. Local tests only |
| `JEFF_MODEL_ID` | `knowledgator/gliformer-large-v1` | Hugging Face repo to download |
| `JEFF_MODEL_PATH` | `/models/gliformer-large-v1` | Where the weights live (inside the `/models` volume) |
| `JEFF_MODEL_REVISION` | `main` | HF branch, tag or commit; pin a commit for reproducibility |
| `JEFF_DOWNLOAD_MODEL` | `true` | Download when missing. `false` = fail if the directory is empty |
| `JEFF_FORCE_MODEL_DOWNLOAD` | `false` | Download again on next start (then set back to `false`) |
| `HF_TOKEN` | — | Hugging Face token for private/gated repos or higher rate limits |

## Compose / container

| Variable | Default | Used by | Description |
|---|---|---|---|
| `JEFF_DOCKER_TAG` | `latest` | prebuilt, dokploy | GHCR tag to run |
| `JEFF_REF` | `main` | local build | Upstream Jeff ref |
| `UV_EXTRAS` | `onnx` | local build | Upstream extras |
| `TORCH_INDEX_URL` | CPU index | local build | PyTorch wheel index |
| `JEFF_CONTAINER_NAME` | `jeff` | local, prebuilt | Container name |
| `JEFF_VOLUME_PREFIX` | `jeff` | local, prebuilt | Volume names `<prefix>-models`, `<prefix>-data` |
| `JEFF_BIND` | `127.0.0.1` | local, prebuilt | Host interface for the port |
| `JEFF_HOST_PORT` | `8000` | local, prebuilt | Host port |
| `JEFF_CPU_LIMIT` | `0` (no limit) | all | CPU limit (`cpus`). Must be ≤ CPUs visible to Docker (`nproc`), otherwise the deploy fails with "range of CPUs is from 0.01 to N" |
| `JEFF_MEM_LIMIT` | `10g` | all | Memory limit (`mem_limit`) |

## Jeff runtime (upstream)

| Variable | Compose default | Upstream default | Description |
|---|---|---|---|
| `JEFF_DEVICE` | `cpu` | auto (cuda → mps → cpu) | Inference device |
| `JEFF_BACKEND` | `torch` | `torch` | `torch` or `onnx` (see [ONNX](onnx.md)) |
| `JEFF_QUANT` | — | `fp32` | ONNX precision: `fp32` or `int8` |
| `JEFF_ONNX_PATH` | — | `<model>/onnx/encoder[.int8].onnx` | Custom ONNX encoder path |
| `JEFF_DTYPE` | — | `bf16` on CUDA, `float32` on CPU | Torch dtype |
| `JEFF_THREADS` | `4` | all cores | Inference threads (also sets `OMP_NUM_THREADS`, `MKL_NUM_THREADS`) |
| `JEFF_WARMUP` | `true` | off | Run a warm-up inference at start (`true`/`1`) |
| `JEFF_COMPILE` / `JEFF_COMPILE_MODE` | — | off | `torch.compile` (GPU, advanced) |
| `JEFF_ATTN` | — | `auto` | Attention kernel: `auto`, `flash`, `eager` |
| `JEFF_PAD_MULTIPLE` | — | `0` | Pad sequence length to a multiple (GPU tuning) |
| `JEFF_MODEL_NAME` | — | `gliformer-large-v1` | Name reported by `/v1/models` and responses |
| `JEFF_MODEL_ALIASES` | — | `jev-latest,jev` | Accepted `model` values |

## Batching, limits and protection

| Variable | Compose default | Upstream default | Description |
|---|---|---|---|
| `JEFF_MAX_BATCH` | `8` | `16` | Max requests per inference batch |
| `JEFF_MAX_WAIT_MS` | `10` | `5` | Time to wait for a batch to fill |
| `JEFF_MAX_QUEUE` | — | `256` | Queue size; beyond it requests get **529** |
| `JEFF_RATE_LIMIT_RPS` | `4` | `0` (off) | Per-key requests per second |
| `JEFF_RATE_LIMIT_BURST` | `8` | `20` | Per-key burst |
| `JEFF_MAX_QUESTIONS` | — | `64` | Max questions per request (**422** above) |
| `JEFF_MAX_LABELS` | — | `64` | Max labels per question |
| `JEFF_MAX_STATE_CHARS` | — | `20000` | Max `state` length |

## Prompt and calibration (advanced)

| Variable | Upstream default | Description |
|---|---|---|
| `JEFF_NOUL_MODE` | `yes_no` | `single`, `single_named`, `yes_no`. Use **`single` with `gliformer-base-v1`** |
| `JEFF_ISOLATE` | `nouls` | `none`, `nouls`, `all` — separate encoder passes per question |
| `JEFF_STATE_FORMAT` | `kv` | How a JSON `state` is rendered: `kv`, `json`, `values` |
| `JEFF_TEMPERATURE` | `3.2` | Probability calibration; `1.0` disables scaling |

## Fixed by the image

| Variable | Value |
|---|---|
| `JEFF_HOST` / `JEFF_PORT` | `0.0.0.0` / `8000` |
| `HF_HOME` | `/data/huggingface` |
| `XDG_CACHE_HOME` | `/data/cache` |
| `HF_HUB_DISABLE_TELEMETRY` | `1` |

## Profiles

=== "Laptop (8 GB)"

    ```dotenv
    JEFF_MODEL_ID=knowledgator/gliformer-base-v1
    JEFF_MODEL_PATH=/models/gliformer-base-v1
    JEFF_NOUL_MODE=single
    JEFF_THREADS=4
    JEFF_MEM_LIMIT=5g
    JEFF_CPU_LIMIT=4
    ```

=== "NUC / Proxmox LXC (16 GB, 8 cores)"

    ```dotenv
    JEFF_THREADS=6
    JEFF_MAX_BATCH=8
    JEFF_MEM_LIMIT=10g
    JEFF_CPU_LIMIT=8
    JEFF_RATE_LIMIT_RPS=4
    ```

=== "Max CPU throughput"

    ```dotenv
    JEFF_BACKEND=onnx
    JEFF_QUANT=int8
    JEFF_THREADS=8
    JEFF_MAX_BATCH=16
    JEFF_MAX_WAIT_MS=15
    ```

=== "Shared public endpoint"

    ```dotenv
    JEFF_API_KEYS=key-client-a,key-client-b
    JEFF_RATE_LIMIT_RPS=2
    JEFF_RATE_LIMIT_BURST=4
    JEFF_MAX_STATE_CHARS=5000
    JEFF_MAX_QUESTIONS=16
    ```
