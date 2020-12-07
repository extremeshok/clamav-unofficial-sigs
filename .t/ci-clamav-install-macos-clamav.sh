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
dscl . create /Groups/clamav
dscl . create /Groups/clamav RealName "Clam Antivirus Group"
dscl . create /Groups/clamav gid 799
dscl . create /Users/clamav
dscl . create /Users/clamav RealName "Clam Antivirus User"
dscl . create /Users/clamav UserShell /bin/false
dscl . create /Users/clamav UniqueID 599
dscl . create /Users/clamav PrimaryGroupID 799

# Create the dirs
mkdir -p /usr/local/var/clamav/run
mkdir -p /usr/local/var/clamav/log
mkdir -p /usr/local/var/clamav/db
mkdir -p /Library/LaunchDaemons

ls -laFh /usr/local/etc/clamav/

# Generate the configs
if [ ! -f "/usr/local/etc/clamav/clamd.conf.sample" ] ; then
    echo "Missing: /usr/local/etc/clamav/clamd.conf"
    exit 1
fi
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

# Fix permissions
chown -R clamav:clamav /usr/local/var/clamav

# Clamd socket
touch /usr/local/var/clamav/run/clamd.socket
chown clamav:clamav /usr/local/var/clamav/run/clamd.socket

tee "/Library/LaunchDaemons/clamav.clamd.plist" << EOF > /dev/null
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


chown root:wheel "/Library/LaunchDaemons/clamav.clamd.plist"
chmod 0644 "/Library/LaunchDaemons/clamav.clamd.plist"
