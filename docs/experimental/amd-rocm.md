# AMD ROCm (experimental)

!!! warning "Unsupported"
    Not covered by CI or the support policy. The Radeon 780M (`gfx1103`)
    is not in the official ROCm support list; it often works with
    `HSA_OVERRIDE_GFX_VERSION=11.0.0`, but stability varies with kernel,
    firmware and ROCm versions. For a ~400 M classifier, an 8-core Zen 4
    CPU may be just as fast. **Benchmark before switching.**

## Chain to make work

```text
Radeon iGPU → Proxmox host (amdgpu driver, /dev/kfd, /dev/dri)
           → LXC (device bind mounts + cgroup allow)
           → Docker (--device /dev/kfd /dev/dri, groups video/render)
           → jeff-docker built with ROCm PyTorch wheels
```

Test each layer before moving to the next.

## 1. Host (Proxmox)

```bash
lsmod | grep amdgpu
ls -la /dev/kfd /dev/dri
stat -c '%n major=%t minor=%T' /dev/kfd /dev/dri/*   # hex majors
```

Assign enough RAM to the iGPU carve-out in BIOS (UMA frame buffer) if
available; ROCm also uses GTT (shared) memory.

## 2. LXC (`/etc/pve/lxc/<CTID>.conf`)

```ini
lxc.cgroup2.devices.allow: c 226:* rwm
lxc.cgroup2.devices.allow: c <kfd-major-decimal>:* rwm
lxc.mount.entry: /dev/kfd dev/kfd none bind,optional,create=file
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
```

For unprivileged containers map the host `video`/`render` GIDs
(`lxc.idmap` + `/etc/subgid`), or make the device nodes accessible.
Then `pct restart <CTID>` and check `ls -la /dev/kfd /dev/dri` inside.

## 3. Docker inside the LXC

```bash
docker run --rm --device=/dev/kfd --device=/dev/dri \
  --group-add video --group-add render \
  -e HSA_OVERRIDE_GFX_VERSION=11.0.0 rocm/pytorch:latest \
  python3 -c "import torch; print(torch.version.hip, torch.cuda.is_available(), torch.cuda.get_device_name(0) if torch.cuda.is_available() else '')"
```

Stop here if it prints `False`.

## 4. Build and run Jeff with ROCm

```bash
git clone https://github.com/tommasomarchionni/jeff-docker.git && cd jeff-docker
cp .env.example .env    # set JEFF_API_KEYS
docker compose -f docker-compose.yml -f docker-compose.rocm.experimental.yml up -d --build
docker compose logs -f jeff   # expect device=cuda in the backend line
```

The overlay builds with `TORCH_INDEX_URL=https://download.pytorch.org/whl/rocm7.2`
(several GB larger than the CPU image), sets `JEFF_DEVICE=cuda` (PyTorch
ROCm exposes HIP as `cuda`), the GFX override and the devices.

On Dokploy use Mode B (build from source) with both files merged into one
compose file in the raw editor; keep it in a separate service from your
CPU deployment.

## 5. Compare

Run the [benchmark](../performance.md#benchmark) with CPU and ROCm, same
payloads. Keep ROCm only if p95 latency or throughput improves clearly.

## Rollback

Remove the overlay, `docker compose up -d --build` (CPU image), or redeploy
the prebuilt CPU image.
