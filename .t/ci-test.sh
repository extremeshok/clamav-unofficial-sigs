#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Remove test signature if it exists. "
if [ -e "/var/lib/clamav/sanesecurity.ftm" ] ; then
	rm -f /var/lib/clamav/sanesecurity.ftm
fi

echo "running script as root"
sudo bash /usr/sbin/clamav-unofficial-sigs
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

echo "running script as clamav"
sudo -u clamav  [ -x /usr/sbin/clamav-unofficial-sigs ] && bash /usr/sbin/clamav-unofficial-sigs --force
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
