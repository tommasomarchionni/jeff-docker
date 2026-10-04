# Quick start

1. `cp .env.example .env` and set `JEFF_API_KEYS` (`openssl rand -hex 32`).
2. Local build: `docker compose up -d --build`
   Prebuilt: `docker compose -f docker-compose.prebuilt.yml up -d`
3. First start downloads ~1.6 GB of weights into the `jeff-models` volume; follow with `docker compose logs -f`.
4. `curl http://127.0.0.1:8000/healthz`

Port is bound to `127.0.0.1` by default; change `JEFF_BIND` only behind a firewall/proxy.
