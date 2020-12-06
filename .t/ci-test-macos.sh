#!/bin/sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "running script verbose default curl"
bash /usr/local/bin/clamav-unofficial-sigs.sh --verbose
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

echo "check signature placed correctly"
if [ -e "/usr/local/var/clamav/db/sanesecurity.ftm" ] ; then
	echo .. OK
else
	echo .. ERROR
	exit 1
fi
#
# echo "check database integrity test"
# bash clamav-unofficial-sigs.sh --test-database sanesecurity.ftm
# if [ "$?" -eq "0" ] ; then
# 	echo .. OK
# else
# 	echo .. ERROR
# 	exit 1
# fi
#
# echo "check gpg verify test"
# bash clamav-unofficial-sigs.sh --gpg-verify scam.ndb
# if [ "$?" -eq "0" ] ; then
# 	echo .. OK
# else
# 	echo .. ERROR
# 	exit 1
# fi

# echo "check clamav-daemon service will start"
# service clamav-daemon stop
# service clamav-daemon start
# if [ "$?" -eq "0" ] ; then
# 	echo .. OK
# else
#  	echo .. ERROR
#     exit 1
# f

echo "===== HIGH /var/lib/clamav/ ====="
ls -laFh /var/lib/clamav/
echo "================"

echo "running script verbose with LOW ratings"
cp -f .t/tests/user_low.conf /usr/local/etc/clamav-unofficial-sigs/user.conf
bash /usr/local/bin/clamav-unofficial-sigs.sh --verbose
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
    exit 1
fi
echo "===== LOW /var/lib/clamav/ ====="
ls -laFh /var/lib/clamav/
echo "================"

echo "Was /var/lib/clamav-unofficial-sigs/dbs-ss/jurlbl.ndb removed ?"
if [ ! -e "/var/lib/clamav-unofficial-sigs/dbs-ss/jurlbl.ndb" ] ; then
    echo .. OK
else
    echo .. ERROR
    exit 1
fi
echo "Was /var/lib/clamav/phish.ndb removed ?"
if [ ! -e "/var/lib/clamav/phish.ndb" ] ; then
    echo .. OK
else
    echo .. ERROR
    exit 1
fi
