#### Basic guide to Installing on CentOS 7

## Install Requirements
# Step 1 Install epel
```
yum -y update
yum -y install epel-release
yum -y update
yum clean all
```

# Step 2 Install clamav
```
yum -y install clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd
```

# Step 3 Configure SELinux to allow clamav
```
setsebool -P antivirus_can_scan_system 1
setsebool -P clamd_use_jit 1
```

# Step 4 Configure clamav
```
sed -i '/^Example$/d' /etc/freshclam.conf
sed -i '/^Example$/d' /etc/clamd.d/scan.conf
sed -i -e 's/#LocalSocket \/var\/run\/clamd.scan\/clamd.sock/LocalSocket \/var\/run\/clamd.scan\/clamd.sock/g' /etc/clamd.d/scan.conf
sed -i '/REMOVE ME/d' /etc/sysconfig/freshclam
systemctl enable clamd@scan
freshclam
systemctl start clamd@scan
systemctl status clamd@scan
```

# Step 5 Install Dependencies
```
yum -y install bind-utils rsync
```
# Step 6
```
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh --output /usr/local/bin/clamav-unofficial-sigs.sh
chmod 777 /usr/local/bin/clamav-unofficial-sigs.sh
mkdir -p /etc/clamav-unofficial-sigs
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf --output /etc/clamav-unofficial-sigs/master.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os.centos7.conf --output /etc/clamav-unofficial-sigs/os.centos7.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf --output /etc/clamav-unofficial-sigs/user.conf
```

# Step 7
set your user options
```
vim /etc/clamav-unofficial-sigs/user.conf
```

# Step 9
run once to make sure there are no errors
```
bash clamav-unofficial-sigs.sh
```

# Step 10
```
bash clamav-unofficial-sigs.sh --install-all
```
