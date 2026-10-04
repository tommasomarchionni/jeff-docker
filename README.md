# Jeff Docker (CPU-first, multi-arch, Dokploy-ready)

[![CI](https://github.com/tommasomarchionni/jeff-docker/actions/workflows/ci.yml/badge.svg)](https://github.com/tommasomarchionni/jeff-docker/actions/workflows/ci.yml)
[![Smoke test](https://github.com/tommasomarchionni/jeff-docker/actions/workflows/smoke-test.yml/badge.svg)](https://github.com/tommasomarchionni/jeff-docker/actions/workflows/smoke-test.yml)
[![Publish image](https://github.com/tommasomarchionni/jeff-docker/actions/workflows/publish.yml/badge.svg)](https://github.com/tommasomarchionni/jeff-docker/actions/workflows/publish.yml)
[![Docs](https://github.com/tommasomarchionni/jeff-docker/actions/workflows/docs.yml/badge.svg)](https://github.com/tommasomarchionni/jeff-docker/actions/workflows/docs.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-tommasomarchionni%2Fjeff--docker-blue?logo=docker)](https://github.com/tommasomarchionni/jeff-docker/pkgs/container/jeff-docker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Production-oriented Docker distribution for
[Jeff](https://github.com/logan-markewich/jeff), a self-hosted,
TypeSafe jev-compatible **structured-classification API** powered by
GLiFormer. Send a text and a set of `score` / `choice` / `noul` questions,
get calibrated answers back — on a plain CPU.

**Full documentation:** [tommasomarchionni.github.io/jeff-docker](https://tommasomarchionni.github.io/jeff-docker/)

> [!IMPORTANT]
> CPU is the supported runtime. NVIDIA CUDA and AMD ROCm (including
> integrated Radeon GPUs and GPU passthrough in Proxmox LXC) are
> documented as experimental and outside the support guarantee.

## Highlights

- Prebuilt multi-arch image on GHCR (`linux/amd64`, `linux/arm64`)
- **CPU-only PyTorch**: no CUDA stack, ~0.4 GB compressed download instead of ~3.2 GB
- Model downloaded **once** into a persistent volume, reused forever
- API key **mandatory**, non-root, no capabilities, localhost-only port
- ONNX Runtime included: switch to `onnx` + `int8` with one variable
- Compose files for prebuilt image, local build and **Dokploy**
- Every upstream option exposed as an environment variable
- Tested: shellcheck, hadolint, bats, Compose validation, end-to-end API
  smoke test (torch + ONNX), post-publish verification on amd64 and arm64
- SBOM, SLSA provenance and GitHub attestations on every image

## Quick start

```bash
curl -LO https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/docker-compose.prebuilt.yml
curl -L -o .env https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/.env.example
sed -i "s/^JEFF_API_KEYS=.*/JEFF_API_KEYS=$(openssl rand -hex 32)/" .env

docker compose -f docker-compose.prebuilt.yml up -d --wait   # first start downloads ~1.7 GB
```

```bash
source .env
curl -s http://127.0.0.1:8000/v1/systemone \
  -H "Authorization: Bearer $JEFF_API_KEYS" -H "Content-Type: application/json" \
  -d '{"state":"The export button crashes on Safari.","model":"jev-latest",
       "questions":{"severity":{"type":"score","instructions":"How severe?",
                                "criteria":["cosmetic","degraded","blocking"]}}}'
```

Or build from source:

```bash
git clone https://github.com/tommasomarchionni/jeff-docker.git && cd jeff-docker
cp .env.example .env   # set JEFF_API_KEYS
docker compose up -d --build --wait
```

New to Docker? Follow the step-by-step
[Quick start for beginners](https://tommasomarchionni.github.io/jeff-docker/quick-start/).

## Compose files

| File | Purpose |
|---|---|
| `docker-compose.prebuilt.yml` | GHCR image, port on `127.0.0.1:8000` |
| `docker-compose.yml` | Local build from `docker/Dockerfile` |
| `docker-compose.dokploy.yml` | Dokploy: no host port, `dokploy-network`, named volumes |
| `docker-compose.nvidia.experimental.yml` | Overlay: CUDA build, `gpus: all` |
| `docker-compose.rocm.experimental.yml` | Overlay: ROCm build, `/dev/kfd` + `/dev/dri` |

## Documentation

| Topic | Link |
|---|---|
| Quick start (beginners) | [docs](https://tommasomarchionni.github.io/jeff-docker/quick-start/) |
| Platform setup (macOS, Windows, Linux, Proxmox) | [docs](https://tommasomarchionni.github.io/jeff-docker/platform-setup/) |
| Prebuilt image (GHCR, tags, verification) | [docs](https://tommasomarchionni.github.io/jeff-docker/prebuilt-image/) |
| Docker Compose | [docs](https://tommasomarchionni.github.io/jeff-docker/docker-compose-guide/) |
| Dokploy (all modes, Proxmox LXC) | [docs](https://tommasomarchionni.github.io/jeff-docker/dokploy/) |
| Plain Docker | [docs](https://tommasomarchionni.github.io/jeff-docker/docker-plain/) |
| Using the API (curl, Python, TypeScript, Home Assistant) | [docs](https://tommasomarchionni.github.io/jeff-docker/api-usage/) |
| Environment variables (full reference) | [docs](https://tommasomarchionni.github.io/jeff-docker/environment-variables/) |
| Models (switch, pin, offline) | [docs](https://tommasomarchionni.github.io/jeff-docker/models/) |
| ONNX backend | [docs](https://tommasomarchionni.github.io/jeff-docker/onnx/) |
| Persistence and backups | [docs](https://tommasomarchionni.github.io/jeff-docker/persistence/) |
| Upgrades and versioning | [docs](https://tommasomarchionni.github.io/jeff-docker/upgrades/) |
| Monitoring and logs | [docs](https://tommasomarchionni.github.io/jeff-docker/monitoring/) |
| Performance and benchmark | [docs](https://tommasomarchionni.github.io/jeff-docker/performance/) |
| Security | [docs](https://tommasomarchionni.github.io/jeff-docker/security/) |
| Testing and CI | [docs](https://tommasomarchionni.github.io/jeff-docker/testing/) |
| Troubleshooting | [docs](https://tommasomarchionni.github.io/jeff-docker/troubleshooting/) |
| FAQ | [docs](https://tommasomarchionni.github.io/jeff-docker/faq/) |
| Experimental GPU (NVIDIA, AMD ROCm) | [NVIDIA](https://tommasomarchionni.github.io/jeff-docker/experimental/nvidia-gpu/) · [ROCm](https://tommasomarchionni.github.io/jeff-docker/experimental/amd-rocm/) |

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Please
follow the [Code of Conduct](CODE_OF_CONDUCT.md). For security issues, see
[SECURITY.md](SECURITY.md) instead of opening a public issue.

## License

[MIT](LICENSE) © Tommaso Marchionni. Jeff and the GLiFormer model weights
are distributed under their own licenses.
