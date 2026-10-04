#!/usr/bin/env bash
# jeff-docker entrypoint
#
#  1. Validates authentication settings (JEFF_API_KEYS is mandatory unless
#     JEFF_ALLOW_NO_AUTH=true is set explicitly).
#  2. Makes sure the model weights exist in the persistent /models volume,
#     downloading them from Hugging Face exactly once (idempotent).
#     (with JEFF_BACKEND=onnx, Jeff itself exports the ONNX encoder into
#     <model>/onnx on first start and reuses it afterwards.)
#  3. Hands over to the Jeff server (PID 1 is tini, see Dockerfile).
set -Eeuo pipefail

log() { printf '[entrypoint] %s\n' "$*"; }
die() { printf '[entrypoint] ERROR: %s\n' "$*" >&2; exit 1; }
is_true() { [[ "${1,,}" =~ ^(1|true|yes|on)$ ]]; }

# Compose passes unset variables as empty strings. Upstream Jeff treats an
# empty string differently from "unset" for some settings (e.g. JEFF_QUANT),
# so drop every empty JEFF_*/HF_* variable before starting.
while IFS='=' read -r name _; do
  if [[ "$name" =~ ^(JEFF_|HF_) ]] && [[ -z "${!name}" ]]; then
    unset "$name"
  fi
done < <(env)

: "${JEFF_MODEL_ID:=knowledgator/gliformer-large-v1}"
: "${JEFF_MODEL_PATH:=/models/${JEFF_MODEL_ID##*/}}"
: "${JEFF_MODEL_REVISION:=main}"
: "${JEFF_DOWNLOAD_MODEL:=true}"
: "${JEFF_FORCE_MODEL_DOWNLOAD:=false}"
: "${JEFF_ALLOW_NO_AUTH:=false}"
: "${JEFF_BACKEND:=torch}"
MARKER="$JEFF_MODEL_PATH/.jeff-download-complete"

# --- 1. Authentication --------------------------------------------------
if [[ -z "${JEFF_API_KEYS:-}" ]]; then
  is_true "$JEFF_ALLOW_NO_AUTH" \
    || die "JEFF_API_KEYS is empty. Set it (openssl rand -hex 32), or JEFF_ALLOW_NO_AUTH=true for local tests only."
  log "WARNING: authentication is DISABLED (JEFF_ALLOW_NO_AUTH=true). Never expose this instance."
fi

# --- 2. Model weights ---------------------------------------------------
if is_true "$JEFF_FORCE_MODEL_DOWNLOAD"; then
  log "JEFF_FORCE_MODEL_DOWNLOAD=true: the model will be downloaded again."
  rm -f "$MARKER"
fi

if [[ -f "$MARKER" ]]; then
  log "Model already present: $(cat "$MARKER") at $JEFF_MODEL_PATH"
elif is_true "$JEFF_DOWNLOAD_MODEL"; then
  log "Downloading $JEFF_MODEL_ID (revision $JEFF_MODEL_REVISION) into $JEFF_MODEL_PATH ..."
  mkdir -p "$JEFF_MODEL_PATH" || die "Cannot create $JEFF_MODEL_PATH (volume permissions? see Troubleshooting)."
  hf download "$JEFF_MODEL_ID" --revision "$JEFF_MODEL_REVISION" --local-dir "$JEFF_MODEL_PATH" \
    || die "Model download failed. Check network/DNS, HF_TOKEN and free disk space."
  printf '%s@%s\n' "$JEFF_MODEL_ID" "$JEFF_MODEL_REVISION" > "$MARKER"
  log "Model download complete."
elif [[ -n "$(ls -A "$JEFF_MODEL_PATH" 2>/dev/null)" ]]; then
  log "Model directory provisioned manually (no marker file), using it as-is."
else
  die "Model missing at $JEFF_MODEL_PATH and JEFF_DOWNLOAD_MODEL=false."
fi

# --- 3. Runtime ---------------------------------------------------------
# Upstream only accepts the literal "1" for boolean flags: normalize
# true/yes/on so both styles work.
for flag in JEFF_WARMUP JEFF_COMPILE; do
  if [[ -n "${!flag:-}" ]]; then
    if is_true "${!flag}"; then export "$flag=1"; else export "$flag=0"; fi
  fi
done
export JEFF_MODEL="$JEFF_MODEL_PATH"
if [[ -n "${JEFF_THREADS:-}" ]]; then
  export OMP_NUM_THREADS="$JEFF_THREADS" MKL_NUM_THREADS="$JEFF_THREADS"
fi

log "jeff-docker ${JEFF_DOCKER_VERSION:-dev} | upstream Jeff $(cat /app/.jeff-revision 2>/dev/null || echo unknown)"
log "device=${JEFF_DEVICE:-auto} backend=$JEFF_BACKEND threads=${JEFF_THREADS:-auto} max_batch=${JEFF_MAX_BATCH:-16} auth=$([[ -n "${JEFF_API_KEYS:-}" ]] && echo on || echo off)"

exec "$@"
