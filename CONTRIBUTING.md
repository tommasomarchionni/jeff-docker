# Contributing

Thanks for helping improve jeff-docker.

## Scope

- **This repository**: Docker image, entrypoint, Compose files, CI,
  documentation, deployment guides.
- **Upstream** ([logan-markewich/jeff](https://github.com/logan-markewich/jeff)):
  model behavior, API semantics, inference code.

## Workflow

1. Fork and branch from `main`.
2. Use [Conventional Commits](https://www.conventionalcommits.org/)
   (`feat:`, `fix:`, `docs:`, `ci:`, `chore:`).
3. Run the checks locally (only Docker needed):

    ```bash
    ./tests/run-tests.sh
    ```

4. If you add or change a variable, update **all** of: `.env.example`, the
   three Compose files, `docs/environment-variables.md`.
5. Add an entry under `[Unreleased]` in `CHANGELOG.md`.
6. Open a PR using the template. CI and the smoke test must pass.

## Releasing (maintainers)

```bash
# move [Unreleased] entries to a new version section in CHANGELOG.md
git tag -a vX.Y.Z -m "vX.Y.Z" && git push origin vX.Y.Z
```

The publish workflow builds the multi-arch image, pushes the semver tags,
creates the GitHub Release and verifies the published image.

## Docs preview

```bash
pip install -r docs/requirements.txt
mkdocs serve
```
