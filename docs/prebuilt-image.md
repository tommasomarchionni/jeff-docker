# Prebuilt image (GHCR)

Every change to the image is built by GitHub Actions and published to the
GitHub Container Registry as a multi-arch manifest (`linux/amd64`,
`linux/arm64`):

```text
ghcr.io/tommasomarchionni/jeff-docker
```

Package page: [github.com/tommasomarchionni/jeff-docker/pkgs/container/jeff-docker](https://github.com/tommasomarchionni/jeff-docker/pkgs/container/jeff-docker).

## Tags

| Tag | Meaning | Use it for |
|---|---|---|
| `latest` | Newest build from `main` or the newest release | Trying things out |
| `edge` | Alias of the newest `main` build | Following development |
| `X.Y.Z` (e.g. `0.2.0`) | Immutable release | **Production** |
| `X.Y` / `X` | Newest patch of a minor/major line | Automatic patch updates |
| `sha-<short-sha>` | Exact commit of this repository | Bisecting, reproducibility |

## Using it

=== "Compose"

    ```bash
    curl -LO https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/docker-compose.prebuilt.yml
    curl -L -o .env https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/.env.example
    # set JEFF_API_KEYS in .env
    docker compose -f docker-compose.prebuilt.yml up -d
    ```

=== "docker run"

    See [Plain Docker](docker-plain.md).

=== "Dokploy"

    See [Dokploy](dokploy.md), Mode A.

## Pinning a version

Set the tag in `.env` (or in Dokploy → Environment):

```dotenv
JEFF_DOCKER_TAG=0.2.0
```

For bit-for-bit reproducibility pin the digest instead of the tag:

```yaml
image: ghcr.io/tommasomarchionni/jeff-docker@sha256:<digest>
```

The digest of each release is printed in the
[GitHub Release notes](https://github.com/tommasomarchionni/jeff-docker/releases).

## What is inside

| Component | Details |
|---|---|
| Base | `python:3.12-slim` (Debian) |
| PyTorch | CPU-only wheels from `download.pytorch.org/whl/cpu` |
| Jeff | Upstream `main` at build time (short SHA in logs and `/app/.jeff-revision`) |
| Extras | `onnx` (ONNX Runtime) so the [ONNX backend](onnx.md) works without rebuilding |
| User | `jeff` (UID/GID `10001`), non-root |
| PID 1 | `tini` (signal forwarding, zombie reaping) |
| Volumes | `/models` (weights, ONNX), `/data` (HF cache) |
| Port | `8000` |
| Health | `HEALTHCHECK` on `/healthz` every 30 s, 300 s start period |

The model is **not** baked into the image: it is downloaded on first start
into the `/models` volume (see [Models](models.md)).

## Verifying the image (supply chain)

Each image is published with an SBOM, SLSA provenance and a GitHub
artifact attestation:

```bash
gh attestation verify oci://ghcr.io/tommasomarchionni/jeff-docker:latest \
  -R tommasomarchionni/jeff-docker
docker buildx imagetools inspect ghcr.io/tommasomarchionni/jeff-docker:latest \
  --format '{{ json .SBOM }}' | head
```

## Building your own instead

Clone the repository and use `docker-compose.yml` (builds locally), see
[Docker Compose](docker-compose-guide.md#build-from-source). Useful build
arguments:

| Build arg | Default | Purpose |
|---|---|---|
| `JEFF_REF` | `main` | Upstream Jeff branch, tag or commit |
| `TORCH_VERSION` | `2.14.0` | Must match upstream `uv.lock` |
| `TORCH_INDEX_URL` | `https://download.pytorch.org/whl/cpu` | `.../cu130` (NVIDIA), `.../rocm7.2` (AMD) |
| `UV_EXTRAS` | `onnx` | Upstream optional extras |
| `PYTHON_VERSION` | `3.12` | Upstream requires 3.12 |
