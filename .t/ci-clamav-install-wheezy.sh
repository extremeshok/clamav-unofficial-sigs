#!/bin/sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Installing clamav 0.99 from Debian wheezy"

wget -nv -t 9 http://ftp.debian.org/debian/pool/main/l/llvm-3.0/libllvm3.0_3.0-10_amd64.deb
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
wget -nv -t 9  http://ftp.debian.org/debian/pool/main/libf/libffi/libffi5_3.0.10-3_amd64.deb
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
wget -nv -t 9  http://ftp.debian.org/debian/pool/main/c/clamav/libclamav7_0.99+dfsg-0+deb7u2_amd64.deb
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
wget -nv -t 9  http://ftp.debian.org/debian/pool/main/c/clamav/clamav-base_0.99+dfsg-0+deb7u2_all.deb
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
wget -nv -t 9  http://ftp.debian.org/debian/pool/main/c/clamav/clamav-freshclam_0.99+dfsg-0+deb7u2_amd64.deb
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
wget -nv -t 9  http://ftp.debian.org/debian/pool/main/c/clamav/clamav-daemon_0.99+dfsg-0+deb7u2_amd64.deb
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
wget -nv -t 9  http://ftp.debian.org/debian/pool/main/c/clamav/clamav_0.99+dfsg-0+deb7u2_amd64.deb
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
dpkg -i *.deb
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
apt-get install -y -f
if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi
