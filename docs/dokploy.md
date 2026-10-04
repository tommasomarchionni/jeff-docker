# Deploying on Dokploy

[Dokploy](https://dokploy.com/) is a self-hosted PaaS that already includes
Docker and a Traefik reverse proxy. This page covers every way to run Jeff
on Dokploy, in the order most people should try them, plus a dedicated
section for Dokploy running inside a **Proxmox LXC** (e.g. on a mini PC such
as a MINISFORUM UM890 Pro).

!!! tip "Recommended path"
    **Compose service** with `docker-compose.dokploy.yml` (Mode A). It
    pulls the prebuilt image, exposes no host port, joins
    `dokploy-network` so the Domains tab works, and keeps the model in
    named volumes across redeploys.

## Before you start

| Check | Command (on the Dokploy host / inside the LXC) |
|---|---|
| Docker works | `docker info` |
| Free RAM ≥ 12 GB | `free -h` |
| Free disk ≥ 20 GB | `df -h /var/lib/docker` |
| Outbound HTTPS to `huggingface.co` and `ghcr.io` | `curl -sI https://huggingface.co \| head -1` |

Generate your API key on any machine:

```bash
openssl rand -hex 32
```

## Choosing a service type

| | **Compose service** (recommended) | **Application service** |
|---|---|---|
| Deploys | `docker-compose.dokploy.yml` from this repo | One container from `ghcr.io/...` or `docker/Dockerfile` |
| Environment variables | Written to `.env` next to the compose file; reach the container **only** because the compose file references them with `${VAR}` (this repo's files already do) | Passed **directly** to the container |
| Volumes | Declared in the compose file (`jeff-models`, `jeff-data`) | Must be added by hand in **Advanced → Volumes** |
| Network | Joins `dokploy-network` (declared in the file) | Managed by Dokploy |
| Best for | Matching the tested setup exactly | Teams that standardize on Application services |

## Mode A — Compose, prebuilt image (recommended)

1. **Create Project** (e.g. `ai`) → open it → **Create Service → Compose**.
2. **Compose Type**: `Docker Compose` (not `Stack`).
3. **General** tab — source of the compose file:
     - **Git-based**: provider `GitHub` (or `Git` with
       `https://github.com/tommasomarchionni/jeff-docker.git`), branch
       `main`, **Compose Path** `./docker-compose.dokploy.yml`.
     - **Raw editor**: paste the content of
       [`docker-compose.dokploy.yml`](https://github.com/tommasomarchionni/jeff-docker/blob/main/docker-compose.dokploy.yml)
       if you don't want Dokploy to access GitHub.
4. **Environment** tab — minimal set:

    ```dotenv
    JEFF_API_KEYS=<paste the openssl key>
    JEFF_DOCKER_TAG=0.2.0
    JEFF_DEVICE=cpu
    JEFF_THREADS=4
    JEFF_MAX_BATCH=8
    JEFF_RATE_LIMIT_RPS=4
    JEFF_RATE_LIMIT_BURST=8
    JEFF_CPU_LIMIT=0
    JEFF_MEM_LIMIT=10g
    ```

    !!! warning "Match the limits to the host"
        `JEFF_CPU_LIMIT` must not exceed the CPUs Docker can see (run
        `nproc` on the Dokploy host / inside the LXC). With a 4-core LXC and
        `JEFF_CPU_LIMIT=8` the deploy fails with
        `range of CPUs is from 0.01 to 4.00, as there are only 4 CPUs available`.
        Use `0` (no limit) or a value ≤ `nproc`, and keep `JEFF_THREADS` ≤
        `nproc` (e.g. `4` on 4 cores, `6` on 8 cores).

    Everything else has sane defaults; see
    [Environment variables](environment-variables.md). Pin
    `JEFF_DOCKER_TAG` to a release in production instead of `latest`.

    !!! warning "Does Dokploy pass these into the container?"
        Yes, but only because `docker-compose.dokploy.yml` references every
        variable as `${VAR}` inside `environment:`. Dokploy writes the
        Environment tab to a `.env` file next to the compose file and does
        **not** inject it automatically
        ([Dokploy docs](https://docs.dokploy.com/docs/core/docker-compose)).
        If you write your own compose file, keep the `${VAR}` references or
        add `env_file: .env`.

5. **Domains** tab → **Add Domain**:
     - Service: `jeff`
     - Host: `jeff.example.com` (or a LAN name, see below)
     - Container Port: **`8000`**
     - HTTPS: on, Certificate: Let's Encrypt (public domains only)
6. **Deploy**, then open **Logs**. First deploy:

    ```text
    [entrypoint] Downloading knowledgator/gliformer-large-v1 (revision main) into /models/gliformer-large-v1 ...
    [entrypoint] Model download complete.
    ... jeff ready: backend=torch model=gliformer-large-v1
    ```

    Later deploys print `Model already present` and start in seconds.
7. Test from your machine:

    ```bash
    curl https://jeff.example.com/healthz
    curl https://jeff.example.com/v1/models -H "Authorization: Bearer <key>"
    ```

8. Optional: **Volume Backups** tab → schedule a backup of `jeff-models`
   (saves the ~1.7 GB re-download after a disaster; not strictly needed).

## Mode B — Compose, build from source

Same as Mode A, but **Compose Path** `./docker-compose.yml`, and add to
`docker-compose.yml` the Dokploy network (or use the raw editor):

```yaml
    networks: [dokploy-network]
networks:
  dokploy-network:
    external: true
```

and remove the `ports:` block. Dokploy builds the image on every deploy
(5–10 minutes). Use this when you forked the repo or pin `JEFF_REF`.

## Mode C — Application service

1. **Create Service → Application**.
2. **General** → Provider **Docker**, image
   `ghcr.io/tommasomarchionni/jeff-docker:0.2.0`.
   (Or Provider GitHub, Build Type `Dockerfile`, Dockerfile path
   `docker/Dockerfile`, context `.`.)
3. **Environment**: same variables as Mode A (passed directly).
4. **Advanced → Volumes**: add two **Volume Mounts**:
   `jeff-models` → `/models` and `jeff-data` → `/data`.
   Skipping this re-downloads the model on every deploy.
5. **Advanced → Resources**: memory limit 10 GB, CPU 8.
6. **Domains**: container port `8000`.
7. Deploy and check logs as in Mode A.

## LAN-only access (no public domain)

If Jeff must stay inside your home network:

1. Create a local DNS record (router, Pi-hole, AdGuard Home) such as
   `jeff.home.lan` → IP of the Dokploy host/LXC.
2. In **Domains**, use that host, HTTPS **off** (or a certificate from your
   internal CA), port `8000`.
3. Do **not** forward ports 80/443 on your router for this domain.

Alternatively, skip Domains entirely and reach Jeff only from other Dokploy
services at `http://jeff:8000` on `dokploy-network`.

## Dokploy inside a Proxmox LXC

Typical layout: Proxmox VE on a mini PC → unprivileged LXC with Docker →
Dokploy → Jeff.

**LXC settings** (Proxmox UI → CT → Resources / Options):

| Setting | Recommended for `gliformer-large-v1` |
|---|---|
| Cores | 8 (Jeff uses `JEFF_THREADS=6`, the rest stays for Dokploy/Traefik) |
| Memory | 16 GB (12 GB minimum) |
| Swap | 4 GB |
| Root disk | 30 GB+ |
| Features | `nesting=1`, `keyctl=1` |

**Why limits matter**: if the container exceeds the LXC memory, the kernel
OOM killer may kill Jeff (exit code 137) or even other services. Keep
`JEFF_MEM_LIMIT` below the LXC memory minus ~3 GB for Dokploy, Traefik and
the OS.

**CPU-only is the supported mode here.** The integrated Radeon (780M on
the UM890 Pro) can in theory be passed to an LXC and to Docker, but the
chain is fragile; see [AMD ROCm (experimental)](experimental/amd-rocm.md).

## Updating

1. Change `JEFF_DOCKER_TAG` (e.g. `0.2.0` → `0.3.0`) in **Environment**.
2. **Deploy**. The model volume is reused.
3. Roll back by setting the previous tag and deploying again.

Enable **Autodeploy** (Git provider) only if you track `latest`; with
pinned tags, updates are a deliberate change of `JEFF_DOCKER_TAG`.

## Dokploy-specific troubleshooting

| Symptom | Cause / fix |
|---|---|
| `404 page not found` on the domain | Domain port isn't `8000`, or the service isn't on `dokploy-network` (Mode B without the network block) |
| `Bad Gateway` right after deploy | Model still downloading; wait for `jeff ready` in Logs |
| Variables ignored | Custom compose file without `${VAR}` references (see warning above) |
| Model re-downloaded on every deploy | Mode C without volume mounts, or volumes deleted |
| `network dokploy-network not found` | Running the Dokploy compose outside Dokploy: `docker network create dokploy-network` |
| `range of CPUs is from 0.01 to N.00, as there are only N CPUs available` | `JEFF_CPU_LIMIT` is higher than the CPUs of the host/LXC: set it to `0` or ≤ `nproc` and redeploy |
| Container killed, exit 137 | Raise LXC memory or lower `JEFF_MEM_LIMIT`/`JEFF_MAX_BATCH` |

More in [Troubleshooting](troubleshooting.md).
