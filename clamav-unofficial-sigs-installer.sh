#!/bin/bash
##
## Version      : 1.0
## release d.d. : 01-02-2015
## Author       : L. van Belle
## E-mail       : louis@van-belle.nl
## Copyright    : Free as free can be, copy it, change it if needed.
## Sidenote     : if you change things, please inform me
## ChangeLog    : first release
## -------------------------------------------------------------------
## This script downloads the latest clamav-unofficial-sigs for you from github.
## It config the script and/or updates the old version. 
## This script is set for Debian Jessie and Wheezy. 
## extent it for other disto's
## use clamav for user and group name. 
## puts the config file from /etc/ to /etc/clamav 
## correct the logrotate file to clamav:adm 640 
## change other file locations to debian standards. 
## Test it and see the output in the end. 
## If it updates an old version it adapts all settings EXECPT the dbs 


if [ -n "$1" ] && [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo " "
    echo "This script will the latest clamav-unofficial-sigs from extremeshok github."
    echo "It wil extract it and install it, and ask for some things"
    echo "It check for and existing config file in /etc/ or /etc/clamav"
    echo "It will backup your old config and import (most) settings."
    echo  "usage:"
    echo  " '$0 -h or --help' will print this message."
    echo  " '$0 -fd or --force-download' force the download of the latest clamav-unofficial-sigs from github."
    echo
    exit 0
fi


######### FUNCTIONS ANY_OS START, which should work for any os.
run_as_root_or_sudo() {
# make sure this is being run by root
    if ! [[ $EUID -eq 0 ]]; then
	echo "This script should be run using sudo or by root."
	exit 1
    fi
}

message_os_detected() {
	echo " "
	echo "Detected OS: $PRETTY_NAME"
	echo " "
}

detect_and_get_os_variables() {
# import os variables
    if [ -e /etc/os-release ]; then 
	source /etc/os-release
    else 
	echo " "
	echo "Oh no... the os does not have the /etc/os-release file "
	echo "without it this script wont work."
	echo "Most distro's do have this file, yours not, please read also : "
	echo "http://www.freedesktop.org/software/systemd/man/os-release.html" 
	echo "Sorry, we cant continue... exiting now... "
	echo " "
	exit 1
    fi
}


######### FUNCTIONS 
do_version_check() {
   [ "$1" == "$2" ] && return 10
   ver1front=`echo $1 | cut -d "." -f -1`
   ver1back=`echo $1 | cut -d "." -f 2-`
   ver2front=`echo $2 | cut -d "." -f -1`
   ver2back=`echo $2 | cut -d "." -f 2-`
   if [ "${ver1front}" != "$1" ] || [ "${ver2front}" != "$2" ]; then
       [ "${ver1front}" -gt "${ver2front}" ] && return 11
       [ "${ver1front}" -lt "${ver2front}" ] && return 9
       [ "${ver1front}" == "$1" ] || [ -z "${ver1back}" ] && ver1back=0
       [ "${ver2front}" == "$2" ] || [ -z "${ver2back}" ] && ver2back=0
       do_version_check "${ver1back}" "${ver2back}"
       return $?
   else
           [ "$1" -gt "$2" ] && return 11 || return 9
   fi
}

message_defaults_per_os() {
    echo "Change-ing config file to ${ID} standards."
}

check_packages_depends() {
    if [ -z $(which unzip) ]; then 
	echo "Missing unzip, please install first. " 
	exit 1 
    fi
}


clamav_unofficial_sigs_base() {
    # always update the needed files
    echo "Copy-ing latest of clamav-unofficial-sigs to there folders : "
    echo "Putting file : clamav-unofficial-sigs.sh in /usr/local/sbin/"
    cp -f /tmp/clamav-sigs/clamav-unofficial-sigs.sh /usr/local/sbin/clamav-unofficial-sigs.sh
    chmod +x /usr/local/sbin/clamav-unofficial-sigs.sh
    echo "Putting file : clamav-unofficial-sigs.8 in /usr/share/man/man8"
    cp -f /tmp/clamav-sigs/clamav-unofficial-sigs.8 /usr/share/man/man8/clamav-unofficial-sigs.8
    echo "Putting file : clamav-unofficial-sigs-cron in /etc/cron.d/"
    cp -f /tmp/clamav-sigs/clamav-unofficial-sigs-cron /etc/cron.d/clamav-unofficial-sigs-cron
    echo "Putting file : clamav-unofficial-sigs-logrotate in /etc/logrotate.d/clamav-unofficial-sigs-logrotate"
    cp -f /tmp/clamav-sigs/clamav-unofficial-sigs-logrotate /etc/logrotate.d/clamav-unofficial-sigs-logrotate
    echo "--"
}

install_clamav_for_os_debuntu() {
# debian/ubuntu
	while true; do
	    echo "We can install clamav-daemon clamav-freshclam now for you"
	    read -p "Do you install them now? (y/n): " yn
	    case $yn in
	        [Yy]* ) SET_CLAMAV_INSTALL="1"; break;;
	        [Nn]* ) SET_CLAMAV_INSTALL="0"; break;;
	        * ) echo "Please answer yes or no.";;
	    esac
	done
        if [ "${SET_CLAMAV_INSTALL}" = "1" ]; then 
	    apt-get update 2>/dev/null 
	    apt-get install clamav-daemon clamav-freshclam -y
	fi
}

install_clamav_for_os_redtos() {
# redhat/centos
	while true; do
	    echo "We can install clamav-daemon clamav-freshclam now for you"
	    read -p "Do you install them now? (y/n): " yn
	    case $yn in
	        [Yy]* ) SET_CLAMAV_INSTALL="1"; break;;
	        [Nn]* ) SET_CLAMAV_INSTALL="0"; break;;
	        * ) echo "Please answer yes or no.";;
	    esac
	done
        if [ "${SET_CLAMAV_INSTALL}" = "1" ]; then 
	    yum update 2>/dev/null 
	    #yum install clamav-daemon clamav-freshclam -y
	    echo "NOT TESTED, Please test first."
	    exit 0
	fi
}

detect_clamd_version_for_yara() {
    ## Detect clamd version to enable/disable yara rules ( this can be improved ) 
    CLAMAV_VERSION_DETECTED=$(clamd -V | cut -d" " -f2| cut -c1-4 )
    do_version_check "0.99" "${CLAMAV_VERSION_DETECTED}"
    COMPAIR="$?"
    if [ "${COMPAIR}" -eq "11" ]; then 
	# lower
	echo "Yara Rules not supported, Clam version incompatible need 0.99 and up."
	sed -i 's/yararules_enabled=\"yes\"/yararules_enabled=\"no\"/g' /etc/clamav/clamav-unofficial-sigs.conf
    fi
    if [ "${COMPAIR}" -eq "9" ] || [ "${COMPAIR}" -eq "10" ]; then 
	# greater or same
        echo "Clamav 0.99 or up detected, yararules enabled, disable them is you dont want to use them."
	sed -i 's/yararules_enabled=\"no\"/yararules_enabled=\"yes\"/g' /etc/clamav/clamav-unofficial-sigs.conf
    fi
}

detect_etc_clamav() {
    ## this can be improved to detect if clamav is installed.
    if [ ! -d /etc/clamav ]; then 
	echo "No clamav configuration directory detected, please install clamav first"
	install_clamav_per_os_detected
	echo " "
    fi
}

get_latest_clamav_unofficial_sigs_github_zip() {
    if [ "$1" = "-fd" ] || [ "$1" = "--force-download" ]; then 
	rm -f /tmp/clamav-sigs/*
    fi

    if [ ! -d /tmp/clamav-sigs ]; then 
	mkdir -p /tmp/clamav-sigs
    fi

    ## always get the latest version of the extremeshok clamav-unofficial-sigs from github
    if [ ! -f /tmp/clamav-sigs/clamav-unofficial-sigs-${DATE_NOW}.zip ]; then 
	echo "Please wait a sec, downloading the latest version of clamav-unofficial-sigs"
        wget -q --no-check-certificate https://github.com/extremeshok/clamav-unofficial-sigs/archive/master.zip \
	    -O /tmp/clamav-sigs/clamav-unofficial-sigs-${DATE_NOW}.zip 
        if [ "$?" -eq "1" ]; then 
	    echo "Something went wrong with the download, exiting now. "
	    echo " "
	    exit 1
	else 
	    unzip -j -qq -o /tmp/clamav-sigs/clamav-unofficial-sigs-${DATE_NOW}.zip -d /tmp/clamav-sigs/
	fi
    else
	if [ ! -f /tmp/clamav-sigs/clamav-unofficial-sigs.sh ]; then 
	    unzip -j -qq -o /tmp/clamav-sigs/clamav-unofficial-sigs-${DATE_NOW}.zip -d /tmp/clamav-sigs/
	fi
	echo " "
	echo "Clamav-unofficial-sigs is already downloaded today, to re-download the file."
	echo "Remove the download file first : /tmp/clamav-sigs/clamav-unofficial-sigs-${DATE_NOW}.zip"
	echo "Or start the script with --fd (--force-download)"
	echo "The script will continue....."
	echo " "
    fi
}

detect_new_or_existing_config() {
    ## new install of update? after running your config file is always /etc/clamav/clamav-unofficial-sigs.conf
    ## we do change the clamav-unofficial-sigs.sh's default config location, so no worries.
    if [ ! -e /etc/clamav-unofficial-sigs.conf ] && [ ! -e /etc/clamav/clamav-unofficial-sigs.conf ] ; then 
	# new config
	UPDATE=0
	cp /tmp/clamav-sigs/clamav-unofficial-sigs.conf /etc/clamav/clamav-unofficial-sigs.conf
    else 
	# update config
	UPDATE=1
        echo "Warning         : /etc/clamav-unofficial-sigs.conf or /etc/clamav/clamav-unofficial-sigs.conf already exists."
	echo "Creating backup : clamav-unofficial-sigs.conf.${DATE_NOW}.backup in /etc/clamav"
        if [ -e /etc/clamav-unofficial-sigs.conf ]; then 
	    echo "Importing old settings from /etc/clamav-unofficial-sigs.conf"
	    source /etc/clamav-unofficial-sigs.conf
	    mv /etc/clamav-unofficial-sigs.conf /etc/clamav/clamav-unofficial-sigs.conf.${DATE_NOW}.backup
	fi
	if [ -e /etc/clamav/clamav-unofficial-sigs.conf ]; then 
	    echo "Importing old settings from /etc/clamav/clamav-unofficial-sigs.conf"
	    source /etc/clamav/clamav-unofficial-sigs.conf
	    mv /etc/clamav/clamav-unofficial-sigs.conf /etc/clamav/clamav-unofficial-sigs.conf.${DATE_NOW}.backup
	fi
	echo "Putting file : clamav-unofficial-sigs.conf in /etc/clamav"
	cp -f /tmp/clamav-sigs/clamav-unofficial-sigs.conf /etc/clamav/clamav-unofficial-sigs.conf
    fi
}

user_config_done_yes() {
	sed -i "s[user_configuration_complete=\"no\"[user_configuration_complete=\"yes\"[g" /etc/clamav/clamav-unofficial-sigs.conf
}

detect_malware_patrol_code() {
    ## configure/detect malware patrol code
    if [ "${malwarepatrol_receipt_code}" = "YOUR-RECEIPT-NUMBER" ]; then 
	echo "#####################################################"
	echo "WARING !!! "
	echo "No malwarepatrol_receipt_code detected, you better register for free.."
	echo "# 1. Sign up for a free account : https://www.malwarepatrol.net/signup-free.shtml"
	echo "# 2. You will recieve an email containing your password/receipt number"
	echo "# 3. Enter the receipt number into the config: replacing YOUR-RECEIPT-NUMBER with your receipt number from the email"
	echo " "
	while true; do
	    read -p "Do you already have a malware patrol receipt number? (y/n): " yn
	    case $yn in
	        [Yy]* ) SET_MALWAREPATROL="1"; break;;
	        [Nn]* ) SET_MALWAREPATROL="0"; break;;
	        * ) echo "Please answer yes or no.";;
	    esac
	done

        if [ "${SET_MALWAREPATROL}" -eq "1" ]; then 
	    while true; do
		read -p "Please type your receipt number: " INPUT_MALWAREPATROL
		echo "You typed: $INPUT_MALWAREPATROL"
		read -p  "is this correct? (y/n): " YN
		case $YN in
		    [Yy]* ) echo "Ok, continuing"; break;;
		    [Nn]* ) echo "please type it again"; continue;;
		    * ) echo "Please answer yes or no.";;
		esac
	    done
	sed -i "s/malwarepatrol_receipt_code=\"YOUR-RECEIPT-NUMBER\"/malwarepatrol_receipt_code=\"${INPUT_MALWAREPATROL}\"/g" /etc/clamav/clamav-unofficial-sigs.conf
	fi
    else
	if [ "${malwarepatrol_receipt_code}" != "YOUR-RECEIPT-NUMBER" ]; then 
	    echo "Detected previous malwarepatrol_receipt_code, transerring this one to the new configfile."
	    sed -i "s/malwarepatrol_receipt_code=\"YOUR-RECEIPT-NUMBER\"/malwarepatrol_receipt_code=\"${malwarepatrol_receipt_code}\"/g" /etc/clamav/clamav-unofficial-sigs.conf
	fi
    fi
}

detect_securite_info_signature() {
    ## configure/detect securiteinfo code
    if [ "${securiteinfo_authorisation_signature}" = "YOUR-SIGNATURE-NUMBER" ]; then 
	echo "#####################################################"
	echo "WARING !!! "
	echo "No securiteinfo_authorisation_signature, you better register for free.."
	echo "Usage of SecuriteInfo 2015 free clamav signatures : https://www.securiteinfo.com"
	echo " - 1. Sign up for a free account : https://www.securiteinfo.com/clients/customers/signup"
	echo " - 2. You will recieve an email to activate your account and then a followup email with your login name"
	echo " - 3. Login and navigate to your customer account : https://www.securiteinfo.com/clients/customers/account"
	echo " - 4. Click on the Setup tab"
	echo " - 5. You will need to get your unique identifier from one of the download links, they are individual for every user"
	echo " - 5.1. The 128 character string is after the http://www.securiteinfo.com/get/signatures/"
	echo " - 5.2. Example https://www.securiteinfo.com/get/signatures/your_unique_and_very_long_random_string_of_characters/securiteinfo.hdb"
	echo "        Your 128 character authorisation signature would be : your_unique_and_very_long_random_string_of_characters"
	echo " - 6. Enter the authorisation signature into the config securiteinfo_authorisation_signature: replacing YOUR-SIGNATURE-NUMBER with your authorisation signature from the link"
	echo " "
	while true; do
	    read -p "Do you already have a securiteinfo authorisation signature? (y/n): " yn
	    case $yn in
	        [Yy]* ) SET_SECURETIINFO="1"; break;;
	        [Nn]* ) SET_SECURETIINFO="0"; break;;
	        * ) echo "Please answer yes or no.";;
	    esac
	done

        if [ "${SET_SECURETIINFO}" -eq "1" ]; then 
	    while true; do
		read -p "Please type your receipt number: " INPUT_SECURETIINFO
		echo "You typed: $INPUT_SECURETIINFO"
		read -p  "is this correct? (y/n): " YN
		case $YN in
		    [Yy]* ) echo "Ok, continuing"; break;;
		    [Nn]* ) echo "please type it again"; continue;;
		    * ) echo "Please answer yes or no.";;
		esac
	    done
	    sed -i "s/securiteinfo_authorisation_signature=\"YOUR-SIGNATURE-NUMBER\"/securiteinfo_authorisation_signature=\"${INPUT_SECURETIINFO}\"/g" /etc/clamav/clamav-unofficial-sigs.conf
	fi
    else
	if [ "${securiteinfo_authorisation_signature}" != "YOUR-SIGNATURE-NUMBER" ]; then 
	    echo "Detected previous securiteinfo_authorisation_signature, transerring this one to the new configfile."
	    sed -i "s/securiteinfo_authorisation_signature=\"YOUR-SIGNATURE-NUMBER\"/securiteinfo_authorisation_signaturee=\"${securiteinfo_authorisation_signature}\"/g" /etc/clamav/clamav-unofficial-sigs.conf
	fi
    fi
}

import_old_settings_in_new_config_file() {
	# cron, changes bin to sbin due to "run as root", root script to sbin, user scripts to bin.
	sed -i "s[/usr/local/bin/clamav-unofficial-sigs.sh[/usr/local/sbin/clamav-unofficial-sigs.sh[g"  /etc/cron.d/clamav-unofficial-sigs-cron
	# change config file location in : /usr/local/sbin/clamav-unofficial-sigs.sh
	sed -i "s[default_config=\"/etc/clamav-unofficial-sigs.conf\"[default_config=\"/etc/clamav/clamav-unofficial-sigs.conf\"[g"  /usr/local/sbin/clamav-unofficial-sigs.sh
	# /etc/logrotate.d/clamav-unofficial-sigs-logrotate, user and group and rights changed to debian defaults for clamav/logrote.
	sed -i "s[/var/log/clamav-unofficial-sigs/clamav-unofficial-sigs.log[/var/log/clamav/clamav-unofficial-sigs.log[g" /etc/logrotate.d/clamav-unofficial-sigs-logrotate
	sed -i "s[     create 0644 clam clam[#     create 0644 clam clam[g" /etc/logrotate.d/clamav-unofficial-sigs-logrotate
	sed -i "s[#     create 0644 clamav clamav[     create 0640 clamav adm[g" /etc/logrotate.d/clamav-unofficial-sigs-logrotate

	# re-using old settings from installed clamav-unofficial-sigs.conf
	## Basic options
	sed -i "s[setmode=\"yes\"[setmode=\"${setmode}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[clam_dbs=\"/var/lib/clamav\"[clam_dbs=\"${clam_dbs}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[reload_dbs=\"yes\"[reload_dbs=\"${reload_dbs}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[ham_dir=\"/var/lib/clamav-unofficial-sigs/ham-test\"[ham_dir=\"${ham_dir}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[work_dir=\"/var/lib/clamav-unofficial-sigs\"[work_dir=\"${work_dir}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[enable_logging=\"yes\"[enable_logging=\"${enable_logging}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[log_file_name=\"clamav-unofficial-sigs.log\"[log_file_name=\"${log_file_name}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[malwarepatrol_free=\"\"[malwarepatrol_free=\"${malwarepatrol_free}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[securiteinfo_update_hours=\"4\"[securiteinfo_update_hours=\"${securiteinfo_update_hours}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[linuxmalwaredetect_update_hours=\"6\"[linuxmalwaredetect_update_hours=\"${linuxmalwaredetect_update_hours}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[malwarepatrol_update_hours=\"24\"[malwarepatrol_update_hours=\"${malwarepatrol_update_hours}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[yararules_update_hours=\"24\"[yararules_update_hours=\"${yararules_update_hours}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[sanesecurity_enabled=\"yes\"[sanesecurity_enabled=\"${sanesecurity_enabled}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[linuxmalwaredetect_enabled=\"yes\"[linuxmalwaredetect_enabled=\"${linuxmalwaredetect_enabled}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[malwarepatrol_enabled=\"yes\"[malwarepatrol_enabled=\"${malwarepatrol_enabled}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[yararules_enabled=\"no\"[yararules_enabled=\"${yararules_enabled}\"[g" /etc/clamav/clamav-unofficial-sigs.conf

	## Advanced options 
	sed -i "s[enable_random=\"yes\"[enable_random=\"${enable_random}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[min_sleep_time=\"60\"[min_sleep_time=\"${min_sleep_time}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[max_sleep_time=\"600\"[max_sleep_time=\"${max_sleep_time}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[rsync_connect_timeout=\"30\"[rsync_connect_timeout=\"${rsync_connect_timeout}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[rsync_max_time=\"90\"[rsync_max_time=\"${rsync_max_time}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[curl_connect_timeout=\"30\"[curl_connect_timeout=\"${curl_connect_timeout}\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[curl_max_time=\"90\"[curl_max_time=\"${curl_max_time}\"[g" /etc/clamav/clamav-unofficial-sigs.conf

# not correctly working yet... 
#	# check for database modifications, reuse the old ones
#	if [ ! -d /tmp/clamav-sigs/old ]; then 
#	    mkdir -p /tmp/clamav-sigs/{old,new,diff}
#	fi

#	echo "save-ing used database files for $x"
#	for x in sanesecurity_dbs securiteinfo_dbs linuxmalwaredetect_dbs malwarepatrol_db yararules_dbs add_dbs ; do 
#	    echo "${x}=\"${!x}\"" > /tmp/clamav-sigs/old/${x}.txt
#	done
#	# get new settings for db. 
#	source /etc/clamav/clamav-unofficial-sigs.conf
#	for x in sanesecurity_dbs securiteinfo_dbs linuxmalwaredetect_dbs malwarepatrol_db yararules_dbs add_dbs ; do 
#	    echo "${x}=\"${!x}\"" > /tmp/clamav-sigs/new/${x}.txt
#	done
#	for x in sanesecurity_dbs securiteinfo_dbs linuxmalwaredetect_dbs malwarepatrol_db yararules_dbs add_dbs ; do 
#	    diff /tmp/clamav-sigs/old/${x}.txt /tmp/clamav-sigs/new/${x}.txt > /tmp/clamav-sigs/diff/${x}.txt
#	done
#	
#	# add new deteted setting to the new files and import them.
#	for x in sanesecurity_dbs securiteinfo_dbs linuxmalwaredetect_dbs malwarepatrol_db yararules_dbs add_dbs ; do 
#	    cat /tmp/clamav-sigs/diff/${x}.txt | grep ">" | grep "\." | cut -c3-10000 > /tmp/clamav-sigs/newdbs-${x}.txt
#	done
#
#	# reimport settings for correcting DB's.
#	source /etc/clamav/clamav-unofficial-sigs.conf
#	for x in sanesecurity_dbs securiteinfo_dbs linuxmalwaredetect_dbs malwarepatrol_db yararules_dbs add_dbs ; do 
#	    OLD_DBS="$(cat /tmp/clamav-sigs/newdbs-${x}.txt)"
#	    sed -i "/${x}=/a ${OLD_DBS}" /etc/clamav/clamav-unofficial-sigs.conf
#	done

}

create_logrotate_per_os() {
if [ ${ID} = "debian" ]||[ ${ID} = "ubuntu" ]; then 
    CLAMAV_USER=clamav
    CLAMAV_GROUP=amd
    CLAMAV_LOGRIGHTS=0640
else 
    CLAMAV_USER=clam
    CLAMAV_GROUP=clam
    CLAMAV_LOGRIGHTS=0644
    echo "You might want to check the user/group and rights in /etc/logrotate.d/clamav-unofficial-sigs-logrotate"
fi

if [ ! -e /etc/logrotate.d/clamav-unofficial-sigs-logrotate ]; then 
cat << EOF >> /etc/logrotate.d/clamav-unofficial-sigs-logrotate
/var/log/clamav/clamav-unofficial-sigs.log {
     weekly
     rotate 4
     missingok
     notifempty
     compress
     create ${CLAMAV_LOGRIGHTS} ${CLAMAV_USER} ${CLAMAV_GROUP}
}
EOF
else
    echo "/etc/logrotate.d/clamav-unofficial-sigs-logrotate already exist"
    echo "Please check your user/group/right in this file"
    echo "we want ${CLAMAV_USER}/${CLAMAV_GROUP}/${CLAMAV_LOGRIGHTS}"
fi
}

create_cron_per_os() {
if [ ! -e /etc/cron.d/clamav-unofficial-sigs-cron ]; then 
cat << EOF >> /etc/logrotate.d/clamav-unofficial-sigs-logrotate
# The script is set to run hourly, at 45 minutes past the hour, and the
# script itself is set to randomize the actual execution time between
# 60 - 600 seconds.  Adjust the cron start time, user account to run the
# script under, and path information shown below to meet your own needs.

45 * * * * root /bin/bash /usr/local/sbin/clamav-unofficial-sigs.sh  > /dev/null
EOF
else
    echo "/etc/logrotate.d/clamav-unofficial-sigs-logrotate already exist"
    echo "Please check if the path the file clamav-unofficial-sigs.sh is correct"
fi
}


######### FUNCTIONS ANY_OS END, which should work for any os.

############################################################################################################
######### FUNCTIONS PER_OS START, if you extend the script, start here.
############################################################################################################
install_clamav_per_os_detected() {
    ## for new os, create a copy of some code below and adjust it.
    ## ONLY TESTED WITH DEBIAN (for now).
    if [ "${ID}" = "debian" ]||[ "${ID}" = "ubuntu" ]; then 
	install_clamav_for_os_debuntu
    fi
    ## NOT TESTED!! EXAMPLE, its here so others have an example.
    if [ "${ID}" = "redhat" ]||[ "${ID}" = "centos" ]; then 
	install_clamav_for_os_redtos
    fi
}

change_conf_2_debian() {
# settings same on wheezy and jessie
# for a new os, copy and change the function name to the os, example change_conf_2_ubuntu and adjust the settings. 
	message_defaults_per_os
	sed -i "s[clam_user=\"clam\"[#clam_user=\"clam\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[clam_group=\"clam\"[#clam_group=\"clam\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[#clam_user=\"clamav\"[clam_user=\"clamav\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[#clam_group=\"clamav\"[clam_group=\"clamav\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[#clamd_socket=\"/var/run/clamd.socket\"[clamd_socket=\"/var/run/clamav/clamd.ctl\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[log_file_path=\"/var/log/clamav-unofficial-sigs\"[log_file_path=\"/var/log/clamav\"[g" /etc/clamav/clamav-unofficial-sigs.conf
}

change_conf_2_ubuntu() {
	message_defaults_per_os
	sed -i "s[clam_user=\"clam\"[#clam_user=\"clam\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[clam_group=\"clam\"[#clam_group=\"clam\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[#clam_user=\"clamav\"[clam_user=\"clamav\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[#clam_group=\"clamav\"[clam_group=\"clamav\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[#clamd_socket=\"/var/run/clamd.socket\"[clamd_socket=\"/var/run/clamav/clamd.ctl\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	sed -i "s[log_file_path=\"/var/log/clamav-unofficial-sigs\"[log_file_path=\"/var/log/clamav\"[g" /etc/clamav/clamav-unofficial-sigs.conf
}

debian_wheezy_defaults() {
    # for a new os/release, copy and change the function name to the os_release, example ubuntu_trusty_defaults and adjust the settings. 
	if [ "${OS_SETUP}" = "wheezy" ]; then 
	    # Per OS Defined
	    sed -i "s[clamd_restart_opt=\"service clamd restart\"[clamd_restart_opt=\"service clamav-daemon restart\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	    sed -i "s[#clamd_start=\"service clamd start\"[clamd_start=\"service clamav-daemon start\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	    sed -i "s[#clamd_stop=\"service clamd stop\"[clamd_stop=\"service clamav-daemon stop\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	    sed -i "s[clamd_pid=\"/var/run/clamav/clamd.pid\"[clamd_pid=\"/var/run/clamav/clamd.pid\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	fi
}

debian_jessie_defaults() {
	if [ "${OS_SETUP}" = "jessie" ]; then 
	    # Per OS Defined
	    sed -i "s[clamd_restart_opt=\"service clamd restart\"[clamd_restart_opt=\"systemctl restart clamav-daemon\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	    sed -i "s[#clamd_start=\"service clamd start\"[#clamd_start=\"systemctl start clamav-daemon\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	    sed -i "s[#clamd_stop=\"service clamd stop\"[#clamd_stop=\"systemctl stop clamav-daemon\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	    sed -i "s[clamd_pid=\"/var/run/clamav/clamd.pid\"[#clamd_pid=\"/var/run/clamav/clamd.pid\"[g" /etc/clamav/clamav-unofficial-sigs.conf
	fi
}

#new os, copy this one, change debian to your os name, if you dont know what, 
# find it by type-ing : cat /etc/os-release | grep ID
configure_for_os_debian() {
# begin Debian
    if [ ${VERSION_ID} -eq "7" ]; then 
	OS_SETUP="wheezy"
	message_os_detected
    fi
    if [ ${VERSION_ID} -eq "8" ]; then 
	OS_SETUP="jessie"
	message_os_detected
    fi
    if [ ${VERSION_ID} -lt "7" ] || [ ${VERSION_ID} -gt "8" ]; then 
	echo "Not supported, only debian Jessie and Wheezy are supported (for now)."
	echo "Exiting now..."
	exit 1
    fi
    # install the all the "not" .conf files ( cron/logrotate/man/.sh ) 
    clamav_unofficial_sigs_base

    # detect new of existing config file
    detect_new_or_existing_config

    # reused old code/signatures and test for yara rules
    detect_malware_patrol_code
    detect_securite_info_signature

    detect_clamd_version_for_yara 

    # new install, debianize the config, user/group/service/socket/logpath/pid gets changed
    change_conf_2_${ID}

    debian_${OS_SETUP}_defaults

    # if your update-ing an existing install.
    if [ "${UPDATE}" -eq "1" ]; then 
	echo "Update-ing files re-use-ing old settings."
        import_old_settings_in_new_config_file
    fi
# end Debian
}

############################################################################################################
######### FUNCTIONS PER_OS END
############################################################################################################

############################################################################################################
######### CODE BEGIN, If done correct, its not needed to change anything below here.
############################################################################################################
DATE_NOW="$(date +%Y-%m-%d)"

run_as_root_or_sudo
detect_and_get_os_variables
check_packages_depends

detect_etc_clamav
get_latest_clamav_unofficial_sigs_github_zip

## Per OS install/updates
configure_for_os_${ID}
create_logrotate_per_os
create_cron_per_os

## make sure its config is set to yes.
user_config_done_yes

#restart_services_by_os_and_version
############################################################################################################
######### CODE ENDS HERE
############################################################################################################
