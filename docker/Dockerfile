# syntax=docker/dockerfile:1.7
#
# jeff-docker — CPU-first container image for Jeff
# (https://github.com/logan-markewich/jeff).
#
# Build args:
#   JEFF_REF          upstream git ref (branch, tag or commit SHA) to build
#   TORCH_VERSION     PyTorch version (must match upstream uv.lock)
#   TORCH_INDEX_URL   PyTorch wheel index. Default: CPU-only wheels (no CUDA,
#                     ~5 GB smaller). Use https://download.pytorch.org/whl/cu130
#                     for an NVIDIA build (experimental, amd64 only).
#   UV_EXTRAS         upstream optional extras to install (default: onnx)
#   JEFF_DOCKER_VERSION  version string shown in logs/labels

ARG PYTHON_VERSION=3.12

# ---------------------------------------------------------------------------
# Stage 1: builder — resolves dependencies into /opt/venv
# ---------------------------------------------------------------------------
FROM python:${PYTHON_VERSION}-slim AS builder

ARG JEFF_REPO=https://github.com/logan-markewich/jeff.git
ARG JEFF_REF=main
ARG UV_VERSION=0.8.22
ARG UV_EXTRAS=onnx
ARG TORCH_VERSION=2.14.0
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu

ENV UV_LINK_MODE=copy \
    UV_NO_CACHE=1 \
    UV_PYTHON_DOWNLOADS=never

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir "uv==${UV_VERSION}"

WORKDIR /app
RUN git clone "${JEFF_REPO}" /app \
 && git checkout "${JEFF_REF}" \
 && git rev-parse --short=12 HEAD > /app/.jeff-revision \
 && rm -rf .git

# Export the exact locked dependency set, drop the CUDA stack (torch, triton,
# nvidia-*, cuda-*) and install torch from the selected index instead.
# CPU wheels are installed with --no-deps (their pure-Python deps are already
# in the lock file); GPU wheels pull their own CUDA/ROCm runtime packages.
RUN extras=(); for e in ${UV_EXTRAS//,/ }; do extras+=(--extra "$e"); done \
 && uv export --frozen --no-hashes --no-dev --no-emit-project "${extras[@]}" -o /tmp/requirements.txt \
 && grep -vE '^(torch|triton|nvidia-|cuda-)' /tmp/requirements.txt > /tmp/requirements-notorch.txt \
 && uv venv /opt/venv \
 && if [[ "${TORCH_INDEX_URL}" == */cpu ]]; then torch_args=(--no-deps); \
    else torch_args=(--extra-index-url https://pypi.org/simple); fi \
 && uv pip install --python /opt/venv/bin/python "${torch_args[@]}" \
      --index-url "${TORCH_INDEX_URL}" "torch==${TORCH_VERSION}" \
 && uv pip install --python /opt/venv/bin/python -r /tmp/requirements-notorch.txt \
 && uv pip install --python /opt/venv/bin/python --no-deps /app \
 && /opt/venv/bin/python -c "import torch, jeff.server.main; print('torch', torch.__version__)"

# ---------------------------------------------------------------------------
# Stage 2: runtime — minimal image, non-root
# ---------------------------------------------------------------------------
FROM python:${PYTHON_VERSION}-slim AS runtime

ARG JEFF_DOCKER_VERSION=dev
ARG JEFF_REF=main

LABEL org.opencontainers.image.title="jeff-docker" \
      org.opencontainers.image.description="CPU-first Docker distribution for Jeff, a self-hosted TypeSafe jev-compatible API powered by GLiFormer." \
      org.opencontainers.image.source="https://github.com/tommasomarchionni/jeff-docker" \
      org.opencontainers.image.documentation="https://tommasomarchionni.github.io/jeff-docker/" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.version="${JEFF_DOCKER_VERSION}" \
      io.github.jeff.upstream-ref="${JEFF_REF}"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/opt/venv/bin:$PATH \
    HF_HOME=/data/huggingface \
    XDG_CACHE_HOME=/data/cache \
    HF_HUB_DISABLE_TELEMETRY=1 \
    JEFF_HOST=0.0.0.0 \
    JEFF_PORT=8000 \
    JEFF_DOCKER_VERSION=${JEFF_DOCKER_VERSION}

RUN apt-get update \
 && apt-get install -y --no-install-recommends tini ca-certificates \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --system --uid 10001 --user-group --create-home --home-dir /home/jeff jeff \
 && mkdir -p /models /data/huggingface /data/cache \
 && chown -R jeff:jeff /models /data

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app/scripts /app/scripts
COPY --from=builder /app/.jeff-revision /app/.jeff-revision
COPY --chmod=0755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=0644 docker/healthcheck.py /usr/local/bin/healthcheck.py

WORKDIR /app
USER jeff
EXPOSE 8000
VOLUME ["/models", "/data"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=5 \
  CMD ["python", "/usr/local/bin/healthcheck.py"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["jeff"]
