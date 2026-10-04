# Platform setup (macOS, Windows, Linux, Proxmox)

The image runs anywhere Docker runs. Pick your platform, install Docker,
then continue with the [Quick start](quick-start.md).

## macOS

1. Install [Docker Desktop for Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
   (Apple Silicon or Intel build) or [OrbStack](https://orbstack.dev/) as a
   lighter alternative.
2. **Settings → Resources**: at least **6 GB memory** (8 GB+ recommended)
   and 4+ CPUs.
3. Apple Silicon pulls the native `linux/arm64` image automatically.

!!! note "Apple GPU (MPS)"
    Containers on macOS run inside a Linux VM, which has no access to the
    Apple GPU. Inside Docker Jeff always runs on CPU. If you need MPS, run
    upstream Jeff natively with `uv` (see the
    [upstream README](https://github.com/logan-markewich/jeff)).

## Windows

1. Enable WSL2: `wsl --install` in an elevated PowerShell, then reboot.
2. Install [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
   with the **WSL2 backend**.
3. Limit/raise WSL2 memory in `%UserProfile%\.wslconfig`:

    ```ini
    [wsl2]
    memory=10GB
    processors=8
    ```

    then `wsl --shutdown` and restart Docker Desktop.
4. Run commands from PowerShell or, better, from a WSL Ubuntu shell
   (the bash snippets in this documentation then work as-is).

## Linux (Debian/Ubuntu/Fedora/...)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"   # log out and back in afterwards
docker run --rm hello-world
```

The Compose plugin (`docker compose`) is included. Check with
`docker compose version`.

## Raspberry Pi 5 / ARM servers

Use a 64-bit OS (`uname -m` must print `aarch64`). The `linux/arm64` image
works on 8 GB boards; prefer `gliformer-base-v1` and the
[ONNX int8 backend](onnx.md) for acceptable latency on a Pi.

## Proxmox VE

Two options, both supported:

| | LXC container | VM |
|---|---|---|
| Overhead | Lowest | Slightly higher |
| Docker inside | Needs `nesting=1` (+ `keyctl=1` if unprivileged) | Works out of the box |
| Best for | Dokploy / Docker host on a NUC | Strict isolation |

LXC checklist (Proxmox UI → container → Options → Features):

- `nesting=1` and, for unprivileged containers, `keyctl=1`.
- Resources: 8 vCPU, 12–16 GB RAM, 4 GB swap, 30 GB disk for a
  comfortable `gliformer-large-v1` setup.
- Inside the LXC: install Docker with the Linux instructions above.

Then deploy with [Docker Compose](docker-compose-guide.md) or
[Dokploy](dokploy.md).

## Verify

```bash
docker info --format '{{.OSType}}/{{.Architecture}} CPUs={{.NCPU}} Mem={{.MemTotal}}'
```
