# FAQ

??? question "Is Jeff a chatbot / LLM like Llama?"
    No. It is a classifier: given a text and questions with predefined
    answers (`score`, `choice`, `noul`), it returns probabilities. It does
    not generate free text.

??? question "Do I need a GPU?"
    No. CPU is the supported runtime. On a modern 8-core CPU, typical
    requests take hundreds of milliseconds. GPUs are
    [experimental](experimental/nvidia-gpu.md).

??? question "Can I use the Radeon 780M / integrated AMD GPU?"
    Only experimentally, with ROCm, and the benefit for a 400 M model is
    uncertain. See [AMD ROCm](experimental/amd-rocm.md). CPU is recommended.

??? question "Does it work on Apple Silicon?"
    Yes, the `linux/arm64` image runs natively under Docker Desktop, on CPU.
    The Apple GPU (MPS) is not reachable from containers.

??? question "How much RAM do I need?"
    Roughly 3–6 GB for the large model depending on batch size (estimate,
    check `docker stats`), plus OS/other services. 8 GB is
    the minimum host, 16 GB comfortable. The base model needs less.

??? question "Why is the first start so slow?"
    It downloads ~1.7 GB of weights. Later starts reuse the volume and take
    seconds.

??? question "Why is the model not inside the image?"
    Smaller image, faster pulls, independent model updates, and you can
    choose/pin any checkpoint without rebuilding.

??? question "Is it compatible with the TypeSafe / jev SDK?"
    The wire format is compatible: set the SDK base URL to your instance and
    use one of your keys. Quality differs from the hosted jev service.

??? question "Can I run several models at once?"
    Run several instances, each with its own `JEFF_MODEL_*`, port and volume
    prefix (see [Docker Compose](docker-compose-guide.md#running-multiple-instances)).

??? question "How do I add or revoke a client?"
    Edit `JEFF_API_KEYS` (comma-separated) and redeploy.

??? question "Does it send data anywhere?"
    No requests leave your host. The only outbound connections are the
    model download from Hugging Face (telemetry disabled) and image pulls
    from GHCR.

??? question "Why does `/v1/models` say `gliformer-large-v1` while I run the base model?"
    The reported name comes from `JEFF_MODEL_NAME` (upstream default). Set
    `JEFF_MODEL_NAME=gliformer-base-v1`.

??? question "`latest` or a version tag?"
    Version tags in production (`JEFF_DOCKER_TAG=0.2.0`), `latest` for tests.

??? question "Can I run it on Kubernetes?"
    Yes: one Deployment with the image, a PVC on `/models`, a Secret for
    `JEFF_API_KEYS`, readiness/liveness probes on `/healthz` with a generous
    initial delay. Not officially documented yet; PRs welcome.

??? question "Where do I report wrong answers from the model?"
    Upstream: [logan-markewich/jeff](https://github.com/logan-markewich/jeff/issues).
    Packaging and deployment issues: this repository.
