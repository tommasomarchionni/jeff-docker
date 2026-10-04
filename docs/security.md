# Security

## Defaults

| Control | Default |
|---|---|
| Authentication | `JEFF_API_KEYS` **mandatory**; the container exits if empty |
| User | Non-root `jeff` (UID 10001) |
| Privileges | `no-new-privileges`, `cap_drop: ALL` in Compose |
| Network | Port bound to `127.0.0.1` (Compose), no host port in Dokploy |
| PID 1 | `tini` |
| Supply chain | SBOM, SLSA provenance, GitHub attestation on every image |
| Updates | Dependabot for actions, base image and docs toolchain |

## API keys

- Generate with `openssl rand -hex 32`; one key per client, comma-separated.
- Store them in Dokploy Environment or a `.env` with `chmod 600`; never in
  Git (`.env` is in `.gitignore`).
- Rotate: add the new key, update clients, remove the old one, redeploy.
- `JEFF_ALLOW_NO_AUTH=true` is for local tests only.

## Exposure

- Always put TLS in front (Dokploy/Traefik, Caddy, Nginx).
- Prefer LAN-only or VPN (WireGuard, Tailscale) for personal use.
- Keep `JEFF_RATE_LIMIT_RPS` and request limits set on any shared endpoint.

## Reverse proxy hardening

Block the unauthenticated `/stats` endpoint publicly:

=== "Caddy"

    ```caddyfile
    jeff.example.com {
        @stats path /stats
        respond @stats 404
        reverse_proxy 127.0.0.1:8000
    }
    ```

=== "Nginx"

    ```nginx
    location = /stats { return 404; }
    location / { proxy_pass http://127.0.0.1:8000; }
    ```

=== "Traefik (Dokploy)"

    Add a second router for `PathPrefix(`/stats`)` pointing to a
    `noop@internal` service, or restrict it with an `ipAllowList` middleware.

Optionally add an IP allow-list or basic auth for an extra layer.

## Verifying images

```bash
gh attestation verify oci://ghcr.io/tommasomarchionni/jeff-docker:0.2.0 \
  -R tommasomarchionni/jeff-docker
```

## Reporting vulnerabilities

See [SECURITY.md](https://github.com/tommasomarchionni/jeff-docker/blob/main/SECURITY.md):
use GitHub private vulnerability reporting, never public issues.
