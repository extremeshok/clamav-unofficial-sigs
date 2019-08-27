# WORK IN PROGRESS

#### Basic guide to Installing on CentOS 7

## Install Requirements
# Step 1 Install epel
```
yum -y update
yum -y install epel-release
yum -y update
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

# Step 5 Configure Freshclam
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

# Step 6 Configure clamav
```
systemctl enable clamd@scan
systemctl start clamd@scan
systemctl status clamd@scan
```

# Step 7 Install Dependencies
```
yum -y install bind-utils rsync
```
# Step 8
```
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh --output /usr/local/bin/clamav-unofficial-sigs.sh
chmod 755 /usr/local/bin/clamav-unofficial-sigs.sh
mkdir -p /etc/clamav-unofficial-sigs
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf --output /etc/clamav-unofficial-sigs/master.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os.centos7.conf --output /etc/clamav-unofficial-sigs/os.centos7.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf --output /etc/clamav-unofficial-sigs/user.conf
```

# Step 9
set your user options
```
vim /etc/clamav-unofficial-sigs/user.conf
```

# Step 10
run once to make sure there are no errors
```
bash clamav-unofficial-sigs.sh
```

# Step 11
```
bash clamav-unofficial-sigs.sh --install-all
```
