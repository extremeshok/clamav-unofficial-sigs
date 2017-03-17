#!/bin/sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Downloading latest clamav databases"

wget -nv -t 9 https://github.com/extremeshok/clamav-sample-db/raw/master/bytecode.cvd.7z
7za e bytecode.cvd.7z
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

wget -nv -t 9 https://github.com/extremeshok/clamav-sample-db/raw/master/daily.cvd.7z.003
wget -nv -t 9 https://github.com/extremeshok/clamav-sample-db/raw/master/daily.cvd.7z.002
wget -nv -t 9 https://github.com/extremeshok/clamav-sample-db/raw/master/daily.cvd.7z.001
7za e daily.cvd.7z.001
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

wget -nv -t 9  https://github.com/extremeshok/clamav-sample-db/raw/master/main.cvd.7z.006
wget -nv -t 9  https://github.com/extremeshok/clamav-sample-db/raw/master/main.cvd.7z.005
wget -nv -t 9  https://github.com/extremeshok/clamav-sample-db/raw/master/main.cvd.7z.004
wget -nv -t 9  https://github.com/extremeshok/clamav-sample-db/raw/master/main.cvd.7z.003
wget -nv -t 9  https://github.com/extremeshok/clamav-sample-db/raw/master/main.cvd.7z.002
wget -nv -t 9  https://github.com/extremeshok/clamav-sample-db/raw/master/main.cvd.7z.001
7za e main.cvd.7z.001
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
