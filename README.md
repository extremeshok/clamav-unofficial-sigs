# clamav-unofficial-sigs
ClamAV Unofficial Signatures Updater

Github fork of the sourceforge hosted and non maintained utility.

## Description
The clamav-unofficial-sigs script provides a simple way to download, test, and update third-party signature databases provided by Sanesecurity, SecuriteInfo, MalwarePatrol, OITC, etc. The package also contains cron, logrotate, and man files.


## ORIGINAL README CONTENTS
======================
CLAMAV-UNOFFICIAL-SIGS
======================

The clamav-unofficial-sigs script and accompanying files are provided by Bill Landry
(unofficialsigs@gmail.com) under general BSD licensing guidelines.

The clamav-unofficial-sigs.tar.gz package contains script and configuration files that
provide the capability to download, test, and update the 3rd-party signature databases
provided by Sanesecurity, SecuriteInfo, MalwarePatrol, OITC, etc.

Files contained in the clamav-unofficial-sigs.tar.gz package:

1.  README - This file.  Contains basic information about script features and capabilities.

2.  CHANGELOG - This file contains the changes that have been made between script updates.

3.  LICENSE - Open-Source license to allow packaging/porting and redistribution of scripts.

4.  INSTALL - Contains detailed instructions for configuring and using scripts.

5.  clamav-unofficial-sigs.conf - This file contains all of the user configurable variable
    setting for running the "clamav-unofficial-sigs.sh" shell script.

6.  clamav-unofficial-sigs.sh - This file contains the shell scripting code necessary for
    checking for updated 3rd party clamav signature databases, downloading of databases,
    testing for valid GPG signatures and clamscan for database integrity, and finally
    implementation of updated databases.

7.  clamav-unofficial-sigs.8 - This is the script's manual page.

8.  clamav-unofficial-sigs-cron - This is the script's cron file used to support automated
    script execution at specified time intervals.

9.  clamav-unofficial-sigs-logrotate - This is the script's logrotate file, used to rotate
    and compress log files at a specified time-interval and to keep the log archives for a
    specified time-frame.

10. clamd-status.sh - A stand-alone script that can be used to run status checks against
    clamd, and can be configured to attempt to start a non-running or crashed daemon.

Script (clamav-unofficial-sigs.sh) features & capabilities:

- Checks for updated unofficial clamav signature database files, detection and download.
- GPG signature verify and clamscan integrity test updated signature databases and implement.
- Download time randomization - this help to distribute the load more evenly for the database
  host mirror sites.
- Create signature bypass entries for temporarily resolving false-positive issues with third-
  party signatures.
- Ability to report which mirror site a download came from (good to know if there are issues).
- Reports if a downloaded database is actually different than the running copy.
- Status check to determine if clamd is running, and if enabled, ability to attemtp to start
  if detected not running.
- Ability to control script output, which is good when run via cron.
- Ability to create a backup copy of a running database before replacing it.
- Currently provides support for six different unofficial clamav database providers:
  Sanesecurity, SecuriteInfo, MalwarePatrol, OITC, etc.
- Ability to choose which database files to download and use from each provider.
- Coded to be portable across as many different OS platforms and utility versions as possible.
- Separate user configuration file, which will allow users to setup their configuration and not
  have to redo the configuration with each new script update.
- The script can hexadecimal encode (for usage) and decode (for viewing) virus signatures.
- Ability to create a hexadecimal signature database file from a clear text ascii file.
- Ability to enable scanning of a local HAM (non-spam) directory for false-positive hits from
  third-party signatures and removal of errant signatures from databases before implementing.
- Script logging can be enabled/disabled in the configuration file.
- Includes cron, manual, and logrotate files.

Script updates can be found at: http://sourceforge.net/projects/unofficial-sigs
