# Docker guide for clamav-unofficial-sigs

The container image is built on the official `clamav/clamav:stable` image, so it always carries a current ClamAV for signature integrity testing.

## Quick start (all-in-one)

Runs clamd, freshclam (official signatures) and the unofficial signature updater in one container:

```bash
docker run -d --name clamav \
  -p 3310:3310 \
  -v clamdb:/var/lib/clamav \
  ghcr.io/extremeshok/clamav-unofficial-sigs:latest
```

clamd listens on TCP 3310 and the unofficial databases refresh every 2 hours.

## Updater sidecar (bring your own clamd)

Share the database volume with an existing clamd container (or a host clamd):

```bash
docker run -d --name clamav-unofficial-sigs \
  -e CUS_MODE=updater \
  -v clamdb:/var/lib/clamav \
  ghcr.io/extremeshok/clamav-unofficial-sigs:latest
```

There is no clamd inside the container in this mode; your clamd picks up the new databases through its SelfCheck interval (default 600 seconds).

## One-shot run (host cron / Kubernetes CronJob)

```bash
docker run --rm \
  -v clamdb:/var/lib/clamav \
  ghcr.io/extremeshok/clamav-unofficial-sigs:latest \
  clamav-unofficial-sigs.sh --force
```

Any arguments replace the update loop, so all script options work, eg. `clamav-unofficial-sigs.sh --whitelist 'Sanesecurity.Junk.12345'`.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CUS_MODE` | `all-in-one` | `all-in-one` (clamd + updater) or `updater` (sidecar loop only) |
| `CUS_UPDATE_HOURS` | `2` | Update loop interval in hours |
| `CUS_USER_CONF` | | Extra user.conf lines (only when no user.conf is mounted) |

Example - enable the optional sources via environment:

```bash
docker run -d \
  -e CUS_USER_CONF=$'ditekshen_enabled="yes"\ntwinclams_enabled="yes"' \
  -v clamdb:/var/lib/clamav \
  ghcr.io/extremeshok/clamav-unofficial-sigs:latest
```

## Custom configuration

For anything beyond simple toggles, bind-mount a full user.conf (see config/user.conf for the template, remember `user_configuration_complete="yes"`):

```bash
docker run -d \
  -v ./user.conf:/etc/clamav-unofficial-sigs/user.conf:ro \
  -v clamdb:/var/lib/clamav \
  ghcr.io/extremeshok/clamav-unofficial-sigs:latest
```

## Compose

See `docker/docker-compose.yml` for ready-made all-in-one and sidecar examples.

## Healthcheck

The image ships a HEALTHCHECK that fails when clamd stops answering (all-in-one mode), when the first update run does not complete within one interval of container start, when the last update run exited with an error, or when the update loop stalls for more than twice the update interval.

## Building locally

```bash
docker build -t clamav-unofficial-sigs .
# or on top of the official debian variant:
docker build --build-arg BASE_IMAGE=clamav/clamav-debian:stable -t clamav-unofficial-sigs .
```
