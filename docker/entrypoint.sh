#!/usr/bin/env bash
set -euo pipefail

log() { printf '[jeff-docker] %s\n' "$*"; }
die() { printf '[jeff-docker] ERROR: %s\n' "$*" >&2; exit 1; }

: "${JEFF_MODEL_ID:=knowledgator/gliformer-large-v1}"
: "${JEFF_MODEL_PATH:=/models/$(basename "$JEFF_MODEL_ID")}"
: "${JEFF_MODEL_REVISION:=main}"
: "${JEFF_DOWNLOAD_MODEL:=true}"
: "${JEFF_FORCE_MODEL_DOWNLOAD:=false}"
: "${JEFF_ALLOW_NO_AUTH:=false}"

is_true() { [[ "${1,,}" =~ ^(1|true|yes|on)$ ]]; }

# --- Auth ---------------------------------------------------------------
if [[ -z "${JEFF_API_KEYS:-}" ]]; then
  is_true "$JEFF_ALLOW_NO_AUTH" || die "JEFF_API_KEYS is empty. Set it, or JEFF_ALLOW_NO_AUTH=true for local tests only."
  log "WARNING: authentication disabled (JEFF_ALLOW_NO_AUTH=true)."
fi

# --- Model --------------------------------------------------------------
model_complete() { [[ -f "$1/.jeff-download-complete" ]]; }

if is_true "$JEFF_FORCE_MODEL_DOWNLOAD" && [[ -d "$JEFF_MODEL_PATH" ]]; then
  log "Forcing model re-download."
  rm -f "$JEFF_MODEL_PATH/.jeff-download-complete"
fi

if ! model_complete "$JEFF_MODEL_PATH"; then
  if is_true "$JEFF_DOWNLOAD_MODEL"; then
    log "Downloading $JEFF_MODEL_ID@$JEFF_MODEL_REVISION -> $JEFF_MODEL_PATH"
    mkdir -p "$JEFF_MODEL_PATH"
    hf download "$JEFF_MODEL_ID" --revision "$JEFF_MODEL_REVISION" --local-dir "$JEFF_MODEL_PATH"
    printf '%s@%s\n' "$JEFF_MODEL_ID" "$JEFF_MODEL_REVISION" > "$JEFF_MODEL_PATH/.jeff-download-complete"
  elif [[ -n "$(ls -A "$JEFF_MODEL_PATH" 2>/dev/null)" ]]; then
    log "Model dir present without marker, assuming manually provisioned."
  else
    die "Model missing at $JEFF_MODEL_PATH and JEFF_DOWNLOAD_MODEL=false."
  fi
else
  log "Model already present: $(cat "$JEFF_MODEL_PATH/.jeff-download-complete")"
fi

export JEFF_MODEL="$JEFF_MODEL_PATH"
log "Upstream revision: $(cat /app/.jeff-revision 2>/dev/null || echo unknown)"
log "Device=${JEFF_DEVICE:-auto} Backend=${JEFF_BACKEND:-torch} Threads=${JEFF_THREADS:-auto}"

if [[ -n "${JEFF_THREADS:-}" ]]; then
  export OMP_NUM_THREADS="$JEFF_THREADS" MKL_NUM_THREADS="$JEFF_THREADS"
fi

exec "$@"
