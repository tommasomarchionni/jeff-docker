# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), [SemVer](https://semver.org/).

## [Unreleased]

### Added
- CPU-first Dockerfile pinned to upstream Jeff ref, non-root, tini.
- Entrypoint with mandatory auth and idempotent model download.
- Compose files: local, prebuilt, Dokploy, experimental ROCm overlay.
- CI (shellcheck, hadolint, compose validation, bats, build), GHCR multi-arch publish, MkDocs Pages.
