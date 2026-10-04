# Jeff Docker

A production-oriented, **CPU-first** Docker distribution for
[Jeff](https://github.com/logan-markewich/jeff) — a self-hosted,
TypeSafe jev-compatible **structured-classification API** powered by
[GLiFormer](https://huggingface.co/knowledgator/gliformer-large-v1).

You send a piece of text (`state`) and a set of questions (`score`,
`choice`, `noul`); Jeff answers with probabilities, a choice or a score.
It is not a chat LLM: it is a fast, deterministic classifier you can run
on a normal CPU, at home or on a server.

## Why this project

- **One command to run**: prebuilt multi-arch image on GHCR
  (`linux/amd64`, `linux/arm64`), no Python toolchain on your machine.
- **CPU-only PyTorch**: the image ships CPU wheels instead of the default
  CUDA stack: about 0.4 GB to pull instead of 3.2 GB (measured on amd64).
- **Model downloaded once**: weights land in a persistent volume and are
  reused on every restart, redeploy or upgrade.
- **Secure by default**: the container refuses to start without an API key,
  runs as a non-root user, with no Linux capabilities and no host port
  exposure in Dokploy.
- **Dokploy-first**: dedicated Compose file and a step-by-step guide,
  including Proxmox LXC.
- **Tested**: shellcheck, hadolint, bats unit tests, Compose validation and
  an end-to-end smoke test that runs the real API on every change
  (see [Testing and CI](testing.md)).
- **GPU optional**: AMD ROCm and NVIDIA CUDA documented as experimental
  overlays, never required.

## How it works

1. On start, the entrypoint checks `JEFF_API_KEYS` (mandatory unless you
   explicitly enable no-auth mode for local tests).
2. If the model is not yet in the `/models` volume, it downloads it from
   Hugging Face once and writes a marker file; later starts skip the
   download.
3. If `JEFF_BACKEND=onnx`, Jeff exports the ONNX encoder into the same
   volume on first start and reuses it afterwards.
4. Jeff starts on port `8000` with dynamic batching, per-key rate limits
   and a `/healthz` endpoint used by the Docker `HEALTHCHECK`.

## Where to start

!!! tip "New to Docker?"
    Follow the [Quick start for beginners](quick-start.md): every step is
    explained, from installing Docker to your first API call.

| I want to... | Go to |
|---|---|
| Try it on my laptop in 5 minutes | [Quick start](quick-start.md) |
| Install Docker on macOS, Windows or Linux | [Platform setup](platform-setup.md) |
| Use the prebuilt image and pin versions | [Prebuilt image](prebuilt-image.md) |
| Run it with Docker Compose on a server | [Docker Compose](docker-compose-guide.md) |
| Deploy on Dokploy (incl. Proxmox LXC) | [Dokploy](dokploy.md) |
| Run it without Compose | [Plain Docker](docker-plain.md) |
| Call the API from curl, Python, TypeScript, Home Assistant | [Using the API](api-usage.md) |
| Tune every option | [Environment variables](environment-variables.md) |
| Choose or pin a model, run offline | [Models](models.md) |
| Make it faster on CPU | [ONNX backend](onnx.md) and [Performance](performance.md) |
| Back up, upgrade, roll back | [Persistence](persistence.md) and [Upgrades](upgrades.md) |
| Fix a problem | [Troubleshooting](troubleshooting.md) and [FAQ](faq.md) |

## Support policy

| Runtime | Status |
|---|---|
| CPU, `linux/amd64` (Linux, Proxmox LXC, Dokploy, Windows/WSL2, Intel Mac) | **Supported** |
| CPU, `linux/arm64` (Apple Silicon via Docker Desktop, ARM servers, Raspberry Pi 5) | **Supported** |
| NVIDIA CUDA | [Experimental](experimental/nvidia-gpu.md) |
| AMD ROCm, integrated Radeon GPUs, GPU passthrough in LXC | [Experimental](experimental/amd-rocm.md) |
| Apple MPS | Not available inside Docker (Linux VM); run Jeff natively on macOS instead |

## Repository

Source code, issues and pull requests:
[github.com/tommasomarchionni/jeff-docker](https://github.com/tommasomarchionni/jeff-docker).
Model behavior and API questions belong upstream:
[github.com/logan-markewich/jeff](https://github.com/logan-markewich/jeff).
