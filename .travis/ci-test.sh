#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

if bash clamav-unofficial-sigs.sh ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi