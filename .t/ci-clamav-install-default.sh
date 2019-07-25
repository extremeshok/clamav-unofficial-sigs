#!/bin/sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Installing default Clamav"

apt-get install -y clamav-base clamav-freshclam clamav clamav-daemon -qq
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
