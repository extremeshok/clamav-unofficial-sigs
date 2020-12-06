# clamav-unofficial-sigs.sh install

## GENERAL INFORMATION

This is property of eXtremeSHOK.com
You are free to use, modify and distribute, however you may not remove this notice.
Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
License: BSD (Berkeley Software Distribution)

Script updates can be found at: <https://github.com/extremeshok/clamav-unofficial-sigs>

## Operating System Specific Install Guides

* CentOS : <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/centos7.md>
* Ubuntu : <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/ubuntu-debian.md>
* Debian : <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/ubuntu-debian.md>
* Mac OSX : <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/macosx.md>
* pFsense : <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/pfsense.md>

## GENERIC UPGRADE INSTRUCTIONS (version 7.0 +)

```bash
clamav-unofficial-sigs.sh --upgrade
clamav-unofficial-sigs.sh --force
```

## GENERIC UPGRADE INSTRUCTIONS (version 6.1 and below)

```bash
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -O /usr/local/sbin/clamav-unofficial-sigs.sh && chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -O /etc/clamav-unofficial-sigs/master.conf
clamav-unofficial-sigs.sh --force
```

## GENERIC INSTALLATION INSTRUCTIONS

### Install

Run the following commands in shell (console/terminal)

```bash
mkdir -p /usr/local/sbin/
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -O /usr/local/sbin/clamav-unofficial-sigs.sh && chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
mkdir -p /etc/clamav-unofficial-sigs/
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -O /etc/clamav-unofficial-sigs/master.conf
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf -O /etc/clamav-unofficial-sigs/user.conf
```

Select your operating system config from <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/config/>
**replace os.ubuntu.conf with your required config, centos7/8 = os.centos.conf , debian9/10 = os.debian.conf**

```bash
os_conf="os.ubuntu.conf"
wget "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/${os_conf}" -O /etc/clamav-unofficial-sigs/os.conf
```

#### Optional: configure your user config /etc/clamav-unofficial-sigs/user.conf

### RUN THE SCRIPT ONCE AS ROOT

ensure there are no errors, fix any missing dependencies
script must run once as your superuser to set all the permissions and create the relevant directories

```bash
/usr/local/sbin/clamav-unofficial-sigs.sh --force
```

#### Install logrotate and man files

```bash
/usr/local/sbin/clamav-unofficial-sigs.sh --install-logrotate
/usr/local/sbin/clamav-unofficial-sigs.sh --install-man
```

#### Install Systemd configs or use cron

##### cron

```bash
/usr/local/sbin/clamav-unofficial-sigs.sh --install-cron
```

##### OR

##### Systemd

```bash
mkdir -p /etc/systemd/system/
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/systemd/clamav-unofficial-sigs.service -O /etc/systemd/system/clamav-unofficial-sigs.service
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/systemd/clamav-unofficial-sigs.timer -O /etc/systemd/system/clamav-unofficial-sigs.timer

systemctl enable clamav-unofficial-sigs.service
systemctl enable clamav-unofficial-sigs.timer
systemctl start clamav-unofficial-sigs.timer
```

## Script updates can be found at: <https://github.com/extremeshok/clamav-unofficial-sigs>
