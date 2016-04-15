#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

if bash clamav-unofficial-sigs.sh ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

#check cron file generation
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

#check logrotate file generation
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

#check man file generation
if bash clamav-unofficial-sigs.sh --install-man  ; then
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