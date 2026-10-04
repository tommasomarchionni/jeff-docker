# Jeff Docker

Production-oriented Docker distribution for
[Jeff](https://github.com/logan-markewich/jeff), a self-hosted,
TypeSafe jev-compatible structured-classification API powered by GLiFormer.

This project provides reproducible CPU-first Docker images, persistent model
storage, Docker Compose deployments, GitHub Container Registry publishing, and
Dokploy deployment guidance.

> [!IMPORTANT]
> CPU is the supported production runtime. AMD ROCm, integrated Radeon GPUs,
> Proxmox LXC GPU device passthrough, and nested Docker GPU execution are
> experimental and outside the support guarantee.
