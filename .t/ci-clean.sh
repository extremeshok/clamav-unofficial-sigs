#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Cleaning CI enviroment"

sudo apt-get purge libclamav6 clamav-base clamav-freshclam clamav clamav-daemon -qq
sudo rm -rf /var/lib/clamav
sudo rm -rf /var/lib/clamav-unofficial-sigs
sudo rm -f /etc/cron.d/clamav-unofficial-sigs
sudo rm -f /etc/logrotate.d/clamav-unofficial-sigs
sudo rm -f /usr/share/man/man8/clamav-unofficial-sigs.8

echo .. OK



