# Basic guide to Installing and Updating on Mac OS 10.12+ and OS X
Press Command+Space and type Terminal and press enter/return key.
Run all the following in the Terminal app:

# UPGRADE INSTRUCTIONS (version 7.0 +)
```
clamav-unofficial-sigs.sh --upgrade
clamav-unofficial-sigs.sh --force
```

# UPGRADE INSTRUCTIONS (version 6.1 and below)
```
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh -O /usr/local/bin/clamav-unofficial-sigs.sh && chmod 755 /usr/local/sbin/clamav-unofficial-sigs.sh
wget https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf -O /etc/clamav-unofficial-sigs/master.conf
clamav-unofficial-sigs.sh --force
```


## Notes:
https://www.clamav.net/documents/installation-on-macos-mac-os-x

## Install Requirements
# Step 1 Install Homebrew
```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

# Step 2 Install clamav
```
brew install clamav
```

# Step 3
```
sudo su
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh --output /usr/local/bin/clamav-unofficial-sigs.sh
chmod 755  /usr/local/bin/clamav-unofficial-sigs.sh
mkdir -p /etc/clamav-unofficial-sigs
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf --output /etc/clamav-unofficial-sigs/master.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os/os.macosx.conf --output /etc/clamav-unofficial-sigs/os.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf --output /etc/clamav-unofficial-sigs/user.conf
exit
```

# Step 4
set your user options
```
sudo pico /etc/clamav-unofficial-sigs/user.conf
```

# Step 5
Console (shell)
```
clamav-unofficial-sigs.sh --force
```

# Step 6
launchd helper Script (replaces cron)
```
sudo su
cat <<EOF > /Library/LaunchDaemons/com.clamav-unofficial-sigs.plist
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
exit
```
