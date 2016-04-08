#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

if bash clamav-unofficial-sigs.sh ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

if bash clamav-unofficial-sigs.sh --install-cron ; then
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

if bash clamav-unofficial-sigs.sh --install-logrotate  ; then
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