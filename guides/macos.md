# Basic guide to Installing and Updating on Mac OS 10.12+ and OS X
Press Command+Space and type Terminal and press enter/return key.
Run all the following in the Terminal app:

# UPGRADE INSTRUCTIONS (version 7.0 +)
```
clamav-unofficial-sigs.sh --upgrade
clamav-unofficial-sigs.sh --force
```

## Notes:
Tested on macOS Big Sur (OSX 11)

## Install Requirements
# Step 1 Install Homebrew
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```


# Step 2 Install dependencies : gtar (gnu-tar) sed (gnu-sed)
```
brew install gnu-tar gnu-tar
```

# Step 3 Install clamav
```
brew install clamav
```

# Step 4 Configure clamav
```
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
sudo mkdir -p  "/Library/LaunchDaemons"

# Generate the configs
cp "/usr/local/etc/clamav/clamd.conf.sample" "/usr/local/etc/clamav/clamd.conf"
sed -e "s|# Example config file|# Config file|" \
       -e "s|^Example$|# Example|" \
       -e "s|^#MaxDirectoryRecursion 20$|MaxDirectoryRecursion 25|" \
       -e "s|^#LogFile .*|LogFile /usr/local/var/clamav/log/clamd.log|" \
       -e "s|^#PidFile .*|PidFile /usr/local/var/clamav/run/clamd.pid|" \
       -e "s|^#DatabaseDirectory .*|DatabaseDirectory /usr/local/var/clamav/db|" \
       -e "s|^#LocalSocket .*|LocalSocket /usr/local/var/clamav/run/clamd.socket|" \
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

sudo tee "/Library/LaunchDaemons/clamav.freshclam.plist" << EOF > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${FRESHCLAM_DAEMON_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/freshclam</string>
        <string>--daemon</string>
        <string>--foreground</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/usr/local/var/clamav/log/freshclam.error.log</string>
    <key>StartInterval</key>
    <integer>86400</integer>
</dict>
</plist>
EOF

sudo tee "/Library/LaunchDaemons/clamav.clamdscan.plist" << EOF > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${CLAMDSCAN_DAEMON_NAME}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/clamdscan</string>
        <string>--log=/usr/local/var/clamav/log/clamdscan.log</string>
        <string>-m</string>
        <string>/</string>
    </array>
    <key>KeepAlive</key>
    <false/>
    <key>RunAtLoad</key>
    <false/>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>1</integer>
        <key>Minute</key>
        <integer>45</integer>
    </dict>
    <key>StandardErrorPath</key>
    <string>/usr/local/var/clamav/log/clamdscan.error.log</string>
</dict>
</plist>
EOF

sudo chown root:wheel "/Library/LaunchDaemons/clamav.clamd.plist" "/Library/LaunchDaemons/clamav.freshclam.plist" "/Library/LaunchDaemons/clamav.clamdscan.plist"
sudo chmod 0644 "/Library/LaunchDaemons/clamav.clamd.plist" "/Library/LaunchDaemons/clamav.freshclam.plist" "/Library/LaunchDaemons/clamav.clamdscan.plist"
sudo launchctl load "/Library/LaunchDaemons/clamav.clamd.plist" "/Library/LaunchDaemons/clamav.freshclam.plist" "/Library/LaunchDaemons/clamav.clamdscan.plist"

```

# Step 5
```
sudo su
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh --output /usr/local/bin/clamav-unofficial-sigs.sh
chmod 755  /usr/local/bin/clamav-unofficial-sigs.sh
mkdir -p /usr/local/etc/clamav-unofficial-sigs
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf --output /usr/local/etc/clamav-unofficial-sigs/master.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/os.macosx.conf --output /usr/local/etc/clamav-unofficial-sigs/os.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf --output /usr/local/etc/clamav-unofficial-sigs/user.conf
exit
```

# Step 6
set your user options
```
sudo pico /usr/local/etc/clamav-unofficial-sigs/user.conf
```

# Step 7
Console (shell)
```
clamav-unofficial-sigs.sh --force
```

# Step 8
launchd helper Script (replaces cron)
```
sudo tee "/Library/LaunchDaemons/clamav.clamav-unofficial-sigs.plist" << EOF > /dev/null
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>Clamav Unofficial Sigs update</string>
	<key>ProgramArguments</key>
	<array>
		<string>bash /usr/local/bin/clamav-unofficial-sigs.sh</string>
	</array>
	<key>StartInterval</key>
	<integer>3600</integer>
</dict>
</plist>
EOF
sudo chown root:wheel "/Library/LaunchDaemons/clamav.clamav-unofficial-sigs.plist"
sudo chmod 0644 "/Library/LaunchDaemons/clamav.clamav-unofficial-sigs.plist"
sudo launchctl load "/Library/LaunchDaemons/clamav.clamav-unofficial-sigs.plist"
```
