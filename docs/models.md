# Models

Jeff serves [GLiFormer](https://huggingface.co/knowledgator) checkpoints.
The image does **not** contain weights: they are downloaded on first start
into the `/models` volume.

| Model | Params | Disk | Notes |
|---|---|---|---|
| [`knowledgator/gliformer-large-v1`](https://huggingface.co/knowledgator/gliformer-large-v1) | ~400 M | ~1.7 GB | **Default**, best quality |
| [`knowledgator/gliformer-base-v1`](https://huggingface.co/knowledgator/gliformer-base-v1) | ~264 M | ~1.1 GB | Faster, lower quality; set `JEFF_NOUL_MODE=single` |

## How the download works

1. On start the entrypoint looks for `<JEFF_MODEL_PATH>/.jeff-download-complete`.
2. Missing → `hf download <JEFF_MODEL_ID> --revision <JEFF_MODEL_REVISION>`
   into `JEFF_MODEL_PATH`, then the marker is written.
3. Present → download skipped (`Model already present` in the logs).

An interrupted download leaves no marker, so it resumes on the next start.

## Switching to the base model

```dotenv
JEFF_MODEL_ID=knowledgator/gliformer-base-v1
JEFF_MODEL_PATH=/models/gliformer-base-v1
JEFF_NOUL_MODE=single
JEFF_MODEL_NAME=gliformer-base-v1
```

Both models can coexist in the same volume (different paths).

## Pinning a revision (reproducible deployments)

```bash
curl -s https://huggingface.co/api/models/knowledgator/gliformer-large-v1 | jq -r .sha
```

```dotenv
JEFF_MODEL_REVISION=<that sha>
JEFF_FORCE_MODEL_DOWNLOAD=true   # once, to replace the current weights
```

Set `JEFF_FORCE_MODEL_DOWNLOAD` back to `false` after the first start.

## Private or gated repositories

```dotenv
HF_TOKEN=hf_xxx
JEFF_MODEL_ID=your-org/your-finetune
JEFF_MODEL_PATH=/models/your-finetune
```

## Offline / air-gapped hosts

Download on a connected machine, copy the folder, mount it read-only:

```bash
# connected machine
pip install -U "huggingface_hub[cli]"
hf download knowledgator/gliformer-large-v1 --local-dir ./gliformer-large-v1
tar czf gliformer-large-v1.tgz gliformer-large-v1

# offline host
sudo mkdir -p /srv/jeff/models && sudo tar xzf gliformer-large-v1.tgz -C /srv/jeff/models
sudo chown -R 10001:10001 /srv/jeff/models
```

```yaml
volumes:
  - /srv/jeff/models:/models
environment:
  JEFF_DOWNLOAD_MODEL: "false"
  HF_HUB_OFFLINE: "1"
```

With `JEFF_DOWNLOAD_MODEL=false`, a non-empty directory without marker is
accepted as manually provisioned.

## Pre-seeding a named volume

```bash
docker run --rm -v jeff-models:/models -e JEFF_API_KEYS=x \
  --entrypoint hf ghcr.io/tommasomarchionni/jeff-docker:latest \
  download knowledgator/gliformer-large-v1 --local-dir /models/gliformer-large-v1
docker run --rm -v jeff-models:/models --entrypoint sh \
  ghcr.io/tommasomarchionni/jeff-docker:latest \
  -c 'echo manual > /models/gliformer-large-v1/.jeff-download-complete'
```

## Licenses

Check each model card on Hugging Face for its license before commercial
use. This repository's MIT license covers the packaging only.
