# Troubleshooting

Start with the logs: `docker compose logs --tail 100 jeff` (or Dokploy →
Logs). Lines from this image start with `[entrypoint]`.

## The container exits immediately

### `JEFF_API_KEYS is empty`

Set a key in `.env` / Dokploy Environment. In Dokploy with a custom compose
file, make sure it contains `JEFF_API_KEYS: ${JEFF_API_KEYS:-}`.

### `Model missing at ... and JEFF_DOWNLOAD_MODEL=false`

Enable the download or provision the directory (see [Models](models.md)).

### `Cannot create /models/...` / `Permission denied`

The volume or bind mount is owned by another user:

```bash
docker run --rm -v jeff-models:/m alpine chown -R 10001:10001 /m
# bind mount:
sudo chown -R 10001:10001 /srv/jeff/models
```

### `Model download failed`

- DNS/egress: `docker run --rm alpine wget -qO- https://huggingface.co >/dev/null && echo ok`
- Disk full: `df -h /var/lib/docker`
- Private repo or rate limit: set `HF_TOKEN`.
- Behind a proxy: pass `HTTPS_PROXY`/`NO_PROXY` to the container.

## `range of CPUs is from 0.01 to N.00, as there are only N CPUs available`

`JEFF_CPU_LIMIT` exceeds the CPUs visible to Docker (common in a Proxmox
LXC with fewer cores). Set `JEFF_CPU_LIMIT=0` (no limit) or a value ≤
`nproc`, and `JEFF_THREADS` ≤ `nproc`, then redeploy.

## Exit code 137 / container killed

Out of memory. Raise Docker Desktop / LXC memory, raise `JEFF_MEM_LIMIT`,
lower `JEFF_MAX_BATCH`, or use `gliformer-base-v1`.
Check: `docker inspect -f '{{.State.OOMKilled}}' jeff`.

## Stuck in `starting` / `unhealthy`

- First start: still downloading (watch the logs; 1.7 GB).
- Later starts: model load takes 10–30 s on slow disks.
- `docker inspect -f '{{json .State.Health}}' jeff | jq` shows the probe output.

## HTTP errors

| Code | Meaning | Fix |
|---|---|---|
| 401 | Missing/wrong key | Header must be `Authorization: Bearer <key>` exactly |
| 422 | Invalid payload or limit | `choice.criteria` must be an **object**, `score.criteria` a **list**; check `JEFF_MAX_*` |
| 429 | Rate limit | Back off (`retry-after-ms`), or raise `JEFF_RATE_LIMIT_RPS` |
| 529 | Queue full | Too many concurrent requests: scale CPU, raise `JEFF_MAX_QUEUE`, add client backoff |
| 502/504 via proxy | Jeff not ready or wrong port | Wait for `jeff ready`; proxy target port `8000` |

## `Bind for 127.0.0.1:8000 failed: port is already allocated`

Another service uses 8000: set `JEFF_HOST_PORT=8001`.

## Slow responses

See [Performance](performance.md): reduce text length, tune
`JEFF_THREADS`, try [ONNX int8](onnx.md), check `docker stats` for CPU
throttling by `JEFF_CPU_LIMIT` or LXC limits.

## `exec format error`

Wrong architecture image (e.g. forced `--platform linux/amd64` on ARM).
Remove the platform override; the manifest picks the right one.

## Dokploy

See [Dokploy-specific troubleshooting](dokploy.md#dokploy-specific-troubleshooting).

## Still stuck?

Open a [bug report](https://github.com/tommasomarchionni/jeff-docker/issues/new/choose)
with image tag, platform, redacted logs and configuration.
