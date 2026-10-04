# Docker Compose

Two Compose files cover the non-Dokploy cases:

| File | Image | When |
|---|---|---|
| `docker-compose.prebuilt.yml` | Pulled from GHCR | Default, fastest |
| `docker-compose.yml` | Built locally from `docker/Dockerfile` | Forks, custom builds, pinned upstream ref |

Both read **every** setting from `.env` through `${VAR}` interpolation,
bind the API to `127.0.0.1:8000`, and declare two named volumes
(`jeff-models`, `jeff-data`).

## Prebuilt image

```bash
git clone https://github.com/tommasomarchionni/jeff-docker.git
cd jeff-docker
cp .env.example .env
sed -i "s/^JEFF_API_KEYS=.*/JEFF_API_KEYS=$(openssl rand -hex 32)/" .env
docker compose -f docker-compose.prebuilt.yml up -d --wait
```

`--wait` returns once the container is `healthy` (first start includes the
model download, so it can take several minutes).

## Build from source

```bash
docker compose up -d --build --wait
```

Pin the upstream revision for reproducible builds:

```bash
JEFF_REF=<commit-sha> docker compose build --no-cache
```

## Exposing it on the network

By default only the host itself can reach Jeff. Options, from safest:

1. **Reverse proxy with TLS** (Caddy, Traefik, Nginx Proxy Manager) on the
   same host → keep `JEFF_BIND=127.0.0.1` and proxy to `127.0.0.1:8000`.
2. **Shared Docker network** with your other containers → remove `ports:`
   and call `http://jeff:8000` from them:

    ```yaml
    services:
      jeff:
        networks: [backend]
    networks:
      backend:
        external: true
    ```

3. **LAN only** → `JEFF_BIND=0.0.0.0` plus a host firewall rule allowing
   only your subnet. Never forward the port on your router.

### Caddy example

```caddyfile
jeff.example.com {
    reverse_proxy 127.0.0.1:8000
}
```

## Running multiple instances

Give each instance its own name, volumes and port:

```dotenv
JEFF_CONTAINER_NAME=jeff-base
JEFF_VOLUME_PREFIX=jeff-base
JEFF_HOST_PORT=8001
JEFF_MODEL_ID=knowledgator/gliformer-base-v1
JEFF_MODEL_PATH=/models/gliformer-base-v1
JEFF_NOUL_MODE=single
```

```bash
docker compose -p jeff-base --env-file .env.base -f docker-compose.prebuilt.yml up -d
```

## Overriding without editing the files

Create `compose.override.yml` (picked up automatically with
`docker-compose.yml`, or pass it with `-f`):

```yaml
services:
  jeff:
    environment:
      JEFF_THREADS: "4"
    labels:
      com.centurylinklabs.watchtower.enable: "false"
```

## Lifecycle

| Action | Command |
|---|---|
| Status / health | `docker compose ps` |
| Logs | `docker compose logs -f jeff` |
| Restart | `docker compose restart jeff` |
| Apply `.env` changes | `docker compose up -d` (recreates the container) |
| Update image | `docker compose pull && docker compose up -d` |
| Stop, keep model | `docker compose down` |
| Stop, delete model | `docker compose down -v` |
