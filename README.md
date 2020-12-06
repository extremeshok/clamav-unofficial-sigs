# clamav-unofficial-sigs [![GitHub Release](https://img.shields.io/github/release/extremeshok/clamav-unofficial-sigs.svg?label=Latest)](https://github.com/extremeshok/clamav-unofficial-sigs/releases/latest) [![Build Status](https://travis-ci.org/extremeshok/clamav-unofficial-sigs.svg?branch=master)](https://travis-ci.org/extremeshok/clamav-unofficial-sigs) [![Issue Count](https://codeclimate.com/github/extremeshok/clamav-unofficial-sigs/badges/issue_count.svg)](https://codeclimate.com/github/extremeshok/clamav-unofficial-sigs)

ClamAV Unofficial Signatures Updater

## Maintained and provided by <https://eXtremeSHOK.com>

## Description

The clamav-unofficial-sigs script provides a simple way to download, test, and update third-party signature databases provided by Sanesecurity, FOXHOLE, OITC, Scamnailer, BOFHLAND, CRDF, Porcupine, Securiteinfo, MalwarePatrol, Yara-Rules Project, urlhaus, MalwareExpert etc. The script will also generate and install cron, logrotate, and man files.

### Automated Testing and Linting

* Travis-CI
* Linting with markdownlint-cli and shellcheck
* Testing with Ubuntu Focal and macOS / OSX

### Checkout some of our other solutions: <https://github.com/extremeshok?tab=repositories>

### Support / Suggestions / Comments

Please post them on the issue tracker: <https://github.com/extremeshok/clamav-unofficial-sigs/issues>

### Submit Patches / Pull requests to the "dev" Branch

### Required Ports / Firewall Exceptions

* rsync: TCP port 873
* wget/curl: TCP port 443

### Supported Operating Systems

Debian, Ubuntu, Raspbian, CentOS (RHEL and clones), OpenBSD, FreeBSD, OpenSUSE, Archlinux, Mac OS X, Slackware, Solaris (Sun OS), pfSense, Zimbra and derivative systems

### Quick Install and Upgrade Guide

<https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/INSTALL.md>

### Operating System Specific Install and Upgrade Guides

* CentOS: <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/centos7.md>
* Ubuntu: <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/ubuntu-debian.md>
* Debian: <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/ubuntu-debian.md>
* Mac OSX: <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/macosx.md>
* pFsense: <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/guides/pfsense.md>

### UPGRADE INSTRUCTIONS (version 7.0 +)

```bash
clamav-unofficial-sigs.sh --upgrade
clamav-unofficial-sigs.sh
```

### FOR PACKAGE MAINTAINERS / PACKAGERS

Please use the included os.*.conf sample config file as a base for your os.conf, this will disable automatic updates, update notifications and the uninstallation feature. <https://github.com/extremeshok/clamav-unofficial-sigs/tree/master/config/packaging>

### Always Run the script once as your superuser to set all the permissions and create the relevant directories

### Advanced Config Overrides

* Default configs are loaded in the following order if they exist:
* master.conf -> os.conf -> os.*.conf -> user.conf or your-specified.config
* user.conf will always override os.conf and master.conf, os.conf will override master.conf
* please do not alter the master.conf, rather create a user.conf
* A minimum of 1 config is required.
* Specifying a config on the command line (-c | --config) will override the loading of the default configs

#### Check if signature are being loaded

**Run the following command to display which signatures are being loaded by clamav

```clamscan --debug 2>&1 /dev/null | grep "loaded"```

#### SELinux cron permission fix

> WARNING - Clamscan reports ________ database integrity tested BAD - SKIPPING

**Run the following command to allow clamav selinux support**
```setsebool -P antivirus_can_scan_system true```

### Yara Rule Support automatically enabled (as of April 2016)

Since usage yara rules requires clamav 0.100 or above, they will be automatically deactivated if your clamav is older than the required version

### URLhaus Support (as of January 2020)

Usage of free URLhaus Database: <https://urlhaus.abuse.ch>

* Enabled by default

### Yara-Rules Project Support (as of June 2015, updated January 2020)

Usage of free Yara-Rules Project: <http://yararules.com>

* Enabled by default

Current limitations of clamav support: <http://blog.clamav.net/search/label/yara>

### malware.expert non-free database support (as of December 2020)

Usage of Malware Expert: <https://www.malware.expert>

1. Sign up for an account:  <https://www.malware.expert>
1. You will receive an email containing your serial key
1. Enter the serial key into the config malwareexpert_serial_key: replacing YOUR-SERIAL-KEY with your serial key from the email

### MalwarePatrol Free/Delayed list support (as of May 2015)

Usage of MalwarePatrol 2015 free clamav signatures: <https://www.malwarepatrol.net>

1. Sign up for a free account: <https://www.malwarepatrol.net/free-guard-upgrade-option/>
1. You will receive an email containing your password/receipt number
1. Enter the receipt number into the config malwarepatrol_receipt_code: replacing YOUR-RECEIPT-NUMBER with your receipt number from the email

### SecuriteInfo Free/Delayed list support (as of June 2015)

Usage of SecuriteInfo 2015 free clamav signatures: <https://www.securiteinfo.com>

1. Sign up for a free account: <https://www.securiteinfo.com/clients/customers/signup>
1. You will receive an email to activate your account and then a followup email with your login name
1. Login and navigate to your customer account: <https://www.securiteinfo.com/clients/customers/account>
1. Click on the Setup tab
1. You will need to get your unique identifier from one of the download links, they are individual for every user
    1. The 128 character string is after the <http://www.securiteinfo.com/get/signatures/>
    1. Example <https://www.securiteinfo.com/get/signatures/your_unique_and_very_long_random_string_of_characters/securiteinfo.hdb>
    Your 128 character authorisation signature would be: your_unique_and_very_long_random_string_of_characters
1. Enter the authorisation signature into the config securiteinfo_authorisation_signature: replacing YOUR-SIGNATURE-NUMBER with your authorisation signature from the link

### Linux Malware Detect support (as of May 2015, updated January 2020)

Usage of free Linux Malware Detect clamav signatures: <https://www.rfxn.com/projects/linux-malware-detect/>

* Enabled by default, no configuration required

### If you want to add, report a missing one or have a problem with a database

Please post on the issue tracker: <https://github.com/extremeshok/clamav-unofficial-sigs/issues>

## USAGE

```bash
Usage: clamav-unofficial-sigs.sh   [OPTION] [PATH|FILE]

-c, --config   Use a specific configuration file or directory
  eg: '-c /your/dir' or ' -c /your/file.name'  
  Note: If a directory is specified the directory must contain at least:  
  master.conf, os.conf or user.conf
  Default Directory: /etc/clamav-unofficial-sigs

-F, --force   Force all databases to be downloaded, could cause ip to be blocked

-h, --help   Display this script's help and usage information

-V, --version   Output script version and date information

-v, --verbose   Be verbose, enabled when not run under cron

-s, --silence   Only output error messages, enabled when run under cron

-d, --decode-sig   Decode a third-party signature either by signature name
  (eg: Sanesecurity.Junk.15248) or hexadecimal string.
  This flag will 'NOT' decode image signatures

-e, --encode-string   Hexadecimal encode an entire input string that can
  be used in any '*.ndb' signature database file

-f, --encode-formatted   Hexadecimal encode a formatted input string containing
  signature spacing fields '{}, (), *', without encoding
  the spacing fields, so that the encoded signature
  can be used in any '*.ndb' signature database file

-g, --gpg-verify   GPG verify a specific Sanesecurity database file
  eg: '-g filename.ext' (do not include file path)

-i, --information   Output system and configuration information for
  viewing or possible debugging purposes

-m, --make-database   Make a signature database from an ascii file containing
  data strings, with one data string per line.  Additional
  information is provided when using this flag

-t, --test-database   Clamscan integrity test a specific database file
  eg: '-t filename.ext' (do not include file path)

-o, --output-triggered   If HAM directory scanning is enabled in the script's
  configuration file, then output names of any third-party
  signatures that triggered during the HAM directory scan

-w, --whitelist <signature-name>   Adds a signature whitelist entry in the newer ClamAV IGN2
  format to 'my-whitelist.ign2' in order to temporarily resolve
  a false-positive issue with a specific third-party signature.
  Script added whitelist entries will automatically be removed
  if the original signature is either modified or removed from
  the third-party signature database

--check-clamav   If ClamD status check is enabled and the socket path is correctly
  specified then test to see if clamd is running or not

--upgrade   Upgrades this script and master.conf to the latest available version

--install-all   Install and generate the cron, logrotate and man files, autodetects the values
  based on your config files

--install-cron   Install and generate the cron file, autodetects the values
  based on your config files

--install-logrotate   Install and generate the logrotate file, autodetects the
  values based on your config files

--install-man   Install and generate the man file, autodetects the
  values based on your config files

--remove-script   Remove the clamav-unofficial-sigs script and all of
  its associated files and databases from the system
```

## Change Log

### Version 7.2 ( XX December 2020: Under Development)

* Database rating downgrades are now supported, eg, changing from HIGH to LOW will remove the HIGH and MEDIUM rated databases.
* Disabled databases are automatically removed
* Disable databases by  setting the rating to "DISABLED" eg. securiteinfo_dbs_rating="DISABLED" will disable all securiteinfo databases
* Added Malware Expert databases (non-free)
* Reworked securiteinfo premium databases (non-free)
* Added malwarepatrol_db to specify the exact database name (default: malwarepatrol.db)
* Added detection of tar executable (use gtar on mac and bsd)
* Config os.macosx.conf renamed to os.macos.conf
* Fix: set ownership of last-version-check.txt
* More automated linting and testing (markdown and macOS / osx) via travis-ci
* Updated macOS installation guide for Big Sur (OSX 11)
* Incremented the config to version 93

### Version 7.1 ( Not Released)

* Enforce HTTPS validation by default
* Updated sanesecurity publickey.gpg url to use SSL
* Ignore yara files that include modules
* Enabled yararulesproject rules by default
* os.gentoo.conf: disable updates and upgrade checks
* Fix: URLhaus log message
* Fix wrong download URL for MalwarePatrol
* Fix: fallback to host if dig is not used
* Disable cron MAILTO
* BSD read config fix
* Incremented the config to version 92
* Thank you @dandanio @Mrothyr @m0urs @msapiro @orlitzky @SlothOfAnarchy @jkellerer @RobbieTheK

### Version 7.0.1 (25 January 2020)

* Disable yara project rules duplicated in rxfn.yara (Thanks @dominicraf)
* Incremented the config to version 91

### Version 7.0.0 (24 January 2020)

* eXtremeSHOK.com Maintenance
* Added urlhaus database
* Added extra yararulesproject databases
* Added new linuxmalwaredetect yara file
* Automatic upgrades ( --upgrade )
* Added --upgrade command line option
* Option to disable automatic upgrades ( allow_upgrades )
* Option to disable update checks (allow_update_checks)
* Increase download time to 1800 seconds from 600 seconds
* os.conf takes preference over os.***.conf
* Warn if there are multiple os.***.conf files
* More sanity checks to help users and prevent errors
* Better output of --info
* Fix all known bugs
* Implement all suggestions
* Fixed yararulesproject database names
* Correctly silence curl and wget
* New linuxmalwaredetect logic
* New malwarepatrol logic
* Suppress --- and === from the logs
* Update the documentation / guides
* Increase minimum clamav version for yara rules to 0.100 or above
* Fix systemd.timer and systemd.service files
* More travis-ci tests
* Added os.alpine.conf
* Added debug options/mode to config
* Set minimum config required to 90
* Lots of refactoring and optimizing
* Only check for and notify about script updates every 12hours
* Incremented the config to version 90

### Version 6.1.1 (02 September 2019)

* eXtremeSHOK.com Maintenance
* Update os.archlinux.conf, thanks @amishmm
* master.conf set default dbs rating to medium
* user.conf better suggested values
* Default to using curl, less logic required (lower cpu)
* force_curl replaced with force_wget
* Fix: suppress all non-error output under cron/non interactive terminal
* Fix: check log file is not a link before setting permissions, only set if owned by root.
* Fix: failed to create symbolic link
* Fix: curl --compress ->> curl --compressed
* Minor enhancement to travis-ci checks
* Incremented the config to version 77

### Version 6.1.0 (27 August 2019)

* eXtremeSHOK.com Maintenance
* Thanks Reio Remma & Oliver Nissen
* fail added to all curl commands
* Fix: Missing logic for LOWMEDIUMONLY | MEDIUMHIGHONLY | HIGHONLY databases
* Support for either os.osname.conf or os.conf files (no more needing to rename the os.osname.conf to os.conf)
* Where possible replaced echo with xshok_pretty_echo_and_log
* Refactor xshok_pretty_echo_and_log and make all notices styles consistent
* Silence output when run under cron
* add MAILTO=root to the generated cron file
* Add full proxy support for wget, curl, rsync, dig, host
* Better support for proxy config variables
* New config variable: git_branch (defaults to master for the update checks)
* allow -w signature for quicker whitelisting
* Sanitize whitelist input string (Remove quotes and .UNOFFICIAL)
* Added Full support for Hash-based Signature Databases
* User.conf is pre-configured with default options to allow for quicker setup
* Default sanesecurity and LinuxMalwareDetect to enabled
* Increase default retries from 3 to 5
* Ensure log file permissions are correct
* Better update comparison check, only notify if newer
* Incremented the config to version 76

### Version 6.0.1

* eXtremeSHOK.com Maintenance
* Fix logging @dominicraf

### Version 6.0

* eXtremeSHOK.com Maintenance & Refactoring
* Add timestamp support (do not re-download not modified files, saves bandwidth)
* wget and curl uses compression for the transfer (detected when supported, saves bandwidth)
* Posix compliance 'which' replaced with 'command -v'
* More escaped characters, shellcheck compliance
* Option added: force_curl , to force the usage of curl instead of wget
* Workaround for wget, which cannot do --timestamping and --output-document together
* Added SECURITEINFO  securiteinfoold.hdb
* set malwarepatrol_free = no , when malwarepatrol_product_code != 8
* Fix: remove hardcoded malwarepatrol_product_code
* Fix: os.macosx.conf service: command not found
* Fix: whitelist a MalwarePatrol signature
* More reliable version checking
* Fix: Clamscan database integrity test
* Fix: version comparison of minimum Yara @bytesplit
* Use custom config directory @Amish
* unzip option -j was removed @wotomg
* ZCS 8.7 updates @tonster
* Logic fixes @Claus-Justus Heine
* Specify correct path for systemd units @SlothOfAnarchy
* Avoid hardcoded path to BASH @rseichter

### Version 5.6.2

* eXtremeSHOK.com Maintenance
* Bug Fix GPG always being disabled, thanks @orlitzky

### Version 5.6.1

* eXtremeSHOK.com Maintenance
* Packers/Javascript_exploit_and_obfuscation.yar false positive rating increased to HIGH
* Codeclimate fixes
* Incremented the config to version 73

### Version 5.6

* eXtremeSHOK.com Maintenance
* PGP is now optional and no longer a requirement and pgp support is auto-detected
* Full support for macOS / OS X and added clamav install guide
* Full support for pfSense and added clamav install guide
* Added os configs for Zimbra and Debian 8 with systemd
* Much better error messages with possible solutions given
* Better checking of possible issues
* Update all SANESECURITY signature databases
* Support for clamav-devel (clamav compiled from source)
* Added full proxy support to wget and curl
* Replace allot of "echo | cut | sed" with bash substitutions
* Added fallbacks/substitutions for various commands
* xshok_file_download and xshok_draw_time_remaining functions added to replace redundant code blocks
* Removed SANESECURITY mbl.ndb as this file is not showing up on the rsync mirrors
* Allow exit code 23 for rsync
* Major refactoring: Normalize comments, quotes, functions, conditions
* Protect various arguments and "POSIX-ize" script integrity
* Enhanced testing with travis-ci, including clamav 0.99
* Incremented the config to version 72

### Version 5.4.1

* eXtremeSHOK.com Maintenance
* Disable installation when either pkg_mgr or pkg_rm is defined.
* Minor refactoring
* Update master.conf with the new Yara-rules project file names
* Incremented the config to version 69

### Version 5.4

* eXtremeSHOK.com Maintenance
* Added Solaris 10 and 11 configs
* When under Solaris we define our own which function
* Define grep_bin variable, use gnu grep on sun os
* Fallback to gpg2 if gpg not found,
* Added support for csw gnupg on solaris
* Trap the keyboard interrupt (ctrl+c) and gracefully exit
* Added CentOS 7 Atomic config @deajan
* Minor refactoring and removing of unused variables
* Removed CRDF signatures as per Sanesecurity #124
* Added more Yara rule project Rules
* Incremented the config to version 68

### Version 5.3.2

* eXtremeSHOK.com Maintenance
* Bug Fix: Additional Databases not downloading
* Added sanesecurity_update_hours option to limit updating to once every 2 hours
* Added additional_update_hours option to limit updating to once every 4 hours
* Refactor Additional Database File Update code
* Updated osx config with correct group for homebrew

### Version 5.3.1

* eXtremeSHOK.com Maintenance
* Bug Fix: for GPG Signature test FAILED by @DamianoBianchi
* Remove unused $GETOPT
* Refactor clamscan_integrity_test_specific_database_file (--test-database)
* Refactor gpg_verify_specific_sanesecurity_database_file (--gpg-verify)
* Big fix: missing $pid_dir

### Version 5.3.0

* eXtremeSHOK.com Maintenance
* Major change: Updated to use new database structure, now allows all low/medium/high databases to be enabled or disabled.
* Major change: curl replaced with wget (will fallback to curl is wget is not installed)
* Major change: script now functions correctly as the clamav user when started under cron
* Added fallback to curl if wget is not available
* Added locking (Enable pid file to prevent issues with multiple instances)
* Added retries to fetching downloads
* Code refactor: if wget repaced with if $? -ne 0
* Enhancement: Verify the clam_user and clam_group actually exists on the system
* Added function: xshok_user_group_exists, to check if a specific user and group exists
* Bug Fix: setmode only if is root
* Bug Fix: eval not working on certain systems
* Bug fix: rsync output not correctly silenced
* Code refactor: remove legacy `..` with $(...)
* Code refactor: replace [ ... -a ... ] with [ ... ] && [ ... ]
* Code refactor: replace [ ... -o ... ] with [ ... ] || [ ... ]
* Code refactor: replace cat "..." with done < ... from loops
* Code refactor: convert for loops using files to while loops
* Code refactor: read replaced with read -r
* Code refactor: added cd ... || exit , to handle a failed cd
* Code refactor: double quoted all varibles
* Code refactor: refactor all "ls" iterations to use globs
* Defined missing uname_bin variable
* Added function xshok_database
* Set minimum config required to 65
* Bump config to 65

### Version 5.2.2

* eXtremeSHOK.com Maintenance
* Added --install-all Install and generate the cron, logroate and man files, autodetects the values $oft based on your config files
* Added functions: xshok_prompt_confirm, xshok_is_file, xshok_is_subdir
* Replaced Y/N prompts with xshok_prompt_confirm
* Bug Fix for disabled databases being removed when the remove_disabled_databases is set to NO (default)
* Added more warnings to remove_script and made it double confirmed
* Remove_script will only remove work_dir if its a sub directory
* Remove_script will only remove files if they are files
* Removed -r switch, --remove-script needs to be used instead of both -r and --remove-script
* Fixed: remove_script not removing logrotate file, cron file, man file

### Version 5.2.1

* eXtremeSHOK.com Maintenance
* Minor bugfix for Sanesecurity_sigtest.yara Sanesecurity_spam.yara files being removed incorrectly
* Minor fix: yararulesproject_enabled not yararulesproject_enable

### Version 5.2.0

* eXtremeSHOK.com Maintenance
* Refactor some functions
* Added --install-man this will automatically generate and install the man (help) file
* Yararules and yararulesproject enabled by default
* Added clamav version detection to automatically disable yararules and yararulesproject if the current clamav version does not support them
* Database files ending with .yar/.yara/.yararules will automatically be disabled from the database if yara rules are not supported
* Script options are added to the man file
* Fixed hardcoded logrotate and cron in remove_script
* Fixed incorrectly assigned logrotate varibles in install-logrotate
* Config added info for port/package maintainers regarding:  pkg_mgr and pkg_rm
* Removed pkg_mgr and pkg_rm from freebsd and openbsd os configs
* Allow overriding of all the individual workdirs, this is mainly to aid package maintainers
* Rename sanesecurity_dir to work_dir_sanesecurity, securiteinfo_dir to work_dir_securiteinfo, malwarepatrol_dir to work_dir_malwarepatrol, yararules_dir to work_dir_yararules, add_dir to work_dir_add, gpg_dir to work_dir_gpg, work_dir_configs to work_dir_work_configs
* Rename yararules_enabled to yararulesproject_enabled
* Rename all yararules to yararulesproject
* Fix to prevent disabled databases processing certian things which will not be used as they are disabled
* Set minimum config required to 62
* Bump config to 62

### Version 5.1.1

* eXtremeSHOK.com Maintenance
* Added OS X and openbsd configs
* Fixed host fallback sed issues by @MichaelKuch
* Suppress most error messages of chmod and chown
* check permissions before chmod
* Added the config option remove_disabled_databases # Default is "no", if enabled when a database is disabled we will remove the associated database files.
* Added function xshok_mkdir_ownership
* Do not set permissions of the log, cron and logrotate dirs
* Fix: fallback for missing gpg -r option on OS X
* Update sanesecurity signatures
* Bump config to 61

### Version 5.1.0

* eXtremeSHOK.com Maintenance
* Added --install-cron this will automatically generate and install the cron file
* Added --install-logrotate this will automatically generate and install the logrotate file
* Change official URL of SecuriteInfo signatures
* Added a new database (securiteinfoandroid.hdb) for SecuriteInfo
* Remove database files after disabling a database group by @reneschuster
* Updated Gentoo OS config by @orlitzky
* Regroup functiuons
* Increase travis-ci code testing
* Set minimum config required to 60
* Bump config to 60

### Version 5.0.6

* eXtremeSHOK.com Maintenance
* Updated winnow databases as per information from Tom @ OITC
* Bump config to 58

### Version 5.0.5

* eXtremeSHOK.com Maintenance
* Add support for specifying a custom config dir or file with (--config) -c option
* Removed default_config
* Added travis-ci build testing
* Updates to the help and usage display
* Added sanity testing of sanesecurity_dbs, securiteinfo_dbs, linuxmalwaredetect_dbs, yararules_dbs, add_dbs
* Added function xshok_array_count
* Prevent some issues with an incomplete or only a user.conf being loaded
* Added fallback to host if dig returns no records
* Check there are Sanesecurity mirror ips before we attempt to rsync
* Important binaries have been aliased (clamscan, rsync, curl, gpg) and allow their paths to be overridden
* Added sanity checks to make sure the binaries and workdir is defined
* Custom Binary Paths added to the config (clamscan_bin, rsync_bin, curl_bin, gpg_bin)
* Bump config to 57
* Added initial centos6 + cpanel os config
* Bugfix Only start logging once all the configs have been loaded
* Rename $version to script_version
* Default malwarePatrol to the free version
* Added script version checks

### Version 5.0.4

* eXtremeSHOK.com Maintenance
* Added/Updated OS configs: CentOS 7, FreeBSD, Slackware
* Added clamd_reload_opt to fix issues with centos7 conf
* Fix --remove-script should call remove_script() function by @IdahoPL
* Add OS specific settings to logrotate
* Increased default timeout values
* Attempt to Silence more output
* Create the log_file_path directory before we touch the file.
* Updated config file to remove the $work_dir varible from dir names
* Remove trailing / from directory names
* Initial support for Travis-Ci testing
* Fixed config option enable_logging -> logging_enabled
* Config updated to 56 due to changes

### Version 5.0.3

* eXtremeSHOK.com Maintenance
* Added OS configs: OpenSUSE, Archlinux, Gentoo, Raspbian, FreeBSD
* Fixed config option enable_logging -> logging_enabled

### Version 5.0.2

* eXtremeSHOK.com Maintenance
* Detect if the entire script is available/complete
* Fix for Missing space between "]

### Version 5.0.1

* eXtremeSHOK.com Maintenance
* Disable logging if the log file is not writable.
* Do not attempt to log before a config is loaded

### Version 5.0.0

* eXtremeSHOK.com Maintenance
* Added porcupine.hsb: Sha256 Hashes of VBS and JSE malware Database from sanesecurity
* Fix for missing $ for clamd_pid an incorrect variable definition
* Fixes for not removing dirs by @msapiro
* Updates to account for changed names and addition of sub-directories for Yara-Rules by @msapiro
* Use MD5 with MalwarePatrol by @olivier2557
* Suppress the header and config loading message if running via cron
* Added systemd files by @falon
* Added config option remove_bad_database,  a database with a BAD integrity check will be removed
* Fixed broken whitelisting of malwarepatrol signatures
* Replaced Version command option -v with -V
* Added command option -v (--verbose) to force verbose output
* Removed config options: silence_ssl, curl_silence, rsync_silence, gpg_silence, comment_silence
* Added ignore_ssl option to supress ssl errors and warnings, ie operate in insecure mode.
* Replaced test-database command option -s with -t
* Replaced output-triggered command option -t with -o
* Added command option -s (--silence) to force silenced output
* Default verbose for terminal and silence for cron
* Added RHEL/Centos 7 config settings
* Added short option (-F) to Force all databases to be downloaded, could cause ip to be blocked"
* Fixed removal of failed databases, disbale with option "remove_bad_database"
* Removed config options: clamd_start, clamd_stop
* Full rewrite of the config handling, master.conf -> os.conf -> user.conf or your-specified.config
* Configs loaded from the /etc/clamav-unofficial-sigs dir
* Added various os.conf files to ease setup
* Added selinux_fixes config option, this will run restorecon on the database files
* minor code refactoring and reindenting

### Version 4.9.3

* eXtremeSHOK.com Maintenance
* Various Bug Fixes
* Last release of 4.x.x base
* minor code refactoring

### Version 4.9.2

* eXtremeSHOK.com Maintenance
* Added function xshok_check_s2 to prevent possible errors with -c and no configfile path
* minor code refactoring

### Version 4.9.1

* eXtremeSHOK.com Maintenance
* OS X compatibility fix by stewardle
* missing $ in $yararules_enabled

### Version 4.9

* eXtremeSHOK.com Maintenance
* Code Refactoring
* New function clamscan_reload_dbs, will first try and reload the clam database, if reload fails will restart clamd
* Added Function xshok_pretty_echo_and_log, far easier and cleaner way to output and log information
* Removed functions comment, log
* Removed config option reload_opt
* Added config option clamd_restart_opt
* Added support for # characters in config values, ie malwarepatrol subscription key contains a #
* Minor formatting and code consitency changes
* 10% Smaller script size
* Config updated to 53 due to changes

### Version 4.8

* eXtremeSHOK.com Maintenance
* Added long option (--force) to Force all databases to be downloaded, could cause ip to be blocked"
* added config option:  malwarepatrol_free="yes", set to "no" to enable commercial subscription url
* added support for commercial malwarepatrol subscription
* Grammar fix in config
* SELINUX cronjob fix added to readme
* Corrects tput warning when used without TERM (like in cron)
* Config updated to 52 due to changes

### Version 4.7

* eXtremeSHOK.com Maintenance
* Code Refactoring
* Complete rewrite of the main case selector (program options)
* Added long options (--decode-sig, --encode-string, --encode-formatted, --gpg-verify, --information, --make-database, --remove-script, --test-database, --output-triggered)
* Replaced clamd-status.sh with --check-clamav
* Removed CHANGELOG, changelog has been replaced by this part of the readme and the git commit log.
* Config updated to 51 due to changes

### Version 4.6.1

* eXtremeSHOK.com Maintenance
* Code Refactoring
* Added generic options (--help --version --config)
* Correctly handle generic options before the main case selector
* Sanitize the config before the main case selector (option)
* Rewrite and formatting of the usage options
* Removed the version information code as this is always printed

### Version 4.6

* eXtremeSHOK.com Maintenance
* Code Refactoring
* Removed custom config forced to use the same filename as the default config
* Change file checks from exists to exists and is readable
* Removed legacy config checks
* Full support for custom config files for all tasks
* Removed function: no_default_config

### Version 4.5.3

* eXtremeSHOK.com Maintenance
* badmacro.ndb rule support for sanesecurity
* Sanesecurity_sigtest.yara rule support for sanesecurity
* Sanesecurity_spam.yara rule support for sanesecurity
* Changed required_config_version to minimum_required_config_version
* Script now supports a minimum config version to allow for out of sync config and script versions

### Version 4.5.2

* eXtremeSHOK.com Maintenance
* hackingteam.hsb rule support for sanesecurity

### Version 4.5.1

* eXtremeSHOK.com Maintenance
* Beta YARA rule support for sanesecurity
* Config updated to 4.8 due to changes
* Bugfix "securiteinfo_enabled" should be "$securiteinfo_enabled"

### Version 4.5.0

* eXtremeSHOK.com Maintenance
* Initial YARA rule support for sanesecurity
* Added Yara-Rules project Database
* Added config option to quickly enable/disable an entire database
* Config updated to 4.7 due to changes
* Note: Yara rules require clamav 0.99+
* Bugfix removed unused linuxmalwaredetect_authorisation_signature varible from script

### Version 4.4.5

* eXtremeSHOK.com Maintenance
* Updated SecuriteInfo setup instructions

### Version 4.4.4

* eXtremeSHOK.com Maintenance
* Committed patch-1 by SecuriteInfo (clean up of SecuriteInfo databases)
* Fixed double $surl_insecure

### Version 4.4.3

* eXtremeSHOK.com Maintenance
* Bugfix for SecuriteInfo not downloading by Colin Waring
* Default will now silence ssl errors caused by ssl certificate errors
* Config updated to 4.6 due to new varible: silence_ssl

### Version 4.4.2

* eXtremeSHOK.com Maintenance
* Improved config error checking
* Config updated to 4.5, due to invalid default dbs-si value
* Fix debug varible being present
* Bug fix for ubuntu 14.04 with sed being aliased
* Explicitly set bash as the shell

### Version 4.4.1

* eXtremeSHOK.com Maintenance
* Added error checking to detect if the config could be broken.

### Version 4.4.0

* eXtremeSHOK.com Maintenance
* Code refactoring:
* Added full support for Linux Malware Detect clamav databases
* Config updated to 4.4

### Version 4.3.0

* eXtremeSHOK.com Maintenance
* Code refactoring: group and move functions to top of script
* Complete rewrite of securiteinfo support, full support for Free/Delayed clamav by securiteinfo.com ;-P
   Note: securite info requires you to create a free account and add your authorisation code to the config.
* Config updated to 4.3
* Restructured Config

### Version 4.2.0

* eXtremeSHOK.com Maintenance
* Replace annoying si_, mbl_, ss_, with actual names ie. securiteinfo_, malwarepatrol_, sanesecurity_
* Complete rewrite of malwarepatrol support, full support for Free/Delayed clamav ;-P
   Note: malware patrol requires you to create a free account and add your "purchase" code to the config.
* More fixes to config prasing and stripping of comments and whitespace
* Code refactoring: remove empty commands: echo "" and comment ""
* Config version detection and enforcing

### Version 4.1.0

* eXtremeSHOK.com Maintenance
* Fix on default enable of foxhole medium and High false positive sources
* grammatical corrections to some comments and log output
* sig-boundary patch by Alan Stern
* create intermediate monitor-ign-old.txt to prevent reading and writing of local.ign by Alan Stern

### Version 4.0.0 (Released 9 May 2015)

* eXtremeSHOK.com Maintenance
* Enabled all low false positive sources by default
* Added all Sanesecurity database files
* Disabled all med/high false positive sources by default
* Set default configs to work out of the box on a centos system
* Silence cron job
* Set correct paths throughout the script
* Updated Installation Instructions
* Updated Paths for removal
* Updated Default locations to reflect installation instructions
* Fix: correctly remove comments and blanklines from config before eval
* Remove: invalid config values (eg. EXPORT path)
* Fix: correctly check if rsync was successful

## Script updates can be found at

### <https://github.com/extremeshok/clamav-unofficial-sigs>
