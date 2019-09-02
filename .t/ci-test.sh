#!/bin/sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Remove test signature if it exists. "
if [ -e "/var/lib/clamav/sanesecurity.ftm" ] ; then
	rm -f /var/lib/clamav/sanesecurity.ftm
fi

echo "running script as root and verbose and force_wget"
sudo cp -f .t/tests/user_wget.conf /etc/clamav-unofficial-sigs/user.conf
sudo bash /usr/sbin/clamav-unofficial-sigs --verbose
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

echo "running script as root and verbose"
sudo cp -f .t/tests/user.conf /etc/clamav-unofficial-sigs/user.conf
sudo bash /usr/sbin/clamav-unofficial-sigs --verbose
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

echo "running script as clamav and silence"
sudo -u clamav  [ -x /usr/sbin/clamav-unofficial-sigs ] && bash /usr/sbin/clamav-unofficial-sigs --force --silence
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

echo "check signature placed correctly"
if [ -e "/var/lib/clamav/sanesecurity.ftm" ] ; then
	echo .. OK
else
	echo .. ERROR
	exit 1
fi

echo "check cron file generation"
bash clamav-unofficial-sigs.sh --install-cron
if [ "$?" -eq "0" ] ; then
	if [ -e "/etc/cron.d/clamav-unofficial-sigs" ] ; then
		echo .. OK
	else
		echo .. ERROR
  	exit 1
	fi
else
 	echo .. ERROR
  exit 1
fi

echo "check logrotate file generation"
bash clamav-unofficial-sigs.sh --install-logrotate
if [ "$?" -eq "0" ] ; then
	if [ -e "/etc/logrotate.d/clamav-unofficial-sigs" ] ; then
		echo .. OK
	else
		echo .. ERROR
  	exit 1
	fi
else
 	echo .. ERROR
  exit 1
fi

echo "check man file generation"
bash clamav-unofficial-sigs.sh --install-man
if [ "$?" -eq "0" ] ; then
	if [ -e "/usr/share/man/man8/clamav-unofficial-sigs.8" ] ; then
		echo .. OK
	else
		echo .. ERROR
  	exit 1
	fi
else
 	echo .. ERROR
  exit 1
fi

echo "check database integrity test"
bash clamav-unofficial-sigs.sh --test-database sanesecurity.ftm
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
	echo .. ERROR
	exit 1
fi

echo "check gpg verify test"
bash clamav-unofficial-sigs.sh --gpg-verify scam.ndb
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
	echo .. ERROR
	exit 1
fi

echo "check clamav-daemon service will start"
service clamav-daemon stop
service clamav-daemon start
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
