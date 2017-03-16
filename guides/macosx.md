#### Basic guide to Installing on Mac OS 10.12+ and OS X

## Install Requirements
# Step 1 Install Homebrew
Press Command+Space and type Terminal and press enter/return key.
Run in Terminal app:
```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" < /dev/null 2> /dev/null
```

# Step 2
```
brew install clamav
```

# Step 3
```
sudo su
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh --output /usr/local/bin/clamav-unofficial-sigs.sh
chmod 777  /usr/local/bin/clamav-unofficial-sigs.sh
mkdir -p /etc/clamav-unofficial-sigs
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/master.conf --output /etc/clamav-unofficial-sigs/master.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/os.macosx.conf --output /etc/clamav-unofficial-sigs/os.conf
curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/config/user.conf --output /etc/clamav-unofficial-sigs/user.conf
exit
```

# Step 4
set your user options
```
sudo su
vi /etc/clamav-unofficial-sigs/user.conf
exit
```

# Stpe 5
Console (shell)
```
clamav-unofficial-sigs.sh
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
		<string>/usr/local/bin/clamav-unofficial-sigs.sh</string>
	</array>
	<key>StartInterval</key>
	<integer>3600</integer>
</dict>
</plist>
EOF
exit
chmod 777 /etc/rc.clamav-unofficial-sigs.sh
echo -e "*/5 * * * * root /etc/rc.clamav-unofficial-sigs.sh\n\n" >> /etc/crontab
```
