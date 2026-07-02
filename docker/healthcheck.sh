#!/usr/bin/env bash
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
# Container healthcheck for clamav-unofficial-sigs
# - all-in-one mode: clamd must answer PING (official clamdcheck.sh)
# - all modes: the newest signature update must be fresher than
#   2 x CUS_UPDATE_HOURS (+10 minute grace)
##################

CUS_MODE="${CUS_MODE:-all-in-one}"
CUS_UPDATE_HOURS="${CUS_UPDATE_HOURS:-2}"
WORK_CONFIGS="/var/lib/clamav-unofficial-sigs/configs"

if [ "$CUS_MODE" == "all-in-one" ] ; then
    if [ -x /usr/local/bin/clamdcheck.sh ] ; then
        /usr/local/bin/clamdcheck.sh || exit 1
    fi
fi

# shellcheck disable=SC2012
newest="$(stat -c '%Y' "${WORK_CONFIGS}"/last-*-update.txt 2>/dev/null | sort -rn | head -n 1)"
if [ -z "$newest" ] ; then
    # No update has completed yet, covered by the healthcheck start-period
    exit 0
fi
now="$(date +%s)"
max_age="$((CUS_UPDATE_HOURS * 3600 * 2 + 600))"
if [ "$((now - newest))" -gt "$max_age" ] ; then
    echo "Signature updates are stale ($(((now - newest) / 3600))h old)"
    exit 1
fi
exit 0
