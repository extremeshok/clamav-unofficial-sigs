#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Downloading latest clamav databases"

wget -nv -t 9 http://database.clamav.net/bytecode.cvd --output-file=.t/databases/bytecode.cvd
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

wget -nv -t 9 http://database.clamav.net/daily.cvd --output-file=.t/databases/daily.cvd
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi

wget -nv -t 9  http://database.clamav.net/main.cvd --output-file=.t/databases/main.cvd
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
