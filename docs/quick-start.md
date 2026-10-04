# Quick start (step by step)

This page assumes **no prior Docker experience**. In about 10 minutes
(mostly waiting for the download) you will have Jeff answering requests on
your machine. Experienced users can jump to
[Docker Compose](docker-compose-guide.md) or [Dokploy](dokploy.md).

## What you need

- A computer with **8 GB RAM or more** (16 GB recommended) and **10 GB
  free disk** (image ~1.5 GB + model ~1.7 GB + headroom).
- Docker installed and running. If you don't have it yet, follow
  [Platform setup](platform-setup.md) first, then come back.
- A terminal: **Terminal** on macOS, **PowerShell** or **WSL** on Windows,
  any shell on Linux.

Check Docker works:

```bash
docker version
docker compose version
```

Both commands must print a version without errors.

## Step 1 — Create a folder and download two files

```bash
mkdir jeff && cd jeff
curl -LO https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/docker-compose.prebuilt.yml
curl -L -o .env https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/.env.example
```

- `docker-compose.prebuilt.yml` describes the container to run.
- `.env` holds your settings. It stays on your computer.

=== "Windows PowerShell"

    ```powershell
    mkdir jeff; cd jeff
    Invoke-WebRequest https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/docker-compose.prebuilt.yml -OutFile docker-compose.prebuilt.yml
    Invoke-WebRequest https://raw.githubusercontent.com/tommasomarchionni/jeff-docker/main/.env.example -OutFile .env
    ```

## Step 2 — Create your API key

Jeff refuses to start without a key. Generate a random one:

=== "macOS / Linux / WSL"

    ```bash
    KEY=$(openssl rand -hex 32)
    sed -i.bak "s/^JEFF_API_KEYS=.*/JEFF_API_KEYS=$KEY/" .env && rm .env.bak
    echo "Your key: $KEY"
    ```

=== "Windows PowerShell"

    ```powershell
    $KEY = -join ((48..57) + (97..102) | Get-Random -Count 64 | ForEach-Object {[char]$_})
    (Get-Content .env) -replace '^JEFF_API_KEYS=.*', "JEFF_API_KEYS=$KEY" | Set-Content .env
    "Your key: $KEY"
    ```

Save the key somewhere safe (password manager): every client needs it.

## Step 3 — Adapt resources to your machine (optional)

Open `.env` in any text editor and check:

| Setting | Laptop 8 GB | Desktop/NUC 16 GB+ |
|---|---|---|
| `JEFF_THREADS` | `4` | `6`–`8` |
| `JEFF_MEM_LIMIT` | `6g` | `10g` |
| `JEFF_CPU_LIMIT` | `4` | `8` |

On Docker Desktop (macOS/Windows), also make sure **Settings → Resources**
gives Docker at least 6 GB of memory.

## Step 4 — Start Jeff

```bash
docker compose -f docker-compose.prebuilt.yml up -d
docker compose -f docker-compose.prebuilt.yml logs -f
```

The first start downloads the model (about 1.7 GB). You will see:

```text
[entrypoint] Downloading knowledgator/gliformer-large-v1 (revision main) into /models/gliformer-large-v1 ...
[entrypoint] Model download complete.
... jeff ready: backend=torch model=gliformer-large-v1
INFO:     Uvicorn running on http://0.0.0.0:8000
```

Press `Ctrl+C` to stop following the logs (Jeff keeps running).

## Step 5 — Check it is healthy

```bash
curl http://127.0.0.1:8000/healthz
# {"ok":true,"model":"gliformer-large-v1"}
docker compose -f docker-compose.prebuilt.yml ps
# STATUS should say "healthy" after a minute
```

## Step 6 — Ask your first question

```bash
curl http://127.0.0.1:8000/v1/systemone \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "state": "The export button crashes on Safari and users cannot download reports.",
    "model": "jev-latest",
    "questions": {
      "severity": {"type": "score", "instructions": "How severe is this?",
                   "criteria": ["cosmetic", "degraded", "blocking"]},
      "area": {"type": "choice", "instructions": "Which area?",
               "criteria": {"frontend": "UI and browser", "backend": "API and server", "infra": null}}
    }
  }'
```

You get back a JSON with a `score` for `severity` and a `choice` for
`area`. See [Using the API](api-usage.md) for every question type and
client examples.

## Everyday commands

| Action | Command |
|---|---|
| Stop | `docker compose -f docker-compose.prebuilt.yml down` |
| Start again | `docker compose -f docker-compose.prebuilt.yml up -d` |
| Logs | `docker compose -f docker-compose.prebuilt.yml logs -f` |
| Update to the newest image | `docker compose -f docker-compose.prebuilt.yml pull && docker compose -f docker-compose.prebuilt.yml up -d` |
| Remove everything **including the model** | `docker compose -f docker-compose.prebuilt.yml down -v` |

!!! tip "Tired of typing `-f docker-compose.prebuilt.yml`?"
    Rename the file to `docker-compose.yml` and plain `docker compose up -d`
    works.

## Next steps

- Run it 24/7 on a server or NUC: [Docker Compose](docker-compose-guide.md)
  or [Dokploy](dokploy.md).
- Make it faster: [ONNX backend](onnx.md).
- Something went wrong: [Troubleshooting](troubleshooting.md).
