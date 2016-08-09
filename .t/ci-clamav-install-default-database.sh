#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Downloading latest clamav databases"

wget -nv -t 9 http://database.clamav.net/bytecode.cvd
wget -nv -t 9 http://database.clamav.net/daily.cvd
wget -nv -t 9  http://database.clamav.net/main.cvd

mkdir -p /var/lib/clamav
cp -f bytecode.cvd /var/lib/clamav/bytecode.cvd
cp -f daily.cvd /var/lib/clamav/daily.cvd
cp -f bytecode.cvd /var/lib/clamav/main.cvd
chown -R clamav:clamav /var/lib/clamav
service clamav-daemon start
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi