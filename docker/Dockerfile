# syntax=docker/dockerfile:1.7
FROM python:3.12-slim AS base

ARG JEFF_REPO=https://github.com/logan-markewich/jeff.git
ARG JEFF_REF=main
ARG UV_EXTRAS=dev

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_LINK_MODE=copy \
    UV_NO_CACHE=1 \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    PATH=/opt/venv/bin:$PATH \
    HF_HOME=/data/huggingface \
    XDG_CACHE_HOME=/data/cache \
    JEFF_HOST=0.0.0.0 \
    JEFF_PORT=8000

RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates tini \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir uv

WORKDIR /app
RUN git clone ${JEFF_REPO} /app \
 && git checkout ${JEFF_REF} \
 && git rev-parse HEAD > /app/.jeff-revision \
 && rm -rf .git

RUN uv sync --frozen --extra ${UV_EXTRAS} \
 && uv pip install --python /opt/venv/bin/python "huggingface_hub[cli]"

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/healthcheck.py /usr/local/bin/healthcheck.py
RUN chmod +x /usr/local/bin/entrypoint.sh \
 && useradd --system --uid 10001 --create-home jeff \
 && mkdir -p /models /data/huggingface /data/cache \
 && chown -R jeff:jeff /models /data /app

USER jeff
EXPOSE 8000
VOLUME ["/models", "/data"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=180s --retries=5 \
  CMD ["python", "/usr/local/bin/healthcheck.py"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["jeff"]
