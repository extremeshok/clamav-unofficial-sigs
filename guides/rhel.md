# Basic guide to Installing and Updating on RHEL / Rocky Linux / AlmaLinux 8, 9 and 10

Run the following as root

## CLAMAV INSTALL INSTRUCTIONS

### Install epel

```bash
dnf -y install epel-release || dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm
dnf -y update
```

### Install clamav

```bash
dnf -y install clamav clamd clamav-update
```

### Configure SELinux to allow clamav

```bash
setsebool -P antivirus_can_scan_system 1
```

### Configure clamd

```bash
sed -i '/^Example$/d' /etc/clamd.d/scan.conf
sed -i 's|^#LocalSocket /run/clamd.scan/clamd.sock|LocalSocket /run/clamd.scan/clamd.sock|' /etc/clamd.d/scan.conf
```

### Enable freshclam and clamd

```bash
systemctl enable --now clamav-freshclam.service
systemctl enable --now clamd@scan
```

## CLAMAV-UNOFFICIAL-SIGS INSTALL INSTRUCTIONS

### Install required packages

```bash
dnf -y install curl rsync bind-utils gnupg2 cronie
```

### Install the script

```bash
curl -o /usr/local/sbin/clamav-unofficial-sigs.sh https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh
chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
```

### Install the configs

```bash
mkdir -p /etc/clamav-unofficial-sigs
curl -o /etc/clamav-unofficial-sigs/master.conf https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf
curl -o /etc/clamav-unofficial-sigs/os.conf https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/os.rhel.conf
curl -o /etc/clamav-unofficial-sigs/user.conf https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf
```

### Edit the user.conf

Set your options (see master.conf for explanations), then activate the config by uncommenting

```text
user_configuration_complete="yes"
```

### Run the script as root to set permissions and create directories

```bash
/usr/local/sbin/clamav-unofficial-sigs.sh
```

### Install the cron, logrotate and man files

```bash
/usr/local/sbin/clamav-unofficial-sigs.sh --install-cron
/usr/local/sbin/clamav-unofficial-sigs.sh --install-logrotate
/usr/local/sbin/clamav-unofficial-sigs.sh --install-man
```

### Force the update

```bash
/usr/local/sbin/clamav-unofficial-sigs.sh --force
```

## UPGRADE INSTRUCTIONS (version 7.0 +)

```bash
/usr/local/sbin/clamav-unofficial-sigs.sh --upgrade
/usr/local/sbin/clamav-unofficial-sigs.sh --force
```

## NOTES

* The EPEL clamav packages use the `clamupdate` user and `/run/clamd.scan/clamd.sock` socket, which os.rhel.conf is configured for.
* By default `reload_dbs` is disabled because the clamupdate user has no permission to restart services; clamd reloads its databases automatically via its SelfCheck interval (default 600 seconds).
* On CentOS 7 (EOL) see guides/centos7.md.
