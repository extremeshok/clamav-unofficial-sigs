#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Installing default Clamav"

sudo apt-get install clamav-daemon -qq
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



