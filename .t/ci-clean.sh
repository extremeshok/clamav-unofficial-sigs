#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Cleanign CI enviroment"

sudo apt-get purge clamav* -qq
sudo rm -rf /var/lib/clamav
sudo rm -rf /var/lib/clamav-unofficial-sigs
sudo rm -f /etc/cron.d/clamav-unofficial-sigs
sudo rm -f /etc/logrotate.d/clamav-unofficial-sigs
sudo rm -f /usr/share/man/man8/clamav-unofficial-sigs.8

echo .. OK



