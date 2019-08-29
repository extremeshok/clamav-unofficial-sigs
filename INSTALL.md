# GENERAL INFORMATION
This is property of eXtremeSHOK.com
You are free to use, modify and distribute, however you may not remove this notice.
Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
License: BSD (Berkeley Software Distribution)

Script updates can be found at: https://github.com/extremeshok/clamav-unofficial-sigs

# Operating System Specific Install Guides
* CentOS : https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/centos7.md
* Ubuntu : https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/ubuntu-debian.md
* Debian : https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/ubuntu-debian.md
* Mac OSX : https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/macosx.md
* pFsense : https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/pfsense.md

# GENERIC INSTALLATION INSTRUCTIONS

## Install
Run the following commands in shell (console/terminal)
```
mkdir -p /usr/local/sbin/
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -c -O /usr/local/sbin/clamav-unofficial-sigs.sh && chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
mkdir -p /etc/clamav-unofficial-sigs/
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -c -O /etc/clamav-unofficial-sigs/master.conf
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf -c -O /etc/clamav-unofficial-sigs/user.conf
```
Select your operating system config from https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/config/
**replace os.ubuntu.conf with your required config, centos7 = os.centos7.conf**
```
os_conf="os.ubuntu.conf"
wget "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/${os_conf}" -c -O /etc/clamav-unofficial-sigs/os.conf
```

### Optional: configure your user config /etc/clamav-unofficial-sigs/user.conf

## RUN THE SCRIPT ONCE AS ROOT
ensure there are no errors, fix any missing dependencies
script must run once as your superuser to set all the permissions and create the relevant directories
```
/usr/local/sbin/clamav-unofficial-sigs.sh --force
```

### Install logrotate and Man files
```
/usr/local/sbin/clamav-unofficial-sigs.sh --install-logrotate
/usr/local/sbin/clamav-unofficial-sigs.sh --install-man
```

### Install Systemd configs or use cron
#### cron
```
/usr/local/sbin/clamav-unofficial-sigs.sh --install-cron
```
### OR
#### systemd
```
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/systemd/clamav-unofficial-sigs.service -c -O /etc/systemd/system/clamav-unofficial-sigs.service
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/systemd/clamav-unofficial-sigs.timer -c -O /etc/systemd/system/clamav-unofficial-sigs.timer
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/systemd/clamd.scan.service -c -O /etc/systemd/system/clamd.scan.service
```

### Script updates can be found at: https://github.com/extremeshok/clamav-unofficial-sigs
