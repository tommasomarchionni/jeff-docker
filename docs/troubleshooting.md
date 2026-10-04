# Troubleshooting

| Symptom | Fix |
|---|---|
| `JEFF_API_KEYS is empty` | Set the key in `.env` / Dokploy |
| Container killed during start (exit 137) | Raise LXC RAM / `JEFF_MEM_LIMIT`, add swap |
| Healthcheck unhealthy on first run | Model download still running; wait, `start_period` is 180 s |
| `Model missing ... JEFF_DOWNLOAD_MODEL=false` | Enable download or provision the volume |
| Corrupted download | `JEFF_FORCE_MODEL_DOWNLOAD=true`, redeploy, then set back to `false` |
| Permission denied on `/models` | Volume created by another UID: `docker run --rm -v <vol>:/m alpine chown -R 10001:10001 /m` |
| 404 via domain | Check Dokploy domain port is `8000` and service is on `dokploy-network` |
| Slow responses | Lower text size, tune `JEFF_THREADS`, try ONNX INT8 |
