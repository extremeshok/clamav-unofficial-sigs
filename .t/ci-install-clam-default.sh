#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Installing clamav 0.99 from Debian wheezy"

sudo wget -nv http://ftp.debian.org/debian/pool/main/l/llvm-3.0/libllvm3.0_3.0-10_amd64.deb
sudo wget -nv http://ftp.debian.org/debian/pool/main/libf/libffi/libffi5_3.0.10-3_amd64.deb
sudo wget -nv http://ftp.debian.org/debian/pool/main/c/clamav/libclamav7_0.99+dfsg-0+deb7u2_amd64.deb
sudo wget -nv http://ftp.debian.org/debian/pool/main/c/clamav/clamav-base_0.99+dfsg-0+deb7u2_all.deb
sudo wget -nv http://ftp.debian.org/debian/pool/main/c/clamav/clamav-freshclam_0.99+dfsg-0+deb7u2_amd64.deb
sudo wget -nv http://ftp.debian.org/debian/pool/main/c/clamav/clamav-daemon_0.99+dfsg-0+deb7u2_amd64.deb
sudo wget -nv http://ftp.debian.org/debian/pool/main/c/clamav/clamav_0.99+dfsg-0+deb7u2_amd64.deb
sudo dpkg -i *.deb
sudo apt-get install -y -f
sudo mkdir -p /var/lib/clamav
sudo cp -f .t/tests/bytecode.cvd /var/lib/clamav/bytecode.cvd
sudo chown -R clamav:clamav /var/lib/clamav
sudo service clamav-daemon start

if [ "$?" -eq "0" ] ; then
	echo .. OK
else
 	echo .. ERROR
  exit 1
fi




