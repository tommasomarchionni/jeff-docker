# AMD ROCm (experimental, unsupported)

!!! warning
    Not covered by CI or the compatibility guarantee. Radeon 780M (`gfx1103`) is not on the
    official ROCm container support list. Do not use with Dokploy in production.

## Chain

Proxmox host (amdgpu + ROCm userspace) → LXC (`/dev/kfd`, `/dev/dri`) → Docker → container.

## 1. Host

```bash
lsmod | grep amdgpu
ls -la /dev/kfd /dev/dri
stat -c '%n major=%t minor=%T' /dev/kfd /dev/dri/*
```

## 2. LXC (`/etc/pve/lxc/<CTID>.conf`)

```ini
lxc.cgroup2.devices.allow: c 226:* rwm
lxc.cgroup2.devices.allow: c 235:* rwm   # use the real KFD major from stat
lxc.mount.entry: /dev/kfd dev/kfd none bind,optional,create=file
lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
```

Map `video`/`render` GIDs for unprivileged containers, then `pct restart <CTID>`.

## 3. Validate PyTorch in the LXC

```bash
docker run --rm --device=/dev/kfd --device=/dev/dri --group-add video --group-add render \
  -e HSA_OVERRIDE_GFX_VERSION=11.0.0 rocm/pytorch:latest \
  python3 -c "import torch;print(torch.version.hip, torch.cuda.is_available())"
```

Stop here if it prints `False`.

## 4. Run Jeff

A ROCm build of torch is required; the default image ships CPU torch. Build a custom image
replacing torch with the ROCm wheel, then:

```bash
docker compose -f docker-compose.yml -f docker-compose.rocm.experimental.yml up -d --build
```

## Rollback

Remove the overlay and set `JEFF_DEVICE=cpu`.
