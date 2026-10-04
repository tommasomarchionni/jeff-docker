# Plain Docker (no Compose)

Everything the Compose files do, as single commands.

```bash
docker volume create jeff-models
docker volume create jeff-data

docker run -d --name jeff \
  --restart unless-stopped \
  -p 127.0.0.1:8000:8000 \
  -v jeff-models:/models \
  -v jeff-data:/data \
  -e JEFF_API_KEYS="$(openssl rand -hex 32)" \
  -e JEFF_DEVICE=cpu \
  -e JEFF_THREADS=4 \
  -e JEFF_RATE_LIMIT_RPS=4 \
  --memory 10g \
  --security-opt no-new-privileges:true --cap-drop ALL \
  ghcr.io/tommasomarchionni/jeff-docker:latest

docker logs -f jeff
```

Read the generated key back with:

```bash
docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' jeff | grep JEFF_API_KEYS
```

Using an env file instead of many `-e` flags:

```bash
docker run -d --name jeff --env-file .env -p 127.0.0.1:8000:8000 \
  -v jeff-models:/models -v jeff-data:/data \
  ghcr.io/tommasomarchionni/jeff-docker:latest
```

!!! warning
    `docker run --env-file` does **not** strip quotes: write
    `JEFF_API_KEYS=abc`, not `JEFF_API_KEYS="abc"`.

Bind-mounting a host directory instead of a volume (e.g. to inspect
weights): the directory must be writable by UID `10001`:

```bash
sudo mkdir -p /srv/jeff/models && sudo chown -R 10001:10001 /srv/jeff/models
docker run ... -v /srv/jeff/models:/models ...
```

Upgrading:

```bash
docker pull ghcr.io/tommasomarchionni/jeff-docker:latest
docker rm -f jeff
# re-run the same docker run command; the volumes keep the model
```
