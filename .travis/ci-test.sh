#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "running script as root"
bash clamav-unofficial-sigs.sh
if [ "$?" == "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

echo "running script as clamav"
sudo -u clamav  [ -x /usr/sbin/clamav-unofficial-sigs ] && bash /usr/sbin/clamav-unofficial-sigs --force
if [ "$?" == "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

echo "check gpg file was downloaded"
if [ -e "/var/lib/clamav-unofficial-sigs/gpg-key/publickey.gpg" ] ; then
	echo .. OK	
else
	echo .. ERROR
  exit 1
fi

echo "check cron file generation"
bash clamav-unofficial-sigs.sh --install-cron
if [ "$?" == "0" ] ; then
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
if [ "$?" == "0" ] ; then
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
if [ "$?" == "0" ] ; then
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
