# NVIDIA GPU (experimental)

The published image is CPU-only. For NVIDIA GPUs build locally with CUDA
wheels. Upstream Jeff is designed for this path (it is what the hosted Modal
deployment uses), but this repository does not test it in CI.

## Requirements

- Linux `amd64` host (or WSL2) with a recent NVIDIA driver.
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).
- Check: `docker run --rm --gpus all nvidia/cuda:12.6.0-base-ubuntu24.04 nvidia-smi`.

## Run

```bash
git clone https://github.com/tommasomarchionni/jeff-docker.git && cd jeff-docker
cp .env.example .env    # set JEFF_API_KEYS
docker compose -f docker-compose.yml -f docker-compose.nvidia.experimental.yml up -d --build
```

The overlay uses `TORCH_INDEX_URL=https://download.pytorch.org/whl/cu130`,
`gpus: all`, `JEFF_DEVICE=cuda`, `JEFF_DTYPE=bf16`, `JEFF_MAX_BATCH=32`,
`JEFF_MAX_WAIT_MS=5`. Upstream also supports `JEFF_ATTN=flash` and
`JEFF_COMPILE=1` for extra speed.

Upstream measured about 50 requests/s per container on an NVIDIA L4 over
HTTP; numbers depend on batching and request size.

## eGPU via OCuLink

Mini PCs with OCuLink (e.g. MINISFORUM UM890 Pro) can host an external
NVIDIA card. On Proxmox, pass the PCIe device to a **VM** (PCI passthrough)
rather than an LXC for the simplest driver setup, then follow this page
inside the VM.
