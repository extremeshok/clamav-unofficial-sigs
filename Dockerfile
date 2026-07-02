###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
# clamav-unofficial-sigs on top of the official clamav image
#
# all-in-one (clamd + freshclam + unofficial sigs):
#   docker run -d -p 3310:3310 ghcr.io/extremeshok/clamav-unofficial-sigs
# updater sidecar (shares the database volume with an external clamd):
#   docker run -d -e CUS_MODE=updater -v clamdb:/var/lib/clamav ghcr.io/extremeshok/clamav-unofficial-sigs
#
# See guides/docker.md for full usage
##################

# Also works with the official debian variant: clamav/clamav-debian:stable
ARG BASE_IMAGE=clamav/clamav:stable
FROM ${BASE_IMAGE}

# bash and GNU userland for the update script, gnupg for signature
# verification, bind-tools for the sanesecurity mirror resolution,
# socat for clamd socket reloads
RUN if command -v apk >/dev/null 2>&1 ; then \
        apk upgrade --no-cache && \
        apk add --no-cache bash curl rsync gnupg bind-tools socat tar coreutils sed grep ; \
    else \
        apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            curl rsync gnupg bind9-dnsutils socat && \
        rm -rf /var/lib/apt/lists/* ; \
    fi

COPY clamav-unofficial-sigs.sh /usr/local/sbin/clamav-unofficial-sigs.sh
COPY config/master.conf /etc/clamav-unofficial-sigs/master.conf
COPY config/os/os.docker.conf /etc/clamav-unofficial-sigs/os.conf
COPY docker/entrypoint.sh /usr/local/sbin/cus-entrypoint.sh
COPY docker/healthcheck.sh /usr/local/sbin/cus-healthcheck.sh

RUN chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh \
        /usr/local/sbin/cus-entrypoint.sh \
        /usr/local/sbin/cus-healthcheck.sh && \
    mkdir -p /var/lib/clamav-unofficial-sigs && \
    chown -R clamav:clamav /var/lib/clamav-unofficial-sigs

ENV CUS_MODE=all-in-one \
    CUS_UPDATE_HOURS=2

HEALTHCHECK --interval=5m --timeout=30s --start-period=15m --retries=3 \
    CMD /usr/local/sbin/cus-healthcheck.sh

ENTRYPOINT ["/usr/local/sbin/cus-entrypoint.sh"]
