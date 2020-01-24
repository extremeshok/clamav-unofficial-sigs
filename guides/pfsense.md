# Basic guide to Installing and Updating on pfSense 2.3+

# UPGRADE INSTRUCTIONS (version 7.0 +)
```
clamav-unofficial-sigs.sh --upgrade
clamav-unofficial-sigs.sh --force
```

# UPGRADE INSTRUCTIONS (version 6.1 and below)
```
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -O /usr/sbin/clamav-unofficial-sigs.sh && chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -O /etc/clamav-unofficial-sigs/master.conf
clamav-unofficial-sigs.sh --force
```

## Install Requirements
# Step 1
Webinterface -> System -> Package Manager -> Available Packages
Select/Install: squid (pfSense-pkg-squid)

# Step 2
Webinterface -> Services -> Squid proxy Server -> Antivirus
Enable AV: enable
ClamAV Database Update: every1 hour
Regional ClamAV Database Update Mirror: closest to your server
[SAVE]

# Step 3
Webinterface -> Services -> Squid proxy Server -> Antivirus
ClamAV Database Update [ Update AV ]

# Step4
Console (shell)
```
pkg install bash
pkg install rsync
echo "fdesc	/dev/fd		fdescfs		rw	0	0" >> /etc/fstab
ln -s /usr/local/bin/bash /bin/bash
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh --output /usr/sbin/clamav-unofficial-sigs.sh
chmod 755 /usr/sbin/clamav-unofficial-sigs.sh
mkdir -p /etc/clamav-unofficial-sigs
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf --output /etc/clamav-unofficial-sigs/master.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/os.pfsense.conf --output /etc/clamav-unofficial-sigs/os.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf --output /etc/clamav-unofficial-sigs/user.conf
````

# Step 5
set your user options
Console (shell)
```
vi /etc/clamav-unofficial-sigs/user.conf
```

# Step 6
Console (shell)
```
reboot
```

# Step 6
Console (shell)
```
clamav-unofficial-sigs.sh
```

# Step 7
Cron helper Script
```
cat <<EOF > /etc/rc.clamav-unofficial-sigs.sh
#!/bin/sh
SHELL=/bin/sh
PATH=/usr/local/bin:$PATH
/bin/bash /usr/sbin/clamav-unofficial-sigs.sh
EOF
chmod 755 /etc/rc.clamav-unofficial-sigs.sh
echo -e "*/5 * * * * root /etc/rc.clamav-unofficial-sigs.sh\n\n" >> /etc/crontab
```
