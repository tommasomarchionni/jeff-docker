# Upgrades and versioning

## Versioning

This repository follows [Semantic Versioning](https://semver.org/):

- **Patch** (`0.2.1`): fixes, dependency bumps, docs.
- **Minor** (`0.3.0`): new options, new upstream Jeff revision.
- **Major** (`1.0.0`): breaking changes to variables, volumes or defaults.

Every release has [notes](https://github.com/tommasomarchionni/jeff-docker/releases)
and a [CHANGELOG](https://github.com/tommasomarchionni/jeff-docker/blob/main/CHANGELOG.md)
entry. The image embeds the upstream Jeff revision it was built from
(`/app/.jeff-revision`, printed at startup).

## Upgrade

=== "Compose"

    ```bash
    sed -i 's/^JEFF_DOCKER_TAG=.*/JEFF_DOCKER_TAG=0.3.0/' .env
    docker compose -f docker-compose.prebuilt.yml pull
    docker compose -f docker-compose.prebuilt.yml up -d --wait
    ```

=== "Dokploy"

    Change `JEFF_DOCKER_TAG` in Environment → **Deploy**.

=== "docker run"

    ```bash
    docker pull ghcr.io/tommasomarchionni/jeff-docker:0.3.0
    docker rm -f jeff && docker run ... ghcr.io/tommasomarchionni/jeff-docker:0.3.0
    ```

## Roll back

Set the previous tag and redeploy. Volumes are compatible across versions
unless a major release says otherwise.

## Automatic updates

Not recommended for production. If you use Watchtower or Dokploy
autodeploy, track a minor line (`JEFF_DOCKER_TAG=0.2`) rather than
`latest`.

## Upgrading the model

Model weights are independent from the image. Change
`JEFF_MODEL_REVISION` and set `JEFF_FORCE_MODEL_DOWNLOAD=true` once (see
[Models](models.md#pinning-a-revision-reproducible-deployments)). If you use
ONNX, delete `<model>/onnx` so the encoder is re-exported.
