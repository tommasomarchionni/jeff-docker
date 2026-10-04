# Persistence and backups

| Volume | Mount | Content | Size | Lost if deleted |
|---|---|---|---|---|
| `jeff-models` | `/models` | Weights, download marker, ONNX exports | 1–4 GB | Re-downloaded automatically |
| `jeff-data` | `/data` | Hugging Face and generic caches | small | Nothing important |

Jeff is **stateless** regarding requests: no database, no user data.
Losing the volumes only costs a re-download.

## What survives what

| Event | Model kept? |
|---|---|
| `docker compose restart` / host reboot | yes |
| `docker compose down` + `up` | yes |
| Image upgrade / Dokploy redeploy | yes |
| `docker compose down -v` | **no** |
| Dokploy Application without volume mounts | **no** |

## Backup

```bash
docker run --rm -v jeff-models:/v:ro -v "$PWD":/b alpine \
  tar czf /b/jeff-models-$(date +%F).tgz -C /v .
```

On Dokploy use **Volume Backups** (S3-compatible destination).

## Restore / migrate to another host

```bash
docker volume create jeff-models
docker run --rm -v jeff-models:/v -v "$PWD":/b alpine \
  sh -c 'tar xzf /b/jeff-models-*.tgz -C /v && chown -R 10001:10001 /v'
```

## Inspect

```bash
docker run --rm -v jeff-models:/m alpine sh -c 'du -sh /m/*; cat /m/*/.jeff-download-complete'
```

## Clean up old models

```bash
docker run --rm -v jeff-models:/m alpine rm -rf /m/gliformer-base-v1
```
