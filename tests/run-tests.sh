#!/usr/bin/env bash
# Runs the verification suite locally using Docker only (nothing to install
# on the host besides Docker): shellcheck, hadolint, bats, compose validation,
# image build and docs build.
#
# Usage:
#   ./tests/run-tests.sh            # static checks + image build + docs
#   SKIP_BUILD=1 ./tests/run-tests.sh
set -Eeuo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

echo "==> Shellcheck"
docker run --rm -v "$(pwd)":/mnt -w /mnt koalaman/shellcheck:stable docker/entrypoint.sh tests/run-tests.sh

echo "==> Hadolint"
docker run --rm -i -v "$(pwd)/.hadolint.yaml":/.config/hadolint.yaml hadolint/hadolint < docker/Dockerfile

echo "==> Unit tests (bats)"
docker run --rm -v "$(pwd)":/code -w /code bats/bats:latest tests/test_entrypoint.bats

echo "==> Compose validation"
tmp_env=$(mktemp)
sed 's/^JEFF_API_KEYS=.*/JEFF_API_KEYS=local-test/' .env.example > "$tmp_env"
docker network inspect dokploy-network >/dev/null 2>&1 || docker network create dokploy-network >/dev/null
for f in docker-compose.yml docker-compose.prebuilt.yml docker-compose.dokploy.yml; do
  docker compose --env-file "$tmp_env" -f "$f" config -q
done
rm -f "$tmp_env"

if [[ -z "${SKIP_BUILD:-}" ]]; then
  echo "==> Docker image build"
  docker build -t jeff-docker:test -f docker/Dockerfile .
  echo "==> Image checks"
  docker run --rm --entrypoint python jeff-docker:test -c "import torch, jeff.server.main; print(torch.__version__)"
  test "$(docker run --rm --entrypoint id jeff-docker:test -u)" = "10001"
fi

echo "==> Docs site build (mkdocs --strict)"
docker run --rm \
  -e PIP_ROOT_USER_ACTION=ignore -e PIP_DISABLE_PIP_VERSION_CHECK=1 -e NO_MKDOCS_2_WARNING=true \
  -v "$(pwd)":/docs -w /docs python:3.12-slim bash -c \
  "pip install --quiet -r docs/requirements.txt && mkdocs build --strict"

echo
echo "All checks passed."
