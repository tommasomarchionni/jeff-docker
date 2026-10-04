"""Dependency-free health probe for Jeff."""
import os
import sys
import urllib.request

port = os.environ.get("JEFF_PORT", "8000")
path = os.environ.get("JEFF_HEALTH_PATH", "/healthz")
try:
    with urllib.request.urlopen(f"http://127.0.0.1:{port}{path}", timeout=5) as r:
        sys.exit(0 if 200 <= r.status < 300 else 1)
except Exception as exc:  # noqa: BLE001
    print(f"healthcheck failed: {exc}", file=sys.stderr)
    sys.exit(1)
