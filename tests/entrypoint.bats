#!/usr/bin/env bats
# Static tests for the entrypoint (no model download).

setup() {
  export JEFF_MODEL_PATH="$BATS_TEST_TMPDIR/model"
  export JEFF_DOWNLOAD_MODEL=false
  ENTRY="$BATS_TEST_DIRNAME/../docker/entrypoint.sh"
}

@test "fails without API key" {
  unset JEFF_API_KEYS
  run bash "$ENTRY" true
  [ "$status" -ne 0 ]
  [[ "$output" == *"JEFF_API_KEYS is empty"* ]]
}

@test "fails when model missing and download disabled" {
  export JEFF_API_KEYS=test
  run bash "$ENTRY" true
  [ "$status" -ne 0 ]
  [[ "$output" == *"Model missing"* ]]
}

@test "starts when model marker exists" {
  export JEFF_API_KEYS=test
  mkdir -p "$JEFF_MODEL_PATH"
  echo "x@main" > "$JEFF_MODEL_PATH/.jeff-download-complete"
  run bash "$ENTRY" true
  [ "$status" -eq 0 ]
  [[ "$output" == *"Model already present"* ]]
}

@test "no-auth allowed only when explicit" {
  unset JEFF_API_KEYS
  export JEFF_ALLOW_NO_AUTH=true
  mkdir -p "$JEFF_MODEL_PATH"; touch "$JEFF_MODEL_PATH/.jeff-download-complete"
  run bash "$ENTRY" true
  [ "$status" -eq 0 ]
  [[ "$output" == *"authentication disabled"* ]]
}
