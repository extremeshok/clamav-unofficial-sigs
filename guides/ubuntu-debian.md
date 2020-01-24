# Basic guide to Installing and Updating on Ubuntu / Debian
Run the following as root

# UPGRADE INSTRUCTIONS (version 7.0 +)
```
clamav-unofficial-sigs.sh --upgrade
clamav-unofficial-sigs.sh --force
```

# UPGRADE INSTRUCTIONS (version 6.1 and below)
```
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -O /usr/local/sbin/clamav-unofficial-sigs.sh && chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -O /etc/clamav-unofficial-sigs/master.conf
clamav-unofficial-sigs.sh --force
```

# CLAMAV INSTALL INSTRUCTIONS
# Install clamav
```
apt-get update && apt-get install -y clamav-base clamav-freshclam clamav clamav-daemon
```

## Make sure you do not have the package installed via apt
```
apt-get purge -y clamav-unofficial-sigs
```

## Install
Run the following commands in shell (console/terminal)
```
mkdir -p /usr/local/sbin/
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -O /usr/local/sbin/clamav-unofficial-sigs.sh && chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
mkdir -p /etc/clamav-unofficial-sigs/
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -O /etc/clamav-unofficial-sigs/master.conf
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf -O /etc/clamav-unofficial-sigs/user.conf
```
Select your operating system config from https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/config/
**replace os.debian9.conf with your required config, ubuntu = os.ubuntu.conf, debian10 = os.debian.conf, debian9 = os.debian.conf, debian8 = os.debian8.conf, debian8-systemd = os.debian8.systemd.conf, debian7 = os.debian7.conf**
```
os_conf="os.debian.conf"
wget "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/${os_conf}" -O /etc/clamav-unofficial-sigs/os.conf
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
mkdir -p /etc/systemd/system/
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/systemd/clamav-unofficial-sigs.service -O /etc/systemd/system/clamav-unofficial-sigs.service
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/systemd/clamav-unofficial-sigs.timer -O /etc/systemd/system/clamav-unofficial-sigs.timer

systemctl enable clamav-unofficial-sigs.service
systemctl enable clamav-unofficial-sigs.timer
systemctl start clamav-unofficial-sigs.timer

```
