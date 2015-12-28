# clamav-unofficial-sigs
ClamAV Unofficial Signatures Updater

Github fork of the sourceforge hosted and non maintained utility.

## Maintained and provided by https://eXtremeSHOK.com

## Description
The clamav-unofficial-sigs script provides a simple way to download, test, and update third-party signature databases provided by Sanesecurity, FOXHOLE, OITC, Scamnailer, BOFHLAND, CRDF, Porcupine, Securiteinfo, MalwarePatrol. The package also contains cron, logrotate, and man files.

### In addition to the original master
This fork provides an installer script, which is tested on debian Jessie and Wheezy.
New Linux distributions are easy to integrate. ( which is a ToDo )

To use the installer script get it here :
wget https://raw.githubusercontent.com/thctlo/clamav-unofficial-sigs/master/clamav-unofficial-sigs-installer.sh
chmod +x clamav-unofficial-sigs-installer.sh
and run in : ./clamav-unofficial-sigs-installer.sh
It wil get the original clamav-unofficial-sigs set from extremeshok, this installer script, installs the files for you.
But more in a "Debian" preffered setup.

For Debian Jessie and Wheezy
* It imports old settings from previous installes and creates a backup of the previous version.
* It set the user/group/right for logrotate to clamav/adm/640 and log file to folder /var/log/clamav
* It set the conf file to /etc/clamav and corrects files where needed to the new path
* It puts the clamav-unofficial-sigs.sh in /usr/local/sbin

For other Linux Distros, not included yet, but should be easy to integrate.
Some parts are done but this is not finished yet.


#### Try our custom spamassasin plugin: https://github.com/extremeshok/spamassassin-extremeshok_fromreplyto

### Quick Install Guide
* Download the files to /tmp/
* move clamav-unofficial-sigs.sh to /usr/local/bin/
* set 755 permissions on  /usr/local/bin/clamav-unofficial-sigs.sh
* move clamav-unofficial-sigs.conf into /etc/ 
* move clamav-unofficial-sigs-cron into /etc/cron.d/
* move clamav-unofficial-sigs-logrotate into /etc/logrotate.d/
* move clamav-unofficial-sigs.8 into /usr/share/man/man8/
* set your config options in /etc/clamav-unofficial-sigs.conf

#### SELinux cron permission fix
> WARNING - Clamscan reports ________ database integrity tested BAD - SKIPPING

**Run the following command to allow clamav selinux support**

```setsebool -P antivirus_can_scan_system true```

### Yara Rule Support (as of June 2015)
Requires clamav 0.99 or above : http://yararules.com 

Current limitations of clamav support : http://blog.clamav.net/search/label/yara

### MalwarePatrol Free/Delayed list support (as of May 2015)
Usage of MalwarePatrol 2015 free clamav signatures : https://www.malwarepatrol.net
 - 1. Sign up for a free account : https://www.malwarepatrol.net/signup-free.shtml
 - 2. You will recieve an email containing your password/receipt number
 - 3. Enter the receipt number into the config malwarepatrol_receipt_code: replacing YOUR-RECEIPT-NUMBER with your receipt number from the email

### SecuriteInfo Free/Delayed list support (as of June 2015)
Usage of SecuriteInfo 2015 free clamav signatures : https://www.securiteinfo.com
 - 1. Sign up for a free account : https://www.securiteinfo.com/clients/customers/signup
 - 2. You will recieve an email to activate your account and then a followup email with your login name
 - 3. Login and navigate to your customer account : https://www.securiteinfo.com/clients/customers/account
 - 4. Click on the Setup tab
 - 5. You will need to get your unique identifier from one of the download links, they are individual for every user
 - 5.1. The 128 character string is after the http://www.securiteinfo.com/get/signatures/ 
 - 5.2. Example https://www.securiteinfo.com/get/signatures/your_unique_and_very_long_random_string_of_characters/securiteinfo.hdb
   Your 128 character authorisation signature would be : your_unique_and_very_long_random_string_of_characters
 - 6. Enter the authorisation signature into the config securiteinfo_authorisation_signature: replacing YOUR-SIGNATURE-NUMBER with your authorisation signature from the link

### Linux Malware Detect support (as of May 2015)
Usage of free Linux Malware Detect clamav signatures: https://www.rfxn.com/projects/linux-malware-detect/
 - Enabled by default, no configuration required

## Change Log
### Version 4.9.2 (updated 2015-12-02)
 - eXtremeSHOK.com Maintenance 
 - Added function xshok_check_s2 to prevent possible errors with -c and no configfile path
 - minor code refactoring

### Version 4.9.1
 - eXtremeSHOK.com Maintenance 
 - OS X compatibility fix by stewardle
 - missing $ in $yararules_enabled

### Version 4.9
 - eXtremeSHOK.com Maintenance 
 - Code Refactoring
 - New function clamscan_reload_dbs, will first try and reload the clam database, if reload fails will restart clamd
 - Added Function xshok_pretty_echo_and_log, far easier and cleaner way to output and log information
 - Removed functions comment, log
 - Removed config option reload_opt
 - Added config option clamd_restart_opt
 - Added support for # characters in config values, ie malwarepatrol subscription key contains a #
 - Minor formatting and code consitency changes
 - 10% Smaller script size
 - Config updated to 53 due to changes

### Version 4.8
 - eXtremeSHOK.com Maintenance 
 - Added long option (--force) to Force all databases to be downloaded, could cause ip to be blocked"
 - added config option:  malwarepatrol_free="yes", set to "no" to enable commercial subscription url
 - added support for commercial malwarepatrol subscription
 - Grammar fix in config
 - SELINUX cronjob fix added to readme
 - Corrects tput warning when used without TERM (like in cron)
 - Config updated to 52 due to changes

### Version 4.7
 - eXtremeSHOK.com Maintenance 
 - Code Refactoring
 - Complete rewrite of the main case selector (program options)
 - Added long options (--decode-sig, --encode-string, --encode-formatted, --gpg-verify, --information, --make-database, --remove-script, --test-database, --output-triggered)
 - Replaced clamd-status.sh with --check-clamav
 - Removed CHANGELOG, changelog has been replaced by this part of the readme and the git commit log.
 - Config updated to 51 due to changes

### Version 4.6.1
 - eXtremeSHOK.com Maintenance 
 - Code Refactoring
 - Added generic options (--help --version --config)
 - Correctly handle generic options before the main case selector
 - Sanitize the config before the main case selector (option)
 - Rewrite and formatting of the usage options
 - Removed the version information code as this is always printed

### Version 4.6
 - eXtremeSHOK.com Maintenance 
 - Code Refactoring
 - Removed custom config forced to use the same filename as the default config
 - Change file checks from exists to exists and is readable
 - Removed legacy config checks
 - Full support for custom config files for all tasks
 - Removed function: no_default_config

### Version 4.5.3
 - eXtremeSHOK.com Maintenance
 - badmacro.ndb rule support for sanesecurity
 - Sanesecurity_sigtest.yara rule support for sanesecurity
 - Sanesecurity_spam.yara rule support for sanesecurity
 - Changed required_config_version to minimum_required_config_version
 - Script now supports a minimum config version to allow for out of sync config and script versions

### Version 4.5.2
 - eXtremeSHOK.com Maintenance
 - hackingteam.hsb rule support for sanesecurity

### Version 4.5.1
 - eXtremeSHOK.com Maintenance
 - Beta YARA rule support for sanesecurity
 - Config updated to 4.8 due to changes
 - Bugfix "securiteinfo_enabled" should be "$securiteinfo_enabled"

### Version 4.5.0
 - eXtremeSHOK.com Maintenance
 - Initial YARA rule support for sanesecurity
 - Added Yara-Rules project Database
 - Added config option to quickly enable/disable an entire database
 - Config updated to 4.7 due to changes
 - Note: Yara rules require clamav 0.99+
 - Bugfix removed unused linuxmalwaredetect_authorisation_signature varible from script

### Version 4.4.5
 - eXtremeSHOK.com Maintenance
 - Updated SecuriteInfo setup instructions 

### Version 4.4.4
 - eXtremeSHOK.com Maintenance
 - Committed patch-1 by SecuriteInfo (clean up of SecuriteInfo databases)
 - Fixed double $surl_insecure

### Version 4.4.3
 - eXtremeSHOK.com Maintenance
 - Bugfix for SecuriteInfo not downloading by Colin Waring
 - Default will now silence ssl errors caused by ssl certificate errors
 - Config updated to 4.6 due to new varible: silence_ssl

### Version 4.4.2
 - eXtremeSHOK.com Maintenance
 - Improved config error checking
 - Config updated to 4.5, due to invalid default dbs-si value
 - Fix debug varible being present
 - Bug fix for ubuntu 14.04 with sed being aliased
 - Explicitly set bash as the shell

### Version 4.4.1
 - eXtremeSHOK.com Maintenance
 - Added error checking to detect if the config could be broken.

### Version 4.4.0
 - eXtremeSHOK.com Maintenance
 - Code refactoring: 
 - Added full support for Linux Malware Detect clamav databases
 - Config updated to 4.4

### Version 4.3.0
 - eXtremeSHOK.com Maintenance
 - Code refactoring: group and move functions to top of script
 - Complete rewrite of securiteinfo support, full support for Free/Delayed clamav by securiteinfo.com ;-P
   Note: securite info requires you to create a free account and add your authorisation code to the config.
 - Config updated to 4.3
 - Restructured Config

### Version 4.2.0
 - eXtremeSHOK.com Maintenance
 - Replace annoying si_ , mbl_,  ss_  with actual names ie. securiteinfo_ malwarepatrol_ sanesecurity_
 - Complete rewrite of malwarepatrol support, full support for Free/Delayed clamav ;-P
   Note: malware patrol requires you to create a free account and add your "purchase" code to the config.
 - More fixes to config prasing and stripping of comments and whitespace
 - Code refactoring: remove empty commands: echo "" and comment ""
 - Config version detection and enforcing

### Version 4.1.0
 - eXtremeSHOK.com Maintenance
 - Fix on default enable of foxhole medium and High false positive sources
 - grammatical corrections to some comments and log output
 - sig-boundary patch by Alan Stern
 - create intermediate monitor-ign-old.txt to prevent reading and writing of local.ign by Alan Stern

### Version 4.0.0
 - eXtremeSHOK.com Maintenance
 - Enabled all low false positive sources by default
 - Added all Sanesecurity database files
 - Disabled all med/high false positive sources by default
 - Set default configs to work out of the box on a centos system
 - Silence cron job
 - Set correct paths throughout the script
 - Updated Installation Instructions
 - Updated Paths for removal
 - Updated Default locations to reflect installation instructions
 - Fix: correctly remove comments and blanklines from config before eval
 - Remove: invalid config values (eg. EXPORT path)
 - Fix: correctly check if rsync was successful

## USAGE

Usage: clamav-unofficial-sigs.sh [OPTION] [PATH|FILE]

-c, --config    Direct script to use a specific configuration file
        eg: '-c /path/to/clamav-unofficial-sigs.conf'
        Optional if the default config is available
        Default: /etc/clamav-unofficial-sigs.conf

--force         Force all databases to be downloaded, could cause ip to be blocked

-h, --help      Display this script's help and usage information

-v, --version   Output script version and date information

-d, --decode-sig        Decode a third-party signature either by signature name
        (eg: Sanesecurity.Junk.15248) or hexadecimal string.
        This flag will 'NOT' decode image signatures

-e, --encode-string     Hexadecimal encode an entire input string that can
        be used in any '*.ndb' signature database file

-f, --encode-formatted  Hexadecimal encode a formatted input string containing
        signature spacing fields '{}, (), *', without encoding
        the spacing fields, so that the encoded signature
        can be used in any '*.ndb' signature database file

-g, --gpg-verify        GPG verify a specific Sanesecurity database file
        eg: '-g filename.ext' (do not include file path)

-i, --information       Output system and configuration information for
        viewing or possible debugging purposes

-m, --make-database     Make a signature database from an ascii file containing
        data strings, with one data string per line.  Additional
        information is provided when using this flag

-r, --remove-script     Remove the clamav-unofficial-sigs script and all of
        its associated files and databases from the system

-s, --test-database     Clamscan integrity test a specific database file
        eg: '-s filename.ext' (do not include file path)

-t, --output-triggered  If HAM directory scanning is enabled in the script's
        configuration file, then output names of any third-party
        signatures that triggered during the HAM directory scan

-w, --whitelist Adds a signature whitelist entry in the newer ClamAV IGN2
        format to 'my-whitelist.ign2' in order to temporarily resolve
        a false-positive issue with a specific third-party signature.
        Script added whitelist entries will automatically be removed
        if the original signature is either modified or removed from
        the third-party signature database

--check-clamav  If ClamD status check is enabled and the socket path is correctly specified
        then test to see if clamd is running or not

### Script updates can be found at: https://github.com/extremeshok/clamav-unofficial-sigs

Original Script can be found at: http://sourceforge.net/projects/unofficial-sigs
