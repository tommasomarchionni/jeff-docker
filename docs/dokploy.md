# Dokploy on Proxmox LXC

Reference: MINISFORUM UM890 Pro (Ryzen 9 8945HS), Proxmox → LXC → Docker → Dokploy.

## 1. LXC resources

| Resource | Value |
|---|---|
| vCPU | 8 |
| RAM | 12 GB min, 16 GB recommended |
| Swap | 4 GB |
| Free disk | 25–30 GB |

Inside the LXC: `docker info`, `docker compose version`, `free -h`, `df -h`.
LXC must have `nesting=1` (and `keyctl=1` if unprivileged).

## 2. Create the service

`Project → Create Service → Compose`

- Provider: GitHub (or Git) → `tommasomarchionni/jeff-docker`
- Branch: `main`
- Compose path: `./docker-compose.dokploy.yml`

## 3. Environment (Dokploy → Environment)

```dotenv
JEFF_API_KEYS=<openssl rand -hex 32>
JEFF_DOCKER_TAG=latest
JEFF_MODEL_REVISION=main
JEFF_DEVICE=cpu
JEFF_BACKEND=torch
JEFF_THREADS=6
JEFF_MAX_BATCH=8
JEFF_RATE_LIMIT_RPS=4
JEFF_RATE_LIMIT_BURST=8
JEFF_MEM_LIMIT=10g
```

Variables only reach the container because the Compose references them with `${VAR}`.

## 4. Domain

Domains tab: host `jeff.example.com`, container port `8000`, HTTPS on, Let's Encrypt.
For LAN-only use, point a local DNS record to the LXC and keep it off the WAN.

## 5. Deploy and verify

First deploy downloads the model (several minutes). Watch logs for
`Model already present` on later redeploys.

```bash
curl https://jeff.example.com/healthz
curl https://jeff.example.com/v1/models -H "Authorization: Bearer <key>"
```

## Persistence and backups

Named volumes `jeff-models` and `jeff-data` survive redeploys. Back up with Dokploy volume
backups or `docker run --rm -v <project>_jeff-models:/v -v $PWD:/b alpine tar czf /b/models.tgz -C /v .`.

## Updating

Change `JEFF_DOCKER_TAG` to a pinned version (e.g. `1.0.0`) and redeploy. Avoid `latest` in production.
