#!/usr/bin/env bash
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
# Container healthcheck for clamav-unofficial-sigs
# - all-in-one mode: clamd must answer PING (official clamdcheck.sh)
# - loop health via /tmp/cus-status written by the entrypoint after every
#   update run: fails when the first run never completes within a grace
#   period, when the last run exited non zero, or when the loop stalls
##################

CUS_MODE="${CUS_MODE:-all-in-one}"
CUS_UPDATE_HOURS="${CUS_UPDATE_HOURS:-2}"

if [ "$CUS_MODE" == "all-in-one" ] ; then
    if [ -x /usr/local/bin/clamdcheck.sh ] ; then
        /usr/local/bin/clamdcheck.sh || exit 1
    fi
fi

now="$(date +%s)"
if [ ! -f /tmp/cus-status ] ; then
    # No update run has completed yet, allow one interval plus grace
    started="$(cat /tmp/cus-started 2>/dev/null)"
    if [ -n "$started" ] && [ "$((now - started))" -gt "$((CUS_UPDATE_HOURS * 3600 + 900))" ] ; then
        echo "No update run has completed since container start"
        exit 1
    fi
    exit 0
fi
read -r last_run last_rc < /tmp/cus-status
if [ "$last_rc" != "0" ] ; then
    echo "Last update run failed (exit ${last_rc})"
    exit 1
fi
if [ "$((now - last_run))" -gt "$((CUS_UPDATE_HOURS * 3600 * 2 + 600))" ] ; then
    echo "Update loop is stalled ($(((now - last_run) / 3600))h since last run)"
    exit 1
fi
exit 0
