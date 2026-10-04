# Contributing

1. Fork, branch from `main`, use Conventional Commits (`feat:`, `fix:`, `docs:`).
2. Validate locally:
   ```bash
   shellcheck docker/entrypoint.sh
   docker run --rm -i hadolint/hadolint < docker/Dockerfile
   bats tests
   docker compose config -q
   ```
3. Update `CHANGELOG.md` and docs; open a PR.
