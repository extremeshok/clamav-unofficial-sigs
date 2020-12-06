#!/bin/sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Installing latest clamav databases"

mkdir -p /var/lib/clamav
cp -f bytecode.cvd /usr/local/var/clamav/db/bytecode.cvd
cp -f daily.cvd /usr/local/var/clamav/db/daily.cvd
cp -f main.cvd /usr/local/var/clamav/db/main.cvd
chown -R clamav:clamav /usr/local/var/clamav/db/

launchctl kickstart -k system/clamav.clamd
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
