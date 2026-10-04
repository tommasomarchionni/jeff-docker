#!/usr/bin/env bats
# Unit tests for docker/entrypoint.sh. No network, no model: `hf` is stubbed
# and the final command is `env`/`true` instead of the Jeff server.

setup() {
  ENTRY="$BATS_TEST_DIRNAME/../docker/entrypoint.sh"
  export JEFF_MODEL_PATH="$BATS_TEST_TMPDIR/models/test-model"
  export JEFF_MODEL_ID="org/test-model"
  export JEFF_DOWNLOAD_MODEL=false
  unset JEFF_API_KEYS JEFF_ALLOW_NO_AUTH JEFF_FORCE_MODEL_DOWNLOAD JEFF_WARMUP JEFF_COMPILE JEFF_THREADS

  # Stub `hf download <id> --revision <rev> --local-dir <dir>`
  STUB_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$STUB_BIN"
  cat > "$STUB_BIN/hf" <<'STUB'
#!/usr/bin/env bash
while [[ $# -gt 0 ]]; do
  case "$1" in --local-dir) dir="$2"; shift 2 ;; *) shift ;; esac
done
echo "$*" >> "${HF_STUB_LOG:-/dev/null}"
mkdir -p "$dir" && echo weights > "$dir/pytorch_model.bin"
STUB
  chmod +x "$STUB_BIN/hf"
  export PATH="$STUB_BIN:$PATH"
  export HF_STUB_LOG="$BATS_TEST_TMPDIR/hf.log"
}

provision_model() {
  mkdir -p "$JEFF_MODEL_PATH"
  echo "org/test-model@main" > "$JEFF_MODEL_PATH/.jeff-download-complete"
}

@test "fails without JEFF_API_KEYS" {
  run bash "$ENTRY" true
  [ "$status" -ne 0 ]
  [[ "$output" == *"JEFF_API_KEYS is empty"* ]]
}

@test "empty JEFF_API_KEYS is treated as missing" {
  export JEFF_API_KEYS=""
  run bash "$ENTRY" true
  [ "$status" -ne 0 ]
  [[ "$output" == *"JEFF_API_KEYS is empty"* ]]
}

@test "no-auth mode only when explicitly allowed" {
  export JEFF_ALLOW_NO_AUTH=true
  provision_model
  run bash "$ENTRY" true
  [ "$status" -eq 0 ]
  [[ "$output" == *"authentication is DISABLED"* ]]
}

@test "fails when model is missing and download is disabled" {
  export JEFF_API_KEYS=test
  run bash "$ENTRY" true
  [ "$status" -ne 0 ]
  [[ "$output" == *"Model missing"* ]]
}

@test "downloads the model once and writes the marker" {
  export JEFF_API_KEYS=test JEFF_DOWNLOAD_MODEL=true
  run bash "$ENTRY" true
  [ "$status" -eq 0 ]
  [[ "$output" == *"Model download complete"* ]]
  [ -f "$JEFF_MODEL_PATH/.jeff-download-complete" ]
  run bash "$ENTRY" true
  [[ "$output" == *"Model already present"* ]]
  [ "$(wc -l < "$HF_STUB_LOG")" -eq 1 ]
}

@test "JEFF_FORCE_MODEL_DOWNLOAD re-downloads" {
  export JEFF_API_KEYS=test JEFF_DOWNLOAD_MODEL=true JEFF_FORCE_MODEL_DOWNLOAD=true
  provision_model
  run bash "$ENTRY" true
  [ "$status" -eq 0 ]
  [[ "$output" == *"Model download complete"* ]]
}

@test "manually provisioned model without marker is accepted" {
  export JEFF_API_KEYS=test
  mkdir -p "$JEFF_MODEL_PATH" && echo x > "$JEFF_MODEL_PATH/pytorch_model.bin"
  run bash "$ENTRY" true
  [ "$status" -eq 0 ]
  [[ "$output" == *"provisioned manually"* ]]
}

@test "exports JEFF_MODEL pointing at JEFF_MODEL_PATH" {
  export JEFF_API_KEYS=test
  provision_model
  run bash "$ENTRY" env
  [[ "$output" == *"JEFF_MODEL=$JEFF_MODEL_PATH"* ]]
}

@test "normalizes boolean flags to 1/0" {
  export JEFF_API_KEYS=test JEFF_WARMUP=true JEFF_COMPILE=no
  provision_model
  run bash "$ENTRY" env
  [[ "$output" == *"JEFF_WARMUP=1"* ]]
  [[ "$output" == *"JEFF_COMPILE=0"* ]]
}

@test "drops empty JEFF_* and HF_* variables" {
  export JEFF_API_KEYS=test JEFF_QUANT="" HF_TOKEN=""
  provision_model
  run bash "$ENTRY" env
  [[ "$output" != *"JEFF_QUANT="* ]]
  [[ "$output" != *"HF_TOKEN="* ]]
}

@test "JEFF_THREADS sets OMP/MKL threads" {
  export JEFF_API_KEYS=test JEFF_THREADS=6
  provision_model
  run bash "$ENTRY" env
  [[ "$output" == *"OMP_NUM_THREADS=6"* ]]
  [[ "$output" == *"MKL_NUM_THREADS=6"* ]]
}
