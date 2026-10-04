# jeff-docker

Production-oriented, multi-architecture Docker distribution for
[Jeff](https://github.com/logan-markewich/jeff) — a self-hosted,
TypeSafe jev-compatible structured-classification API powered by GLiFormer.

- CPU-first, `linux/amd64` + `linux/arm64` images on GHCR
- Idempotent model download into a persistent volume
- Compose files for local build, prebuilt image and **Dokploy**
- Mandatory bearer auth, no host port exposure in Dokploy
- AMD ROCm documented as **experimental**

## Quick start (prebuilt)

```bash
curl -LO https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/docker-compose.prebuilt.yml
curl -L -o .env https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/.env.example
sed -i "s/^JEFF_API_KEYS=.*/JEFF_API_KEYS=$(openssl rand -hex 32)/" .env
docker compose -f docker-compose.prebuilt.yml up -d
docker compose -f docker-compose.prebuilt.yml logs -f
```

## Quick start (build from source)

```bash
git clone https://github.com/tommasomarchionni/jeff-docker.git && cd jeff-docker
cp .env.example .env   # set JEFF_API_KEYS
docker compose up -d --build
```

## Test

```bash
source .env
curl -s http://127.0.0.1:8000/healthz
curl -s http://127.0.0.1:8000/v1/systemone \
  -H "Authorization: Bearer $JEFF_API_KEYS" -H "Content-Type: application/json" \
  -d '{"state":"Export button crashes on Safari.","model":"jev-latest",
       "questions":{"severity":{"type":"score","instructions":"How severe?",
       "criteria":["cosmetic","degraded","blocking"]}}}'
```

## Deploy on Dokploy

See [docs/dokploy.md](docs/dokploy.md). Use `docker-compose.dokploy.yml` as Compose path.

## Compose files

| File | Purpose |
|---|---|
| `docker-compose.yml` | Local build from source |
| `docker-compose.prebuilt.yml` | GHCR image |
| `docker-compose.dokploy.yml` | Dokploy (no ports, `dokploy-network`) |
| `docker-compose.rocm.experimental.yml` | Unsupported AMD ROCm overlay |

## License

MIT for this packaging. Jeff and model weights are subject to their own licenses.
