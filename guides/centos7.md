# Basic guide to Installing and Updating on CentOS 7
Run the following as root

# UPGRADE INSTRUCTIONS (version 7.0 +)
```
/usr/local/sbin/clamav-unofficial-sigs.sh --upgrade
/usr/local/sbin/clamav-unofficial-sigs.sh --force
```

# UPGRADE INSTRUCTIONS (version 6.1 and below)
```
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -O /usr/local/sbin/clamav-unofficial-sigs.sh && chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -O /etc/clamav-unofficial-sigs/master.conf
/usr/local/sbin/clamav-unofficial-sigs.sh --force
```

# CLAMAV INSTALL INSTRUCTIONS

## Install Install epel
```
yum -y update
yum -y install epel-release
yum -y update
```

## Install clamav
```
yum -y install clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd
```

## Configure SELinux to allow clamav
```
setsebool -P antivirus_can_scan_system 1
setsebool -P clamd_use_jit 1
```

## Configure clamav
```
sed -i '/^Example$/d' /etc/clamd.d/scan.conf
sed -i -e 's|#LocalSocket /var/run/clamd.scan/clamd.sock|LocalSocket /var/run/clamd.scan/clamd.sock/g' /etc/clamd.d/scan.conf


cat << EOF > /etc/tmpfiles.d/clamav.conf
/var/run/clamd.scan 0755 clam clam
EOF

mv /usr/lib/systemd/system/clamd\@scan.service /usr/lib/systemd/system/clamd\@scan.old
cat << EOF > /usr/lib/systemd/system/clamd\@scan.service
# Run the clamd scanner
[Unit]
Description = clamd scanner (%i) daemon
After = syslog.target nss-lookup.target network.target

[Service]
Type = simple
ExecStart = /usr/sbin/clamd --foreground=yes
Restart = on-failure
IOSchedulingPriority = 7
CPUSchedulingPolicy = 5
Nice = 19
PrivateTmp = true
MemoryLimit=500M
CPUQuota=50%

[Install]
WantedBy = multi-user.target
EOF

systemctl daemon-reload

```

## Configure Freshclam
```
sed -i '/^Example$/d' /etc/freshclam.conf
sed -i '/REMOVE ME/d' /etc/sysconfig/freshclam

cat << EOF > /usr/lib/systemd/system/clam-freshclam.service
# Run the freshclam as daemon
[Unit]
Description = freshclam scanner
After = network.target

[Service]
Type = forking
ExecStart = /usr/bin/freshclam -d
Restart = on-failure
IOSchedulingPriority = 7
CPUSchedulingPolicy = 5
Nice = 19
PrivateTmp = true

[Install]
WantedBy = multi-user.target
EOF
systemctl daemon-reload

freshclam
systemctl enable clam-freshclam.service
systemctl start clam-freshclam.service

```

## Configure clamav
```
systemctl enable clamd@scan
systemctl start clamd@scan
systemctl status clamd@scan
```

## Install Dependencies
```
yum -y install bind-utils rsync
```
# INSTALLATION INSTRUCTIONS

## Make sure you do not have the package installed via yum
```
yum erase -y clamav-unofficial-sigs
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
**replace os.centos.conf with your required config, centos6 = os.centos6.conf, centos7-atomic = os.centos7-atomic.conf, centos6-cpanel = os.centos6-cpanel.conf**
```
os_conf="os.centos.conf"
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
