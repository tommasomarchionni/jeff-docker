# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
versioning: [SemVer](https://semver.org/).

## [Unreleased]

## [0.2.1] - 2026-10-04

### Fixed
- Default `JEFF_CPU_LIMIT` is now `0` (no limit): the previous default `8`
  made deploys fail on hosts/LXC with fewer than 8 CPUs ("range of CPUs is
  from 0.01 to N"). Default `JEFF_THREADS` lowered to `4`.

## [0.2.0] - 2026-10-04

### Changed
- Image ships **CPU-only PyTorch** (no CUDA/triton packages), multi-stage
  build, OCI labels, upstream revision printed at startup.
- ONNX Runtime included by default (`UV_EXTRAS=onnx`); Jeff exports the
  encoder automatically on first start with `JEFF_BACKEND=onnx`.
- Entrypoint drops empty `JEFF_*`/`HF_*` variables and normalizes boolean
  flags (`true` → `1`) as expected by upstream.
- Compose files: every upstream variable exposed, `no-new-privileges`,
  `cap_drop: ALL`, log rotation, CPU/memory limits, configurable names.
- Publish workflow: `latest`/`edge` on `main`, semver and `sha-` tags,
  GitHub Release on tags, attestation, post-publish verification on native
  amd64 and arm64 runners.

### Added
- End-to-end smoke test workflow (torch + ONNX int8, auth, validation,
  rate limit, persistence, Compose stack), weekly schedule.
- NVIDIA CUDA experimental overlay; ROCm overlay now builds ROCm wheels.
- Full documentation site: beginner quick start, platform setup, prebuilt
  image, Compose, Dokploy (all modes + Proxmox LXC), plain Docker, API
  usage, models, ONNX, persistence, upgrades, monitoring, performance,
  security, testing, troubleshooting, FAQ.
- Dependabot, stale workflow, issue/PR templates, `tests/run-tests.sh`.

## [0.1.0] - 2026-10-04

### Added
- Initial CPU-first Dockerfile, entrypoint with mandatory auth and
  idempotent model download, Compose files (local, prebuilt, Dokploy,
  experimental ROCm), CI, GHCR publish workflow, MkDocs site.

[Unreleased]: https://github.com/tommasomarchionni/jeff-docker/compare/v0.2.1...HEAD
[0.2.1]: https://github.com/tommasomarchionni/jeff-docker/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/tommasomarchionni/jeff-docker/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/tommasomarchionni/jeff-docker/releases/tag/v0.1.0
