#!/bin/sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Cleaning CI enviroment"

rm -f /etc/cron.d/clamav-unofficial-sigs
rm -f /etc/logrotate.d/clamav-unofficial-sigs
rm -f /usr/share/man/man8/clamav-unofficial-sigs.8
rm -rf /var/lib/clamav-unofficial-sigs

service clamav-daemon stop
apt-get purge libclamav6 clamav-base clamav-freshclam clamav clamav-daemon -qq
rm -rf /var/lib/clamav

echo .. OK

#force the exit to 0
exit 0
