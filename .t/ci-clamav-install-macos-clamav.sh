#!/bin/sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

pwd

echo "Installing default Clamav"

# Create clamav user and group
sudo dscl . create /Groups/clamav
sudo dscl . create /Groups/clamav RealName "Clam Antivirus Group"
sudo dscl . create /Groups/clamav gid 799
sudo dscl . create /Users/clamav
sudo dscl . create /Users/clamav RealName "Clam Antivirus User"
sudo dscl . create /Users/clamav UserShell /bin/false
sudo dscl . create /Users/clamav UniqueID 599
sudo dscl . create /Users/clamav PrimaryGroupID 799

# Create the dirs
sudo mkdir -p /usr/local/var/clamav/run
sudo mkdir -p /usr/local/var/clamav/log
sudo mkdir -p /usr/local/var/clamav/db
sudo mkdir -p "/Library/LaunchDaemons"

# Generate the configs
cp "/usr/local/etc/clamav/clamd.conf.sample" "/usr/local/etc/clamav/clamd.conf"
sed -e "s|# Example config file|# Config file|" \
       -e "s|^Example$|# Example|" \
       -e "s|^#MaxDirectoryRecursion 20$|MaxDirectoryRecursion 25|" \
       -e "s|^#LogFile .*|LogFile /usr/local/var/clamav/log/clamd.log|" \
       -e "s|^#PidFile .*|PidFile /usr/local/var/clamav/run/clamd.pid|" \
       -e "s|^#DatabaseDirectory .*|DatabaseDirectory /usr/local/var/clamav/db|" \
       -e "s|^#LocalSocket .*|LocalSocket /usr/local/var/clamav/run/clamd.socket|" \
       -e "s|^#FixStaleSocket|FixStaleSocket|" \"
       -i -n "/usr/local/etc/clamav/clamd.conf"

cp "/usr/local/etc/clamav/freshclam.conf.sample" "/usr/local/etc/clamav/freshclam.conf"
sed -e "s|# Example config file|# Config file|" \
       -e "s|^Example$|# Example|" \
       -e "s|^#DatabaseDirectory .*|DatabaseDirectory /usr/local/var/clamav/db|" \
       -e "s|^#UpdateLogFile .*|UpdateLogFile /usr/local/var/clamav/log/freshclam.log|" \
       -e "s|^#PidFile .*|PidFile /usr/local/var/clamav/run/freshclam.pid|" \
       -e "s|^#NotifyClamd .*|NotifyClamd /usr/local/etc/clamav/clamd.conf|" \
       -i -n "/usr/local/etc/clamav/freshclam.conf"

# Fix permissions
sudo chown -R clamav:clamav /usr/local/var/clamav

# Clamd socket
sudo touch /usr/local/var/clamav/run/clamd.socket
sudo chown clamav:clamav /usr/local/var/clamav/run/clamd.socket

sudo tee "/Library/LaunchDaemons/clamav.clamd.plist" << EOF > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>clamav.clamd</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/sbin/clamd</string>
        <string>--foreground</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/usr/local/var/clamav/log/clamd.error.log</string>
</dict>
</plist>
EOF


sudo chown root:wheel "/Library/LaunchDaemons/clamav.clamd.plist"
sudo chmod 0644 "/Library/LaunchDaemons/clamav.clamd.plist"
sudo launchctl load "/Library/LaunchDaemons/clamav.clamd.plist"
