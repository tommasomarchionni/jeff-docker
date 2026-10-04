# Testing and CI

## Workflows

| Workflow | Trigger | What it checks |
|---|---|---|
| **CI** (`ci.yml`) | push, PR | shellcheck, hadolint, Compose validation (all files + GPU overlays), bats unit tests, `mkdocs --strict`, image build; image fails fast without a key, runs as UID 10001, ships CPU-only torch and no CUDA packages |
| **Smoke test** (`smoke-test.yml`) | push/PR touching the image, weekly, manual | Builds the image, downloads `gliformer-base-v1`, runs the real server for both `torch` and `onnx` int8 and tests: `healthy` status, 401 on missing/wrong key, 422 on invalid payload, `score`/`choice`/`noul` answers, `/stats` backend, restart without re-download, **429** rate limiting; plus a full `docker compose up --build --wait` run checking named volumes, persistence across `down/up` and localhost-only port binding |
| **Publish image** (`publish.yml`) | push to `main` (image paths), `v*.*.*` tags, manual | Multi-arch build and push to GHCR with SBOM/provenance/attestation, GitHub Release for tags, then **pulls the published digest on native amd64 and arm64 runners** and verifies architecture, imports, CPU torch, fail-fast and the attestation |
| **Deploy docs** (`docs.yml`) | push touching docs | Builds and publishes this site |
| **Stale** (`stale.yml`) | daily | Marks inactive issues/PRs |

The weekly smoke test catches upstream Jeff changes that would break the
image before you redeploy.

## Unit tests

`tests/test_entrypoint.bats` covers the entrypoint without network or
model (Hugging Face CLI stubbed): mandatory key, explicit no-auth mode,
missing model, one-time download and marker, forced re-download, manually
provisioned models, `JEFF_MODEL` export, boolean normalization, dropping
empty variables, thread variables.

## Running everything locally

Only Docker is required:

```bash
./tests/run-tests.sh            # full suite incl. image build
SKIP_BUILD=1 ./tests/run-tests.sh
```

Or individual tools:

```bash
bats tests/test_entrypoint.bats
shellcheck docker/entrypoint.sh
docker run --rm -i hadolint/hadolint < docker/Dockerfile
```

## Manual end-to-end test

```bash
cp .env.example .env
sed -i -e "s/^JEFF_API_KEYS=.*/JEFF_API_KEYS=test/" \
       -e "s|^JEFF_MODEL_ID=.*|JEFF_MODEL_ID=knowledgator/gliformer-base-v1|" \
       -e "s|^JEFF_MODEL_PATH=.*|JEFF_MODEL_PATH=/models/gliformer-base-v1|" \
       -e "s/^JEFF_NOUL_MODE=.*/JEFF_NOUL_MODE=single/" .env
docker compose up -d --build --wait
curl -s localhost:8000/v1/systemone -H 'Authorization: Bearer test' \
  -H 'Content-Type: application/json' \
  -d '{"state":"Login fails","model":"jev-latest","questions":{"q":{"type":"noul"}}}'
```
