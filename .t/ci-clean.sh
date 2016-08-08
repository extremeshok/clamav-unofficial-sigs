#!/bin/sh

export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Cleaning CI enviroment"

sudo rm -f /etc/cron.d/clamav-unofficial-sigs
sudo rm -f /etc/logrotate.d/clamav-unofficial-sigs
sudo rm -f /usr/share/man/man8/clamav-unofficial-sigs.8
sudo rm -rf /var/lib/clamav-unofficial-sigs

sudo service clamav-daemon stop
sudo apt-get purge libclamav6 clamav-base clamav-freshclam clamav clamav-daemon -qq
sudo rm -rf /var/lib/clamav

echo .. OK

#force the exit to 0
exit 0
