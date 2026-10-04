# Security

- `JEFF_API_KEYS` is mandatory; the container refuses to start without it.
- Never commit `.env`; store secrets in Dokploy Environment.
- Dokploy compose exposes no host port; traffic goes through Traefik with TLS.
- Local compose binds to `127.0.0.1`.
- Container runs as non-root UID 10001 with `tini` as PID 1.
- Pin `JEFF_DOCKER_TAG` and `JEFF_MODEL_REVISION` for reproducible deployments.
- Images ship SBOM and build provenance attestations:
  `gh attestation verify oci://ghcr.io/tommasomarchionni/jeff-docker:<tag> -R tommasomarchionni/jeff-docker`
