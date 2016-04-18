#!/bin/bash
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
################################################################################
# 
# Script updates can be found at: https://github.com/extremeshok/clamav-unofficial-sigs
#
# Originially based on: 
# Script provide by Bill Landry (unofficialsigs@gmail.com).
#
# License: BSD (Berkeley Software Distribution)
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#   ALL CONFIGURATION OPTIONS ARE LOCATED IN THE INCLUDED CONFIGURATION FILE 
#
################################################################################

################################################################################

######  #######    #     # ####### #######    ####### ######  ### ####### 
#     # #     #    ##    # #     #    #       #       #     #  #     #    
#     # #     #    # #   # #     #    #       #       #     #  #     #    
#     # #     #    #  #  # #     #    #       #####   #     #  #     #    
#     # #     #    #   # # #     #    #       #       #     #  #     #    
#     # #     #    #    ## #     #    #       #       #     #  #     #    
######  #######    #     # #######    #       ####### ######  ###    #    

################################################################################

# Detect to make sure the entire script is avilable, fail if the script is missing contents
if [ ! "` tail -1 "$0" | head -1 | cut -c1-7 `" == "exit \$?" ] ; then
	echo "FATAL ERROR: Script is incomplete, please redownload"
	exit 1
fi

################################################################################
# HELPER FUNCTIONS
################################################################################

# Function to support user config settings for applying file and directory access permissions.
function perms () {
	if [ -n "$clam_user" -a -n "$clam_group" ] ; then
		"${@:-}"
	fi
}

# Function to prompt a user if they should complete an action with Y or N
# usage: xshok_prompt_confirm
# if [ xshok_prompt_confirm ]; then
# xshok_prompt_confirm && echo "accepted"
# xshok_prompt_confirm && echo "yes" || echo "no"
xshok_prompt_confirm () {
  while true; do
    read -r -p "${1:-Are you sure? [y/N]} " response
    case $response in
      [yY]) echo ; return 0 ;;
      [nN]) echo ;return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac 
  done  
}


# Function to check if its a file, otherwise return false
xshok_is_file () { #"filepath"
	filepath=$1
  if [ -f "${filepath}" ]; then
  	return 0 ;
  else
  	return 1 ;	#not a file
  fi 
}

# Function to check if filepath is a subdir, otherwise return false
# Usage: xshok_is_subdir "filepath"
# xshok_is_subdir "/root/" - false
# xshok_is_subdir "/usr/local/etc" && echo "yes" - yes
xshok_is_subdir () { #filepath
	filepath=$(echo "$1" | sed 's:/*$::')
	if [ -d "$filepath" ] ; then
		res="${filepath//[^\/]}"
		if [ "${#res}" -gt 1 ] ; then
			return 0 ;
		else
			return 1 ;	#not a subdir
		fi
	else
		return 1 ;	#not a dir
	fi
}

# Function to create a dir and set the ownership
function xshok_mkdir_ownership () { #"path"
	mkdir -p "$1" 2>/dev/null
	perms chown -f $clam_user:$clam_group "$1"
}


# Function to handle comments with/out borders and logging.
# Usage:
# pretty_echo_and_log "one" 
# one
# pretty_echo_and_log "two" "-" 
# ---
# two
# ---
# pretty_echo_and_log "three" "=" "8"
# ========
# three
# ========
# pretty_echo_and_log "" "/\" "7"
# /\/\/\/\/\/\
#type: e = error, w= warning ""
function xshok_pretty_echo_and_log () { #"string" "repeating" "count" "type"
	# handle comments
	if [ "$comment_silence" = "no" ] ; then
		if [ "${#@}" = "1" ] ; then
			echo "$1"
		else
			myvar=""
			if [ -n "$3" ] ; then
				mycount="$3"
			else
				mycount="${#1}"
			fi
			for (( n = 0; n < $mycount; n++ )) ; do 
				myvar="$myvar$2"
			done
			if [ "$1" != "" ] ; then
				echo -e "$myvar\n$1\n$myvar"
			else  
				echo -e "$myvar"
			fi
		fi
	fi

	# handle logging
	if [ "$enable_log" == "yes" ] ; then
		if [ ! -e "$log_file_path/$log_file_name" ] ; then
				#xshok_mkdir_ownership "$log_file_path"
				mkdir -p "$log_file_path"
		    touch "$log_file_path/$log_file_name" 2>/dev/null
		    perms chown -f $clam_user:$clam_group $log_file_path/$log_file_name
		fi
		if [ ! -w "$log_file_path/$log_file_name" ] ; then
			echo "Warning: Logging Disabled, as file not writable: $log_file_path/$log_file_name"
			enable_log="no"
		else
			echo `date "+%b %d %T"` "$1" >> "$log_file_path/$log_file_name"
		fi 
	fi
}

# function to check if the $2 value is not null and does not start with -
function xshok_check_s2 () {
	if [ "$1" ]; then
		if [[ "$1" =~ ^-.* ]]; then
			xshok_pretty_echo_and_log "ERROR: Missing value for option or value begins with -" "="
			exit 1
		fi
	else
		xshok_pretty_echo_and_log "ERROR: Missing value for option" "="
		exit 1
	fi
}

# function to count array elements and output the total element count
# required due to compound array assignment
# Usage:
# array=("one" "two" "three")
# xshok_array_count $array
# 3
function xshok_array_count () {
	k_array=$@
	if [ -n "$k_array" ] ; then
		i="0"
		for k  in $k_array ; do
			let i=$i+1;
		done
		echo "$i"
	else
		echo "0"
	fi
}

#function to handle list of database files
function clamav_files () {
	echo "$clam_dbs/$db" >> "$current_tmp"
	if [ "$keep_db_backup" = "yes" ] ; then
		echo "$clam_dbs/$db-bak" >> "$current_tmp"
	fi
}

################################################################################
# ADDITIONAL PROGRAM FUNCTIONS
################################################################################


#generates a man config and installs it
function install_man (){
	echo ""
	echo "Generating man file for install...."
	
	#Use defined varibles or attempt to use default varibles

	if [ ! -e "$man_dir/$man_filename" ] ; then
		mkdir -p "$man_dir"
		touch "$man_dir/$man_filename" 2>/dev/null
	fi
	if [ ! -w "$man_dir/$man_filename" ] ; then
		echo "ERROR: man install aborted, as file not writable: $man_dir/$man_filename"
	else

BOLD="\fB"
REV=""
NORM="\fR"
manresult=`help_and_usage "man"`

#Our template..
	cat << EOF > "$man_dir/$man_filename"

.\" Manual page for eXtremeSHOK.com ClamAV Unofficial Signature Updater
.TH clamav-unofficial-sigs 8 "$script_version_date" "Version: $script_version" "SCRIPT COMMANDS"
.SH NAME
clamav-unofficial-sigs \- Download, test, and install third-party ClamAV signature databases.
.SH SYNOPSIS
.B clamav-unofficial-sigs
.RI [ options ]
.SH DESCRIPTION
\fBclamav-unofficial-sigs\fP provides a simple way to download, test, and update third-party signature databases provided by Sanesecurity, FOXHOLE, OITC, Scamnailer, BOFHLAND, CRDF, Porcupine, Securiteinfo, MalwarePatrol, Yara-Rules Project, etc. It will also generate and install cron, logrotate, and man files.
.SH UPDATES
Script updates can be found at: \fBhttps://github.com/extremeshok/clamav-unofficial-sigs\fP
.SH OPTIONS
This script follows the standard GNU command line syntax.
.LP
$manresult
.SH SEE ALSO
.BR clamd (8),
.BR clamscan (1)
.SH COPYRIGHT
Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
.TP
You are free to use, modify and distribute, however you may not remove this notice.
.SH LICENSE
BSD (Berkeley Software Distribution)
.SH BUGS
Report bugs to \fBhttps://github.com/extremeshok/clamav-unofficial-sigs\fP
.SH AUTHOR
Adrian Jon Kriel :: admin@extremeshok.com
Originially based on Script provide by Bill Landry


EOF

	fi 
	echo "Completed: man installed, as file: $man_dir/$man_filename"
}


#generates a logrotate config and installs it
function install_logrotate (){
	echo ""
	echo "Generating logrotate file for install...."
	
	#Use defined varibles or attempt to use default varibles

	if [ ! -n "$logrotate_user" ] ; then
		logrotate_user="$clam_user";
	fi
	if [ ! -n "$logrotate_group" ] ; then
		logrotate_group="$clam_group";
	fi
	if [ ! -n "$logrotate_log_file_full_path" ] ; then
		logrotate_log_file_full_path="$log_file_path/$log_file_name"
	fi


	if [ ! -e "$logrotate_dir/$logrotate_filename" ] ; then
		mkdir -p "$logrotate_dir"
		touch "$logrotate_dir/$logrotate_filename" 2>/dev/null
	fi
	if [ ! -w "$logrotate_dir/$logrotate_filename" ] ; then
		echo "ERROR: logrotate install aborted, as file not writable: $logrotate_dir/$logrotate_filename"
	else
#Our template..
	cat << EOF > "$logrotate_dir/$logrotate_filename"
# https://eXtremeSHOK.com ######################################################
# This file contains the logrotate settings for clamav-unofficial-sigs.sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
##################
#
# Script updates can be found at: https://github.com/extremeshok/clamav-unofficial-sigs
# 
# Originially based on: 
# Script provide by Bill Landry (unofficialsigs@gmail.com).
#
# License: BSD (Berkeley Software Distribution)
#
##################
# Automatically Generated: $(date)
##################
#
# This logrotate file will rotate the logs generated by the clamav-unofficial-sigs.sh
#
# To Adjust the logrotate values, edit your configs and run
# bash clamav-unofficial-sigs.sh --install-logrotate to generate a new file.

$logrotate_log_file_full_path {
  weekly
  rotate 4
  missingok
  notifempty
  compress
  create 0644 $logrotate_user $logrotate_group
}

EOF

	fi 
	echo "Completed: logrotate installed, as file: $logrotate_dir/$logrotate_filename"
}

#generates a cron config and installs it
function install_cron (){
	echo ""
	echo "Generating cron file for install...."
	
	#Use defined varibles or attempt to use default varibles
	if [ ! -n "$cron_minute" ] ; then
		cron_minute=$[ ( $RANDOM % 59 )  + 1 ];
	fi
	if [ ! -n "$cron_user" ] ; then
		cron_user="$clam_user";
	fi
	if [ ! -n "$cron_bash" ] ; then
		cron_bash=`which bash`
	fi	
	if [ ! -n "$cron_script_full_path" ] ; then
		#my script filename
		cron_script_name=$(basename -- "$0")
		#my script directory
		cron_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

		cron_script_dir=$(echo "$cron_script_dir" | sed 's:/*$::')
		cron_script_full_path="$cron_script_dir/$cron_script_name"
	fi

	

	if [ ! -e "$cron_dir/$cron_filename" ] ; then
		mkdir -p "$cron_dir"
		touch "$cron_dir/$cron_filename" 2>/dev/null
	fi
	if [ ! -w "$cron_dir/$cron_filename" ] ; then
		echo "ERROR: cron install aborted, as file not writable: $cron_dir/$cron_filename"
	else
#Our template..
	cat << EOF > "$cron_dir/$cron_filename"
# https://eXtremeSHOK.com ######################################################
# This file contains the cron settings for clamav-unofficial-sigs.sh
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
##################
#
# Script updates can be found at: https://github.com/extremeshok/clamav-unofficial-sigs
# 
# Originially based on: 
# Script provide by Bill Landry (unofficialsigs@gmail.com).
#
# License: BSD (Berkeley Software Distribution)
#
##################
# Automatically Generated: $(date)
##################
#
# This cron file will execute the clamav-unofficial-sigs.sh script that
# currently supports updating third-party signature databases provided
# by Sanesecurity, SecuriteInfo, MalwarePatrol, OITC, etc.
#
# The script is set to run hourly, at a random minute past the hour, and the 
# script itself is set to randomize the actual execution time between
# 60 - 600 seconds.  To Adjust the cron values, edit your configs and run
# bash clamav-unofficial-sigs.sh --install-cron to generate a new file.

$cron_minute * * * * $cron_user $cron_bash $cron_script_full_path > /dev/null

# https://eXtremeSHOK.com ######################################################

EOF

	fi 
	echo "Completed: cron installed, as file: $cron_dir/$cron_filename"
}


#decode a third-party signature either by signature name
function decode_third_party_signature_by_signature_name (){
	echo ""
	echo "Input a third-party signature name to decode (e.g: Sanesecurity.Junk.15248) or"
	echo "a hexadecimal encoded data string and press enter (do not include '.UNOFFICIAL'"
	echo "in the signature name nor add quote marks to any input string):"
	read input
	input=`echo "$input" | tr -d "'" | tr -d '"'`
	if `echo "$input" | grep "\." > /dev/null` ; then
		cd "$clam_dbs"
		sig=`grep "$input:" *.ndb`
		if [ -n "$sig" ] ; then
			db_file=`echo "$sig" | cut -d ':' -f1`
			echo "$input found in: $db_file"
			echo "$input signature decodes to:"
			echo "$sig" | cut -d ":" -f5 | perl -pe 's/([a-fA-F0-9]{2})|(\{[^}]*\}|\([^)]*\))/defined $2 ? $2 : chr(hex $1)/eg'
		else
			echo "Signature '$input' could not be found."
			echo "This script will only decode ClamAV 'UNOFFICIAL' third-Party,"
			echo "non-image based, signatures as found in the *.ndb databases."
		fi
	else
		echo "Here is the decoded hexadecimal input string:"
		echo "$input" | perl -pe 's/([a-fA-F0-9]{2})|(\{[^}]*\}|\([^)]*\))/defined $2 ? $2 : chr(hex $1)/eg'
	fi
}

#Hexadecimal encode an entire input string
function hexadecimal_encode_entire_input_string (){
	echo ""
	echo "Input the data string that you want to hexadecimal encode and then press enter.  Do not include"
	echo "any quotes around the string unless you want them included in the hexadecimal encoded output:"
	read input
	echo "Here is the hexadecimal encoded input string:"
	echo "$input" | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg'
}

#Hexadecimal encode a formatted input string
function hexadecimal_encode_formatted_input_string (){
	echo ""
	echo "Input a formated data string containing spacing fields '{}, (), *' that you want to hexadecimal"
	echo "encode, without encoding the spacing fields, and then press enter.  Do not include any quotes"
	echo "around the string unless you want them included in the hexadecimal encoded output:"
	read input
	echo "Here is the hexadecimal encoded input string:"
	echo "$input" | perl -pe 's/(\{[^}]*\}|\([^)]*\)|\*)|(.)/defined $1 ? $1 : sprintf("%02lx", ord $2)/eg'
}

#GPG verify a specific Sanesecurity database file
function gpg_verify_specific_sanesecurity_database_file () {
	echo ""
	db_file=`echo "$OPTARG" | awk -F '/' '{print $NF}'`
	if [ -r "$work_dir_sanesecurity/$db_file" ] ; then
		xshok_pretty_echo_and_log "GPG signature testing database file: $work_dir_sanesecurity/$db_file"

		if ! $gpg_bin --trust-model always -q --no-default-keyring --homedir $work_dir_gpg --keyring $work_dir_gpg/ss-keyring.gpg --verify $work_dir_sanesecurity/$db_file.sig $work_dir_sanesecurity/$db_file 2>/dev/null ; then
			$gpg_bin --always-trust -q --no-default-keyring --homedir $work_dir_gpg --keyring $work_dir_gpg/ss-keyring.gpg --verify $work_dir_sanesecurity/$db_file.sig $work_dir_sanesecurity/$db_file 2>/dev/null
		fi
	else
		xshok_pretty_echo_and_log "File '$db_file' cannot be found or is not a Sanesecurity database file."
		xshok_pretty_echo_and_log "Only the following Sanesecurity and OITC databases can be GPG signature tested:"
		xshok_pretty_echo_and_log "$sanesecurity_dbs"
	fi
}

#Output system and configuration information
function output_system_configuration_information () {
	echo ""
	echo "*** SCRIPT VERSION ***"
	echo "`basename $0` $script_version ($script_version_date)"
	echo "*** SYSTEM INFORMATION ***"
	$uname_bin -a
	echo "*** CLAMSCAN LOCATION & VERSION ***"
	echo "$clamscan_bin"
	$clamscan_bin --version | head -1
	echo "*** RSYNC LOCATION & VERSION ***"
	echo "$rsync_bin"
	$rsync_bin --version | head -1
	echo "*** CURL LOCATION & VERSION ***"
	echo "$curl_bin"
	$curl_bin --version | head -1
	echo "*** GPG LOCATION & VERSION ***"
	echo "$gpg_bin"
	$gpg_bin --version | head -1

	echo "*** SCRIPT WORKING DIRECTORY INFORMATION ***"
	ls -ld $work_dir

	ls -lR $work_dir | grep -v total

	echo "*** CLAMAV DIRECTORY INFORMATION ***"
	ls -ld $clam_dbs
	echo "---"
	ls -l $clam_dbs | grep -v total

	echo "*** SCRIPT CONFIGURATION SETTINGS ***"
	if [ "$custom_config" != "no" ] ; then
		if [ -d "$custom_config" ]; then
			# Assign the custom config dir and remove trailing / (removes / and //)
			echo "Custom Configuration Directory: $config_dir"
		else
			echo "Custom Configuration File: $custom_config"
		fi
	else
		echo "Configuration Directory: $config_dir"
	fi
}

#Make a signature database from an ascii file
function make_signature_database_from_ascii_file () {
	echo ""
	echo "
	The '-m' script flag provides a way to create a ClamAV hexadecimal signature database (*.ndb) file
	from a list of data strings stored in a clear-text ascii file, with one data string entry per line.

	- Hexadecimal encoding can be either 'full' or 'formatted' on a per line basis:

	Full line encoding should be used if there are no formatted spacing entries [{}, (), *]
	included on the line.  Prefix unformatted lines with: '-:' (no quote marks).

	Example:

	-:This signature contains no formatted spacing fields

	Encodes to:

	54686973207369676e617475726520636f6e7461696e73206e6f20666f726d61747465642073706163696e67206669656c6473

	Formatted line encoding should be used if there are user added spacing entries [{}, (), *]
	included on the line.  Prefix formatted lines with '=:' (no quote marks).

	Example:

	=:This signature{-10}contains several(25|26|27)formatted spacing*fields

	Encodes to:

	54686973207369676e6174757265{-10}636f6e7461696e73207365766572616c(25|26|27)666f726d61747465642073706163696e67*6669656c6473

	Use 'full' encoding if you want to encode everything on the line [including {}, (), *] and 'formatted'
	encoding if you want to encode everything on the line except the formatted character spacing fields.

	The prefixes ('-:' and '=:') will be stripped from the line before hexadecimal encoding is done.
	If no prefix is found at the beginning of the line, full line encoding will be done (default).

	- It is assumed that the signatures will be created for email scanning purposes, thus the '4'
	target type is used and full file scanning is enabled (see ClamAV signatures.pdf for details).

	- Line numbering will be done automatically by the script.
	" | command sed 's/^          //g'
	echo -n "Do you wish to continue? "
	if [ `xshok_prompt_confirm` ] ; then

		echo -n "Enter the source file as /path/filename: "
		read source
		if [ -r "$source" ] ; then
			source_file=`basename "$source"`

			echo "What signature prefix would you like to use?  For example: 'Phish.Domains'"
			echo "will create signatures that looks like: 'Phish.Domains.1:4:*:HexSigHere'"

			echo -n "Enter signature prefix: "
			read prefix
			path_file=`echo "$source" | cut -d "." -f-1 | command sed 's/$/.ndb/'`
			db_file=`basename $path_file`
			rm -f "$path_file"
			total=`wc -l "$source" | cut -d " " -f1`
			line_num=1

			cat "$source" | while read line ; do
				line_prefix=`echo "$line" | awk -F ':' '{print $1}'`
				if [ "$line_prefix" = "-" ] ; then
					echo "$line" | cut -d ":" -f2- | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg' | command sed "s/^/$prefix\.$line_num:4:\*:/" >> "$path_file"
				elif [ "$line_prefix" = "=" ] ; then
					echo "$line" | cut -d ":" -f2- | perl -pe 's/(\{[^}]*\}|\([^)]*\)|\*)|(.)/defined $1 ? $1 : sprintf("%02lx", ord $2)/eg' | command sed "s/^/$prefix\.$line_num:4:\*:/" >> "$path_file"
				else
					echo "$line" | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg' | command sed "s/^/$prefix\.$line_num:4:\*:/" >> "$path_file"
				fi
				printf "Hexadecimal encoding $source_file line: $line_num of $total\r"
				line_num=$(($line_num + 1))
			done
		else
			echo "Source file not found, exiting..."
			exit
		fi


		echo "Signature database file created at: $path_file"
		if $clamscan_bin --quiet -d "$path_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null ; then

			echo "Clamscan reports database integrity tested good."

			echo -n "Would you like to move '$db_file' into '$clam_dbs' and reload databases?"
			if [ `xshok_prompt_confirm` ] ; then
				if ! cmp -s "$path_file" "$clam_dbs/$db_file" ; then
					if $rsync_bin -pcqt "$path_file" "$clam_dbs" ; then
						perms chown -f $clam_user:$clam_group "$clam_dbs/$db_file"
						perms chmod -f 0644 "$clam_dbs/$db_file"
						if [ "$selinux_fixes" == "yes" ] ; then
							restorecon "$clam_dbs/$db_file"
						fi
						$clamd_restart_opt

						echo "Signature database '$db_file' was successfully implemented and ClamD databases reloaded."
					else

						echo "Failed to add/update '$db_file', ClamD database not reloaded."
					fi
				else

					echo "Database '$db_file' has not changed - skipping"
				fi
			else

				echo "No action taken."
			fi
		else

			echo "Clamscan reports that '$db_file' signature database integrity tested bad."
		fi
	fi
}

#Remove the clamav-unofficial-sigs script
function remove_script () {
	echo ""
	if [ -n "$pkg_mgr" -a -n "$pkg_rm" ] ; then
		echo "  This script (clamav-unofficial-sigs) was installed on the system"
		echo "  via '$pkg_mgr', use '$pkg_rm' to remove the script"
		echo "  and all of its associated files and databases from the system."

	else
		echo "  Are you sure you want to remove the clamav-unofficial-sigs script and all of its"
		echo -n "  associated files, third-party databases, and work directories from the system?"
		if [ `xshok_prompt_confirm` ] ; then
			if [ -r "$work_dir_work_configs/purge.txt" ] ; then

				for file in `cat $work_dir_work_configs/purge.txt` ; do
					xshok_is_file "$file" && rm -f -- "$file"
					echo "     Removed file: $file"
				done
				cron_file_full_path="$cron_dir/$cron_filename"
				if [ -r "$cron_file_full_path" ] ; then
					xshok_is_file "$cron_file_full_path" && rm -f "$cron_file_full_path"
					echo "     Removed file: $cron_file_full_path"
				fi
				logrotate_file_full_path="$logrotate_dir/$logrotate_filename"
				if [ -r "$logrotate_file_full_path" ] ; then
					xshok_is_file "$logrotate_file_full_path" && rm -f "$logrotate_file_full_path"
					echo "     Removed file: $logrotate_file_full_path"
				fi
				man_file_full_path="$man_dir/$man_filename"
				if [ -r "$man_file_full_path" ] ; then
					xshok_is_file "$man_file_full_path" && rm -f "$man_file_full_path"
					echo "     Removed file: $man_file_full_path"
				fi
				
				#rather keep the configs
				#rm -f -- "$default_config" && echo "     Removed file: $default_config"
				#rm -f -- "$0" && echo "     Removed file: $0"
				xshok_is_subdir "$work_dir" && rm -rf -- "$work_dir" && echo "     Removed script working directories: $work_dir"

				echo "  The clamav-unofficial-sigs script and all of its associated files, third-party"
				echo "  databases, and work directories have been successfully removed from the system."

			else
				echo "  Cannot locate 'purge.txt' file in $work_dir_work_configs."
				echo "  Files and signature database will need to be removed manually."

			fi
		else
			help_and_usage
		fi
	fi
}

#Clamscan integrity test a specific database file
function clamscan_integrity_test_specific_database_file (){
	echo ""
	input=`echo "$OPTARG" | awk -F '/' '{print $NF}'`
	db_file=`find $work_dir -name $input`
	if [ -r "$db_file" ] ; then
		echo "Clamscan integrity testing: $db_file"

		if $clamscan_bin --quiet -d "$db_file" "$work_dir_work_configs/scan-test.txt" ; then
			echo "Clamscan reports that '$input' database integrity tested GOOD"
		fi
	else
		echo "File '$input' cannot be found."
		echo "Here is a list of third-party databases that can be clamscan integrity tested:"

		echo "Sanesecurity $sanesecurity_dbs""SecuriteInfo $securiteinfo_dbs""MalwarePatrol $malwarepatrol_dbs"
		echo "Check the file name and try again..."
	fi 
}

#output names of any third-party signatures that triggered during the HAM directory scan
function output_signatures_triggered_during_ham_directory_scan () {
	echo ""
	if [ -n "$ham_dir" ] ; then
		if [ -r "$work_dir_work_configs/whitelist.hex" ] ; then
			echo "The following third-party signatures triggered hits during the HAM Directory scan:"

			grep -h -f "$work_dir_work_configs/whitelist.hex" "$work_dir"/*/*.ndb | cut -d ":" -f1
		else
			echo "No third-party signatures have triggered hits during the HAM Directory scan."
		fi
	else
		echo "Ham directory scanning is not currently enabled in the script's configuration file."
	fi
}

#Adds a signature whitelist entry in the newer ClamAV IGN2 format
function add_signature_whitelist_entry () {
	echo ""
	echo "Input a third-party signature name that you wish to whitelist due to false-positives"
	echo "and press enter (do not include '.UNOFFICIAL' in the signature name nor add quote"
	echo "marks to the input string):"

	read input
	if [ -n "$input" ] ; then
		cd "$clam_dbs"
		input=`echo "$input" | tr -d "'" | tr -d '"'`
		sig_full=`grep -H "$input" *.*db`
		sig_name=`echo "$sig_full" | cut -d ":" -f2`
		if [ -n "$sig_name" ] ; then
			if ! grep "$sig_name" my-whitelist.ign2 > /dev/null 2>&1 ; then
				cp -f my-whitelist.ign2 "$work_dir_work_configs" 2>/dev/null
				echo "$sig_name" >> "$work_dir_work_configs/my-whitelist.ign2"
				echo "$sig_full" >> "$work_dir_work_configs/tracker.txt"
				if $clamscan_bin --quiet -d "$work_dir_work_configs/my-whitelist.ign2" "$work_dir_work_configs/scan-test.txt" ; then
					if $rsync_bin -pcqt $work_dir_work_configs/my-whitelist.ign2 $clam_dbs ; then
						perms chown -f $clam_user:$clam_group my-whitelist.ign2

						if [ ! -s "$work_dir_work_configs/monitor-ign.txt" ] ; then 
							# Create "monitor-ign.txt" file for clamscan database integrity testing.
							echo "This is the monitor ignore file..." > "$work_dir_work_configs/monitor-ign.txt"
						fi

						perms chmod -f 0644 my-whitelist.ign2 "$work_dir_work_configs/monitor-ign.txt"
						if [ "$selinux_fixes" == "yes" ] ; then
							restorecon "$clam_dbs/local.ign"
						fi
						clamscan_reload_dbs

						echo "Signature '$input' has been added to my-whitelist.ign2 and"
						echo "all databases have been reloaded.  The script will track any changes"
						echo "to the offending signature and will automatically remove it if the"
						echo "signature is modified or removed from the third-party database."
					else

						echo "Failed to successfully update my-whitelist.ign2 file - SKIPPING."
					fi
				else

					echo "Clamscan reports my-whitelist.ign2 database integrity is bad - SKIPPING."
				fi
			else

				echo "Signature '$input' already exists in my-whitelist.ign2 - no action taken."
			fi
		else

			echo "Signature '$input' could not be found."

			echo "This script will only create a whitelise entry in my-whitelist.ign2 for ClamAV"
			echo "'UNOFFICIAL' third-Party signatures as found in the *.ndb *.hdb *.db databases."
		fi
	else
		echo "No input detected - no action taken."
	fi
}

#Clamscan reload database
function clamscan_reload_dbs (){
	# Reload all clamd databases if updates detected and $reload_dbs" is set to "yes"
	if [ "$reload_dbs" = "yes" ] ; then
		if [ "$do_clamd_reload" != "0" ] ; then
			if [ "$do_clamd_reload" = "1" ] ; then
				xshok_pretty_echo_and_log "Update(s) detected, reloading ClamAV databases" "="
			elif [ "$do_clamd_reload" = "2" ] ; then
				xshok_pretty_echo_and_log "Database removal(s) detected, reloading ClamAV databases" "="
			elif [ "$do_clamd_reload" = "3" ] ; then      
				xshok_pretty_echo_and_log "File 'local.ign' has changed, reloading ClamAV databases" "="
			elif [ "$do_clamd_reload" = "4" ] ; then      
				xshok_pretty_echo_and_log "File 'my-whitelist.ign2' has changed, reloading ClamAV databases" "="
			else
				xshok_pretty_echo_and_log "Update(s) detected, reloading ClamAV databases" "="
			fi

			if [[ `$clamd_reload_opt 2>&1` =~ "ERROR" ]] ; then
				xshok_pretty_echo_and_log "ERROR: Failed to reload, trying again" "-"
				if [ -r "$clamd_pid" ] ; then
					mypid=`cat $clamd_pid`
					kill -USR2 $mypid
					if [ $? -eq  0 ] ; then
						xshok_pretty_echo_and_log "ClamAV databases Reloaded" "="
					else
						xshok_pretty_echo_and_log "ERROR: Failed to reload, forcing clamd to restart" "-"
						if [ -z "$clamd_restart_opt" ] ; then      
							xshok_pretty_echo_and_log "WARNING: Check the script's configuration file, 'reload_dbs' enabled but no 'clamd_restart_opt'" "*"
						else
							$clamd_restart_opt
							xshok_pretty_echo_and_log "ClamAV Restarted" "="
						fi
					fi
				else
					xshok_pretty_echo_and_log "ERROR: Failed to reload, forcing clamd to restart" "="
					if [ -z "$clamd_restart_opt" ] ; then      
						xshok_pretty_echo_and_log "WARNING: Check the script's configuration file, 'reload_dbs' enabled but no 'clamd_restart_opt'" "*"
					else
						$clamd_restart_opt
						xshok_pretty_echo_and_log "ClamAV Restarted" "="
					fi
				fi   
			else
				xshok_pretty_echo_and_log "ClamAV databases Reloaded" "="
			fi
		else   
			xshok_pretty_echo_and_log "No updates detected, ClamAV databases were not reloaded" "="
		fi
	else      
		xshok_pretty_echo_and_log "Database reload has been disabled in the configuration file" "="  
	fi

}

# If ClamD status check is enabled ("clamd_socket" variable is uncommented
# and the socket path is correctly specified in "User Edit" section above),
# then test to see if clamd is running or not.
function check_clamav () {
	if [ -n "$clamd_socket" ] ; then
		if [ -S "$clamd_socket" ] ; then
			if [ "`perl -e 'use IO::Socket::UNIX; print $IO::Socket::UNIX::VERSION,"\n"' 2>/dev/null`" ] ; then
				io_socket1=1
				if [ "`perl -MIO::Socket::UNIX -we '$s = IO::Socket::UNIX->new(shift); $s->print("PING"); print $s->getline; $s->close' "$clamd_socket" 2>/dev/null`" = "PONG" ] ; then
					io_socket2=1
					xshok_pretty_echo_and_log "ClamD is running" "="
				fi
			else
				socat="`which socat 2>/dev/null`"
				if [ -n "$socat" -a -x "$socat" ] ; then
					socket_cat1=1
					if [ "`(echo "PING"; sleep 1;) | socat - "$clamd_socket" 2>/dev/null`" = "PONG" ] ; then
						socket_cat2=1
						xshok_pretty_echo_and_log "ClamD is running" "="
					fi
				fi
			fi
			if [ -z "$io_socket1" -a -z "$socket_cat1" ] ; then
				xshok_pretty_echo_and_log "WARNING: socat or perl module 'IO::Socket::UNIX' not found, cannot test if ClamD is running" "*"
			else
				if [ -z "$io_socket2" -a -z "$socket_cat2" ] ; then

					xshok_pretty_echo_and_log "ALERT: CLAMD IS NOT RUNNING!" "="
					if [ -n "$clamd_restart_opt" ] ; then
						xshok_pretty_echo_and_log "Attempting to start ClamD..." "-"
						if [ -n "$io_socket1" ] ; then
							$clamd_restart_opt > /dev/null && sleep 5
							if [ "`perl -MIO::Socket::UNIX -we '$s = IO::Socket::UNIX->new(shift); $s->print("PING"); print $s->getline; $s->close' "$clamd_socket" 2>/dev/null`" = "PONG" ] ; then
								xshok_pretty_echo_and_log "ClamD was successfully started" "="
							else
								xshok_pretty_echo_and_log "ERROR: CLAMD FAILED TO START" "="
								exit 1
							fi
						else
							if [ -n "$socket_cat1" ] ; then
								$clamd_restart_opt > /dev/null && sleep 5
								if [ "`(echo "PING"; sleep 1;) | socat - "$clamd_socket" 2>/dev/null`" = "PONG" ] ; then
									xshok_pretty_echo_and_log "ClamD was successfully started" "="
								else
									xshok_pretty_echo_and_log "ERROR: CLAMD FAILED TO START" "="
									exit 1
								fi
							fi
						fi
					fi
				fi
			fi
		else
			xshok_pretty_echo_and_log "WARNING: $clamd_socket is not a usable socket" "*"
		fi
	else
		xshok_pretty_echo_and_log "WARNING: clamd_socket is not defined in the configuration file" "*"
	fi
}

#function to check for a new version
function check_new_version () {
	latest_version=`curl https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/master/clamav-unofficial-sigs.sh 2> /dev/null | grep  "script""_version=" | cut -d\" -f2`
	if [ "$latest_version" ] ; then
		if [ ! "$latest_version" == "$script_version" ] ; then
			xshok_pretty_echo_and_log "New version : v$latest_version @ https://github.com/extremeshok/clamav-unofficial-sigs" "-"
		fi
	fi
}

#function for help and usage
##usage: 
# help_and_usage "1" - enables the man output formatting
# help_and_usage - normal help output formatting
function help_and_usage () {

	if [ "$1" ]; then
		#option_format_start
		ofs="\fB"
		#option_format_end
		ofe="\fR"
		#option_format_blankline
		ofb=".TP"
		#option_format_tab_line
		oft=" "
	else
		#option_format_start
		ofs="${BOLD}"
		#option_format_end
		ofe="${NORM}\t"
		#option_format_blankline
		ofb="\n"
		#option_format_tab_line
		oft="\n\t"
	fi

helpcontents=`cat << EOF
$ofs Usage: $(basename $0) $ofe [OPTION] [PATH|FILE]
$ofb
$ofs -c, --config $ofe Use a specific configuration file or directory $oft eg: '-c /your/dir' or ' -c /your/file.name'  $oft Note: If a directory is specified the directory must contain atleast:  $oft master.conf, os.conf or user.conf $oft Default Directory: $config_dir
$ofb 
$ofs -F, --force $ofe Force all databases to be downloaded, could cause ip to be blocked
$ofb 
$ofs -h, --help $ofe Display this script's help and usage information
$ofb 
$ofs -V, --version $ofe Output script version and date information
$ofb 
$ofs -v, --verbose $ofe Be verbose, enabled when not run under cron
$ofb 
$ofs -s, --silence $ofe Only output error messages, enabled when run under cron
$ofb 
$ofs -d, --decode-sig $ofe Decode a third-party signature either by signature name $oft (eg: Sanesecurity.Junk.15248) or hexadecimal string. $oft This flag will 'NOT' decode image signatures
$ofb 
$ofs -e, --encode-string $ofe Hexadecimal encode an entire input string that can $oft be used in any '*.ndb' signature database file
$ofb 
$ofs -f, --encode-formatted $ofe Hexadecimal encode a formatted input string containing $oft signature spacing fields '{}, (), *', without encoding $oft the spacing fields, so that the encoded signature $oft can be used in any '*.ndb' signature database file
$ofb 
$ofs -g, --gpg-verify $ofe GPG verify a specific Sanesecurity database file $oft eg: '-g filename.ext' (do not include file path)
$ofb 
$ofs -i, --information $ofe Output system and configuration information for $oft viewing or possible debugging purposes
$ofb 
$ofs -m, --make-database $ofe Make a signature database from an ascii file containing $oft data strings, with one data string per line.  Additional $oft information is provided when using this flag
$ofb 
$ofs -r, --remove-script $ofe Remove the clamav-unofficial-sigs script and all of $oft its associated files and databases from the system
$ofb 
$ofs -t, --test-database $ofe Clamscan integrity test a specific database file $oft eg: '-s filename.ext' (do not include file path)
$ofb 
$ofs -o, --output-triggered $ofe If HAM directory scanning is enabled in the script's $oft configuration file, then output names of any third-party $oft signatures that triggered during the HAM directory scan
$ofb 
$ofs -w, --whitelist $ofe Adds a signature whitelist entry in the newer ClamAV IGN2 $oft format to 'my-whitelist.ign2' in order to temporarily resolve $oft a false-positive issue with a specific third-party signature. $oft Script added whitelist entries will automatically be removed $oft if the original signature is either modified or removed from $oft the third-party signature database
$ofb 
$ofs --check-clamav $ofe If ClamD status check is enabled and the socket path is correctly $oft specifiedthen test to see if clamd is running or not
$ofb 
$ofs --install-cron $ofe Install and generate the cron file, autodetects the values $oft based on your config files
$ofb 
$ofs --install-logrotate $ofe Install and generate the logrotate file, autodetects the $oft values based on your config files
$ofb 
$ofs --install-man $ofe Install and generate the man file, autodetects the $oft values based on your config files
$ofb 
EOF
	` #this is very important...

	if [ "$1" ]; then
		echo "${helpcontents//-/\\-}"
	else
		echo -e "$helpcontents"
	fi



}

################################################################################
# MAIN PROGRAM
################################################################################

#Script Info
script_version="5.2.1"
script_version_date="16 April 2016"
minimum_required_config_version="62"
minimum_yara_clamav_version="0.99"

#default config files
config_dir="/etc/clamav-unofficial-sigs"
config_files=("$config_dir/master.conf" "$config_dir/os.conf" "$config_dir/user.conf")

#Initialise 
config_version="0"
do_clamd_reload="0"
comment_silence="no"
enable_logging="no"
forced_updates="no"
enable_log="no"
custom_config="no"
we_have_a_config="0"

#Default Binaries & Commands
clamd_reload_opt="clamdscan --reload"  
clamscan_bin=`which clamscan`
rsync_bin=`which rsync`
curl_bin=`which curl`
gpg_bin=`which gpg`

#Detect if terminal
if [ -t 1 ] ; then
	#Set fonts
	##Usage: echo "${BOLD}-a${NORM}"
	BOLD=`tput bold`
	REV=`tput smso`
	NORM=`tput sgr0`
	#Verbose
	force_verbose="yes"
else
	#Null Fonts
	BOLD=''
	REV=''
	NORM=''
	#silence
	force_verbose="no"
fi


# Generic command line options
while true ; do
	case "$1" in
		-c | --config ) xshok_check_s2 $2; custom_config="$2"; shift 2; break ;;
		-F | --force ) force_updates="yes"; shift 1; break ;;
		-v | --verbose ) force_verbose="yes"; shift 1; break ;;
		-s | --silence ) force_verbose="no"; shift 1; break ;;
		* ) break ;;
	esac
done

#Set the verbosity
if [ "$force_verbose" == "yes" ] ; then
	#verbose
	curl_silence="no"
	rsync_silence="no"
	gpg_silence="no"
	comment_silence="no"
else
	#silence
	curl_silence="yes"
	rsync_silence="yes"
	gpg_silence="yes"
	comment_silence="yes"
fi

xshok_pretty_echo_and_log "" "#" "80"
xshok_pretty_echo_and_log " eXtremeSHOK.com ClamAV Unofficial Signature Updater"
xshok_pretty_echo_and_log " Version: v$script_version ($script_version_date)"
xshok_pretty_echo_and_log " Required Configuration Version: v$minimum_required_config_version"
xshok_pretty_echo_and_log " Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com"
xshok_pretty_echo_and_log "" "#" "80"

# Generic command line options
while true ; do
	case "$1" in
		-h | --help ) help_and_usage; exit; break ;;
		-V | --version ) exit; break ;;
		* ) break ;;
	esac
done

## CONFIG LOADING AND ERROR CHECKING ##############################################
if [ "$custom_config" != "no" ] ; then
	if [ -d "$custom_config" ]; then
		# Assign the custom config dir and remove trailing / (removes / and //)
		config_dir=$(echo "$custom_config" | sed 's:/*$::')
		config_files=("$config_dir/master.conf" "$config_dir/os.conf" "$config_dir/user.conf")
	else
		config_files=("$custom_config")
	fi
fi

for config_file in "${config_files[@]}" ; do
	if [ -r "$config_file" ] ; then #exists and readable
		we_have_a_config="1"
		#config stripping
		xshok_pretty_echo_and_log "Loading config: $config_file" "="

		# delete lines beginning with #
		# delete from ' #' to end of the line
		# delete from '# ' to end of the line
		# delete both trailing and leading whitespace
		# delete all empty lines
		clean_config=`command sed -e '/^#.*/d' -e 's/[[:space:]]#.*//' -e 's/#[[:space:]].*//' -e 's/^[ \t]*//;s/[ \t]*$//' -e '/^\s*$/d' "$config_file"`

		### config error checking
		# check "" are an even number
		config_check="${clean_config//[^\"]}"
		if [ $(( ${#config_check} % 2)) -eq 1 ] ; then 
			xshok_pretty_echo_and_log "ERROR: Your configuration has errors, every \" requires a closing \"" "="     
			exit 1
		fi

		# check there is an = for every set of "" #optional whitespace \s* between = and "
		config_check_vars=`echo "$clean_config" | grep -o '=\s*\"' | wc -l`
		if [ $(( ${#config_check} / 2)) -ne "$config_check_vars" ] ; then 
			xshok_pretty_echo_and_log "ERROR: Your configuration has errors, every = requires a pair of \"\"" "="    
			exit 1
		fi

		#config loading
		for i in "${clean_config[@]}" ; do
			eval $(echo ${i} | command sed -e 's/[[:space:]]*$//')
		done
	fi
done

# Assign the log_file_path earlier and remove trailing / (removes / and //)
log_file_path=$(echo "$log_file_path" | sed 's:/*$::')
#Only start logging once all the configs have been loaded
if [ "$logging_enabled" == "yes" ] ; then
	enable_log="yes"
fi

## Make sure we have a readable config file
if [ "$we_have_a_config" == "0" ] ; then
	xshok_pretty_echo_and_log "ERROR: Config file/s could NOT be read/loaded" "="
	exit 1
fi

#prevent some issues with an incomplete or only a user.conf being loaded
if [ $config_version  == "0" ] ; then
	xshok_pretty_echo_and_log "ERROR: Config file is missing important contents of the master.conf" "="
	xshok_pretty_echo_and_log "Note: Possible fix would be to point the script to the dir with the configs"
	exit 1
fi

#config version validation
if [ $config_version -lt $minimum_required_config_version ] ; then
	xshok_pretty_echo_and_log "ERROR: Your config version $config_version is not compatible with the min required version $minimum_required_config_version" "="
	exit 1
fi

# Check to see if the script's "USER CONFIGURATION FILE" has been completed.
if [ "$user_configuration_complete" != "yes" ] ; then
	xshok_pretty_echo_and_log "WARNING: SCRIPT CONFIGURATION HAS NOT BEEN COMPLETED" "*"
	xshok_pretty_echo_and_log "Please review the script configuration files."
	exit 1
fi

# Assign the directories and remove trailing / (removes / and //)
work_dir=$(echo "$work_dir" | sed 's:/*$::')

#Allow overriding of all the individual workdirs, this is mainly to aid package maintainers
if [ ! -n "$work_dir_sanesecurity" ] ; then
	work_dir_sanesecurity=$(echo "$work_dir/$sanesecurity_dir" | sed 's:/*$::')
else
	work_dir_sanesecurity=$(echo "$work_dir_sanesecurity" | sed 's:/*$::')
fi
if [ ! -n "$work_dir_securiteinfo" ] ; then
	work_dir_securiteinfo=$(echo "$work_dir/$securiteinfo_dir" | sed 's:/*$::')
else
	work_dir_securiteinfo=$(echo "$work_dir_securiteinfo" | sed 's:/*$::')
fi
if [ ! -n "$work_dir_linuxmalwaredetect" ] ; then
	work_dir_linuxmalwaredetect=$(echo "$work_dir/$linuxmalwaredetect_dir" | sed 's:/*$::')
else
	work_dir_linuxmalwaredetect=$(echo "$work_dir_linuxmalwaredetect" | sed 's:/*$::')
fi
if [ ! -n "$work_dir_malwarepatrol" ] ; then
	work_dir_malwarepatrol=$(echo "$work_dir/$malwarepatrol_dir" | sed 's:/*$::')
else
	work_dir_malwarepatrol=$(echo "$work_dir_malwarepatrol" | sed 's:/*$::')
fi
if [ ! -n "$work_dir_yararulesproject" ] ; then
	work_dir_yararulesproject=$(echo "$work_dir/$yararulesproject_dir" | sed 's:/*$::')
else
	work_dir_yararulesproject=$(echo "$work_dir_yararulesproject" | sed 's:/*$::')
fi
if [ ! -n "$work_dir_add" ] ; then
	work_dir_add=$(echo "$work_dir/$add_dir" | sed 's:/*$::')
else
	work_dir_add=$(echo "$work_dir_add" | sed 's:/*$::')
fi
if [ ! -n "$work_dir_work_configs" ] ; then
	work_dir_work_configs=$(echo "$work_dir/$work_dir_configs" | sed 's:/*$::')
else
	work_dir_work_configs=$(echo "$work_dir_work_configs" | sed 's:/*$::')
fi
if [ ! -n "$work_dir_gpg" ] ; then
	work_dir_gpg=$(echo "$work_dir/$gpg_dir" | sed 's:/*$::')
else
	work_dir_gpg=$(echo "$work_dir_gpg" | sed 's:/*$::')
fi

#	Assign defaults if not defined
if [ ! -n "$cron_dir" ] ; then
	cron_dir="/etc/cron.d"
fi
cron_dir=$(echo "$cron_dir" | sed 's:/*$::')
if [ ! -n "$cron_filename" ] ; then
	cron_filename="clamav-unofficial-sigs"
fi
if [ ! -n "$logrotate_dir" ] ; then
	logrotate_dir="/etc/logrotate.d"
fi
logrotate_dir=$(echo "$logrotate_dir" | sed 's:/*$::')
if [ ! -n "$logrotate_filename" ] ; then
	logrotate_filename="clamav-unofficial-sigs"
fi	
if [ ! -n "$man_dir" ] ; then
	man_dir="/usr/share/man/man8"
fi
man_dir=$(echo "$man_dir" | sed 's:/*$::')
if [ ! -n "$man_filename" ] ; then
	man_filename="clamav-unofficial-sigs.8"
fi	
if [ ! -n "$man_log_file_full_path" ] ; then
	man_log_file_full_path="$log_file_path/$log_file_name"
fi

### SANITY checks
#Check default Binaries & Commands are defined
if [ "$clamd_reload_opt" == "" ] ; then
	xshok_pretty_echo_and_log "ERROR: Missing clamd_reload_opt" "="
	exit 1
fi
if [ "$clamscan_bin" == "" ] ; then
	xshok_pretty_echo_and_log "ERROR: clamscan binary (clamscan_bin) not found" "="
	exit 1
fi
if [ "$rsync_bin" == "" ] ; then
	xshok_pretty_echo_and_log "ERROR: rsync binary (rsync_bin) not found" "="
	exit 1
fi
if [ "$curl_bin" == "" ] ; then
	xshok_pretty_echo_and_log "ERROR: curl binary (curl_bin) not found" "="
	exit 1
fi
if [ "$gpg_bin" == "" ] ; then
	xshok_pretty_echo_and_log "ERROR: gpg binary (gpg_bin) not found" "="
	exit 1
fi
#Check default directories are defined
if [ "$work_dir" == "" ] ; then
	xshok_pretty_echo_and_log "ERROR: working directory (work_dir) not defined" "="
	exit 1
fi

# Reset the update timers to force a full update.
if [ "$force_updates" == "yes" ] ; then
	xshok_pretty_echo_and_log "Force Updates: enabled"     
	securiteinfo_update_hours="0"
	linuxmalwaredetect_update_hours="0"
	malwarepatrol_update_hours="0"
	yararulesproject_update_hours="0"
fi


################################################################################
# MAIN LOGIC
################################################################################

while true; do
	case "$1" in
		-d | --decode-sig ) decode_third_party_signature_by_signature_name; exit; break ;;
		-e | --encode-string ) hexadecimal_encode_entire_input_string; exit; break ;;
		-f | --encode-formatted ) hexadecimal_encode_formatted_input_string; exit; break ;;
		-g | --gpg-verify ) gpg_verify_specific_sanesecurity_database_file; exit; break ;;
		-i | --information ) output_system_configuration_information; exit; break ;;
		-m | --make-database ) make_signature_database_from_ascii_file; exit; break ;;
		-r | --remove-script ) remove_script; exit; break ;;
		-t | --test-database ) clamscan_integrity_test_specific_database_file; exit; break ;;
		-o | --output-triggered ) output_signatures_triggered_during_ham_directory_scan; exit; break ;;
		-w | --whitelist ) add_signature_whitelist_entry; exit; break ;;
		--check-clamav ) check_clamav; exit; break ;;
		--install-cron ) install_cron; exit; break ;;
		--install-logrotate ) install_logrotate; exit; break ;;
		--install-man ) install_man; exit; break ;;
		* ) break ;;
	esac
done

# Check yararule support is available
if [ "$enable_yararules" == "yes" ] ; then
	current_clamav_version=`$clamscan_bin -V | cut -d " " -f2 | cut -d "/" -f1 | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'`
	minimum_yara_clamav_version=`echo "$minimum_yara_clamav_version" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'`
	#Check current clamav version against the minimum required version for yara support
	if [ $current_clamav_version -lt $minimum_yara_clamav_version ]; then #older
		yararulesproject_enabled="no"
		enable_yararules="no"
		xshok_pretty_echo_and_log "Notice: Yararules Disabled due to clamav being older than the minimum required version"
	fi
else
	yararulesproject_enabled="no"
	enable_yararules="no"
fi

#rebuild the database if we need to remove yara rules from them due to yararules being disabled
if [ "$enable_yararules" == "no" ] ; then #yararules are disabled
	if [ "$sanesecurity_enabled" == "yes" ] ; then
		if [ -n "$sanesecurity_dbs" ] ; then
			if [ `xshok_array_count "$sanesecurity_dbs"` -ge "1" ] ; then
				new_sanesecurity_dbs=""
				for db_name in $sanesecurity_dbs ; do
					if [[ ! "$db_name" =~ ".yar" ]] ; then # if it's the value you want to delete
				 		new_sanesecurity_dbs="$new_sanesecurity_dbs$db_name "
					fi
				done
				sanesecurity_dbs="$new_sanesecurity_dbs"
			fi
		fi
	fi
	if [ "$securiteinfo_enabled" == "yes" ] ; then
		if [ -n "$securiteinfo_dbs" ] ; then
			if [ `xshok_array_count "$securiteinfo_dbs"` -ge "1" ] ; then
				new_securiteinfo_dbs=""
				for db_name in $securiteinfo_dbs ; do
					if [[ ! "$db_name" =~ ".yar" ]] ; then # if it's the value you want to delete
				 		new_securiteinfo_dbs="$new_securiteinfo_dbs$db_name "
					fi
				done
				securiteinfo_dbs="$new_securiteinfo_dbs"
			fi
		fi
	fi
	if [ "$linuxmalwaredetect_enabled" == "yes" ] ; then
		if [ -n "$linuxmalwaredetect_dbs" ] ; then
			if [ `xshok_array_count "$linuxmalwaredetect_dbs"` -ge "1" ] ; then
				new_linuxmalwaredetect_dbs=""
				for db_name in $linuxmalwaredetect_dbs ; do
					if [[ ! "$db_name" =~ ".yar" ]] ; then # if it's the value you want to delete
				 		new_linuxmalwaredetect_dbs="$new_linuxmalwaredetect_dbs$db_name "
					fi
				done
				linuxmalwaredetect_dbs="$new_linuxmalwaredetect_dbs"
			fi
		fi
	fi
fi

# Set the variables for MalwarePatrol
if [ "$malwarepatrol_free" == "yes" ] ; then
	malwarepatrol_product_code="8"
	malwarepatrol_list="clamav_basic"
else
	if [ -z $malwarepatrol_list ] ; then
		malwarepatrol_list="clamav_basic"
	fi
	if [ -z $malwarepatrol_product_code ] ; then
		# Not sure, it may be better to return an error.
		malwarepatrol_product_code=8
	fi
fi
if [ $malwarepatrol_list == "clamav_basic" ] ; then
	malwarepatrol_db="malwarepatrol.db"
else
	malwarepatrol_db="malwarepatrol.ndb"
fi
malwarepatrol_url="$malwarepatrol_url?product=$malwarepatrol_product_code&list=$malwarepatrol_list"

# If "ham_dir" variable is set, then create initial whitelist files (skipped if first-time script run).
test_dir="$work_dir/test"
if [ -n "$ham_dir" -a -d "$work_dir" -a ! -d "$test_dir" ] ; then
	if [ -d "$ham_dir" ] ; then
		xshok_mkdir_ownership "$test_dir"
		cp -f "$work_dir"/*/*.ndb "$test_dir"
		$clamscan_bin --infected --no-summary -d "$test_dir" "$ham_dir"/* | command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' >> "$work_dir_work_configs/whitelist.txt"
		grep -h -f "$work_dir_work_configs/whitelist.txt" "$test_dir"/* | cut -d "*" -f2 | sort | uniq > "$work_dir_work_configs/whitelist.hex"
		cd "$test_dir"
		for db_file in `ls`; do
			grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$db_file" > "$db_file-tmp"
			mv -f "$db_file-tmp" "$db_file"
			if $clamscan_bin --quiet -d "$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null ; then
				if $rsync_bin -pcqt $db_file $clam_dbs ; then
					perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
					if [ "$selinux_fixes" == "yes" ] ; then
						restorecon "$clam_dbs/$db_file"
					fi
					do_clamd_reload=1
				fi
			fi
		done
		if [ -r "$work_dir_work_configs/whitelist.hex" ] ; then
			xshok_pretty_echo_and_log "Initial HAM directory scan whitelist file created in $work_dir_work_configs"
		else
			xshok_pretty_echo_and_log "No false-positives detected in initial HAM directory scan"
		fi
	else
		xshok_pretty_echo_and_log "WARNING: Cannot locate HAM directory: $ham_dir"
		xshok_pretty_echo_and_log "Skipping initial whitelist file creation.  Fix 'ham_dir' path in config file"
	fi
fi

# Check to see if the working directories have been created.
# If not, create them.  Otherwise, ignore and proceed with script.
xshok_mkdir_ownership "$work_dir"
xshok_mkdir_ownership "$work_dir_securiteinfo"
xshok_mkdir_ownership "$work_dir_malwarepatrol"
xshok_mkdir_ownership "$work_dir_linuxmalwaredetect"
xshok_mkdir_ownership "$work_dir_sanesecurity"
xshok_mkdir_ownership "$work_dir_yararulesproject"
xshok_mkdir_ownership "$work_dir_work_configs"
xshok_mkdir_ownership "$work_dir_gpg"
xshok_mkdir_ownership "$work_dir_add"

# Set secured access permissions to the GPG directory
perms chmod -f 0700 "$work_dir_gpg"

# If we haven't done so yet, download Sanesecurity public GPG key and import to custom keyring.
if [ ! -s "$work_dir_gpg/publickey.gpg" ] ; then
	if ! $curl_bin -s -S $curl_proxy $curl_insecure --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" -L -R "$sanesecurity_gpg_url" -o $work_dir_gpg/publickey.gpg 2>/dev/null ; then
		xshok_pretty_echo_and_log "ALERT: Could not download Sanesecurity public GPG key" "*"
		exit 1
	else

		xshok_pretty_echo_and_log "Sanesecurity public GPG key successfully downloaded"
		rm -f -- "$work_dir_gpg/ss-keyring.gp*"
		if ! $gpg_bin -q --no-options --no-default-keyring --homedir $work_dir_gpg --keyring $work_dir_gpg/ss-keyring.gpg --import $work_dir_gpg/publickey.gpg 2>/dev/null ; then
			xshok_pretty_echo_and_log "ALERT: could not import Sanesecurity public GPG key to custom keyring" "*"
			exit 1
		else
			chmod -f 0644 $work_dir_gpg/*.*
			xshok_pretty_echo_and_log "Sanesecurity public GPG key successfully imported to custom keyring"
		fi
	fi
fi

# If custom keyring is missing, try to re-import Sanesecurity public GPG key.
if [ ! -s "$work_dir_gpg/ss-keyring.gpg" ] ; then
	rm -f -- "$work_dir_gpg/ss-keyring.gp*"
	if ! $gpg_bin -q --no-options --no-default-keyring --homedir $work_dir_gpg --keyring $work_dir_gpg/ss-keyring.gpg --import $work_dir_gpg/publickey.gpg 2>/dev/null ; then
		xshok_pretty_echo_and_log "ALERT: Custom keyring MISSING or CORRUPT!  Could not import Sanesecurity public GPG key to custom keyring" "*"
		exit 1
	else
		chmod -f 0644 $work_dir_gpg/*.*
		xshok_pretty_echo_and_log "Sanesecurity custom keyring MISSING!  GPG key successfully re-imported to custom keyring"
	fi
fi

# Database update check, time randomization section.  This script now
# provides support for both bash and non-bash enabled system shells.
if [ "$enable_random" = "yes" ] ; then
	if [ -n "$RANDOM" ] ; then
		sleep_time=$(($RANDOM * $(($max_sleep_time - $min_sleep_time)) / 32767 + $min_sleep_time))
	else
		sleep_time=0
		while [ "$sleep_time" -lt "$min_sleep_time" -o "$sleep_time" -gt "$max_sleep_time" ] ; do
			sleep_time=`head -1 /dev/urandom | cksum | awk '{print $2}'`
		done
	fi
	if [ ! -t 0 ] ; then
		xshok_pretty_echo_and_log "`date` - Pausing database file updates for $sleep_time seconds..."
		sleep $sleep_time
		xshok_pretty_echo_and_log "`date` - Pause complete, checking for new database files..."
	fi
fi

# Create "scan-test.txt" file for clamscan database integrity testing.
if [ ! -s "$work_dir_work_configs/scan-test.txt" ] ; then
	echo "This is the clamscan test file..." > "$work_dir_work_configs/scan-test.txt"
fi

# If rsync proxy is defined in the config file, then export it for use.
if [ -n "$rsync_proxy" ] ; then
	RSYNC_PROXY="$rsync_proxy"
	export RSYNC_PROXY
fi

# Create $current_dbsfiles containing lists of current and previously active 3rd-party databases
# so that databases and/or backup files that are no longer being used can be removed.
current_tmp="$work_dir_work_configs/current-dbs.tmp"
current_dbs="$work_dir_work_configs/current-dbs.txt"
previous_dbs="$work_dir_work_configs/previous-dbs.txt"
sort "$current_dbs" > "$previous_dbs" 2>/dev/null
rm -f "$current_dbs"

if [ "$sanesecurity_enabled" == "yes" ] ; then
	# Create the Sanesecurity rsync "include" file (defines which files to download).
	sanesecurity_include_dbs="$work_dir_work_configs/ss-include-dbs.txt"
	if [ -n "$sanesecurity_dbs" ] ; then
		rm -f -- "$sanesecurity_include_dbs" "$work_dir_sanesecurity/*.sha256"
		for db in $sanesecurity_dbs ; do
			echo "$db" >> "$sanesecurity_include_dbs"
			echo "$db.sig" >> "$sanesecurity_include_dbs"
			
			echo "$work_dir_sanesecurity/$db" >> "$current_tmp"
			echo "$work_dir_sanesecurity/$db.sig" >> "$current_tmp"
			clamav_files
		done
	fi
fi
if [ "$securiteinfo_enabled" == "yes" ] ; then
	if [ -n "$securiteinfo_dbs" ] ; then
		for db in $securiteinfo_dbs ; do
			echo "$work_dir_securiteinfo/$db" >> "$current_tmp"
			clamav_files
		done
	fi
fi
if [ "$linuxmalwaredetect_enabled" == "yes" ] ; then
	if [ -n "$linuxmalwaredetect_dbs" ] ; then
		for db in $linuxmalwaredetect_dbs ; do
			echo "$work_dir_linuxmalwaredetect/$db" >> "$current_tmp"
			clamav_files
		done
	fi
fi
if [ "$malwarepatrol_enabled" == "yes" ] ; then
	if [ -n "$malwarepatrol_db" ] ; then
		echo "$work_dir_malwarepatrol/$malwarepatrol_db" >> "$current_tmp"
		clamav_files
	fi
fi
if [ "$yararulesproject_enabledd" == "yes" ] ; then
	if [ -n "$yararulesproject_dbs" ] ; then
		for db in $yararulesproject_dbs ; do
			if echo $db|grep -q "/"; then
				db=`echo $db | cut -d"/" -f2`
			fi
			echo "$work_dir_yararulesproject/$db" >> "$current_tmp"
			clamav_files
		done
	fi
fi
if [ "$additional_enabled" == "yes" ] ; then
	if [ -n "$additional_dbs" ] ; then
		for db in $additional_dbs ; do
			echo "$work_dir_add/$db" >> "$current_tmp"
			clamav_files
		done
	fi
fi

# Remove 3rd-party databases and/or backup files that are no longer being used.
sort "$current_tmp" > "$current_dbs" 2>/dev/null
rm -f "$current_tmp"
db_changes="$work_dir_work_configs/db-changes.txt"
if [ ! -s "$previous_dbs" ] ; then
	cp -f "$current_dbs" "$previous_dbs" 2>/dev/null
fi
diff "$current_dbs" "$previous_dbs" 2>/dev/null | grep '>' | awk '{print $2}' > "$db_changes"
if [ -r "$db_changes" ] ; then
	if grep -vq "bak" $db_changes 2>/dev/null ; then
		do_clamd_reload=2
	fi

	for file in `cat $db_changes` ; do
		rm -f -- "$file"
		xshok_pretty_echo_and_log "File removed: $file"
	done
fi

# Create "purge.txt" file for package maintainers to support package uninstall.
purge="$work_dir_work_configs/purge.txt"
cp -f "$current_dbs" "$purge"
echo "$work_dir_work_configs/current-dbs.txt" >> "$purge"
echo "$work_dir_work_configs/db-changes.txt" >> "$purge"
echo "$work_dir_work_configs/last-mbl-update.txt" >> "$purge"
echo "$work_dir_work_configs/last-si-update.txt" >> "$purge"
echo "$work_dir_work_configs/local.ign" >> "$purge"
echo "$work_dir_work_configs/monitor-ign.txt" >> "$purge"
echo "$work_dir_work_configs/my-whitelist.ign2" >> "$purge"
echo "$work_dir_work_configs/tracker.txt"  >> "$purge"
echo "$work_dir_work_configs/previous-dbs.txt" >> "$purge"
echo "$work_dir_work_configs/scan-test.txt" >> "$purge"
echo "$work_dir_work_configs/ss-include-dbs.txt" >> "$purge"
echo "$work_dir_work_configs/whitelist.hex" >> "$purge"
echo "$work_dir_gpg/publickey.gpg" >> "$purge"
echo "$work_dir_gpg/secring.gpg" >> "$purge"
echo "$work_dir_gpg/ss-keyring.gpg*" >> "$purge"
echo "$work_dir_gpg/trustdb.gpg" >> "$purge"
echo "$log_file_path/$log_file_name*" >> "$purge"
echo "$purge" >> "$purge"

# Ignore SSL errors
if [ "$ignore_ssl" = "yes" ] ; then
	curl_insecure="--insecure"
fi

# Silence rsync output and only report errors - useful if script is run via cron.
if [ "$rsync_silence" = "yes" ] ; then
	rsync_output_level="-q"
fi

# If the local rsync client supports the '--no-motd' flag, then enable it.
if $rsync_bin --help | grep 'no-motd' > /dev/null ; then
	no_motd="--no-motd"
fi

# If the local rsync client supports the '--contimeout' flag, then enable it.
if $rsync_bin --help | grep 'contimeout' > /dev/null ; then
	connect_timeout="--contimeout=$rsync_connect_timeout"
fi

# Silence curl output and only report errors - useful if script is run via cron.
if [ "$curl_silence" = "yes" ] ; then
	curl_output_level="-s -S"
else
	curl_output_level=""
fi

# Check and save current system time since epoch for time related database downloads.
# However, if unsuccessful, issue a warning that we cannot calculate times since epoch.
if [ -n "$securiteinfo_dbs" -o -n "malwarepatrol_db" ] ; then
	if [ `date +%s` -gt 0 2>/dev/null ] ; then
		current_time=`date +%s`
	else
		if [ `perl -le print+time 2>/dev/null` ] ; then
			current_time=`perl -le print+time`
		fi
	fi
else
	xshok_pretty_echo_and_log "WARNING: No support for 'date +%s' or 'perl' was not found , SecuriteInfo and MalwarePatrol updates bypassed" "="
	securiteinfo_dbs=""
	malwarepatrol_db=""
fi

################################################################
# Check for Sanesecurity database & GPG signature file updates #
################################################################
if [ "$sanesecurity_enabled" == "yes" ] ; then
	if [ -n "$sanesecurity_dbs" ] ; then
		##if [ ${#sanesecurity_dbs[@]} -lt "1" ] ; then ##will not work due to compound array assignment

		if [ `xshok_array_count "$sanesecurity_dbs"` -lt "1" ] ; then
			xshok_pretty_echo_and_log "Failed sanesecurity_dbs config is invalid or not defined - SKIPPING"
		else
		
		db_file=""
		xshok_pretty_echo_and_log "Sanesecurity Database & GPG Signature File Updates" "="

		sanesecurity_mirror_ips=`dig +ignore +short $sanesecurity_url`
		#add fallback to host if dig returns no records
		if [ `xshok_array_count  "$sanesecurity_mirror_ips"` -lt 1 ] ; then
			sanesecurity_mirror_ips=`host -t A "$sanesecurity_url" | sed -n '/has address/{s/.*address \([^ ]*\).*/\1/;p;}'`
		fi

		if [ `xshok_array_count  "$sanesecurity_mirror_ips"` -ge "1" ] ; then


		for sanesecurity_mirror_ip in $sanesecurity_mirror_ips ; do
			sanesecurity_mirror_name=""
			sanesecurity_mirror_name=`dig +short -x $sanesecurity_mirror_ip | command sed 's/\.$//'`
			#add fallback to host if dig returns no records
			if [ "$sanesecurity_mirror_name" == "" ] ; then
				sanesecurity_mirror_name=`host "$sanesecurity_mirror_ip" | sed -n '/name pointer/{s/.*pointer \([^ ]*\).*\.$/\1/;p;}'`
			fi
			sanesecurity_mirror_site_info="$sanesecurity_mirror_name $sanesecurity_mirror_ip"
			xshok_pretty_echo_and_log "Sanesecurity mirror site used: $sanesecurity_mirror_site_info"
			$rsync_bin $rsync_output_level $no_motd --files-from=$sanesecurity_include_dbs -ctuz $connect_timeout --timeout="$rsync_max_time" --stats rsync://$sanesecurity_mirror_ip/sanesecurity $work_dir_sanesecurity 2>/dev/null
			if [ "$?" -eq "0" ] ; then #the correct way
				sanesecurity_rsync_success="1"
				for db_file in $sanesecurity_dbs ; do
					if ! cmp -s $work_dir_sanesecurity/$db_file $clam_dbs/$db_file ; then

						xshok_pretty_echo_and_log "Testing updated Sanesecurity database file: $db_file"
						if ! $gpg_bin --trust-model always -q --no-default-keyring --homedir $work_dir_gpg --keyring $work_dir_gpg/ss-keyring.gpg --verify $work_dir_sanesecurity/$db_file.sig $work_dir_sanesecurity/$db_file 2>/dev/null ; then
							$gpg_bin --always-trust -q --no-default-keyring --homedir $work_dir_gpg --keyring $work_dir_gpg/ss-keyring.gpg --verify $work_dir_sanesecurity/$db_file.sig $work_dir_sanesecurity/$db_file 2>/dev/null
						fi
						if [ "$?" = "0" ] ; then
							test "$gpg_silence" = "no" && xshok_pretty_echo_and_log "Sanesecurity GPG Signature tested good on $db_file database"
							true
						else
							xshok_pretty_echo_and_log "Sanesecurity GPG Signature test FAILED on $db_file database - SKIPPING" 
							false
						fi
						if [ "$?" = "0" ] ; then
							db_ext=`echo $db_file | cut -d "." -f2`
							if [ -z "$ham_dir" -o "$db_ext" != "ndb" ] ; then
								if $clamscan_bin --quiet -d "$work_dir_sanesecurity/$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null ; then
									xshok_pretty_echo_and_log "Clamscan reports Sanesecurity $db_file database integrity tested good"
									true
								else
									xshok_pretty_echo_and_log "Clamscan reports Sanesecurity $db_file database integrity tested BAD"
									if [ "$remove_bad_database" == "yes" ] ; then
										if rm -f "$work_dir_sanesecurity/$db_file" ; then
											xshok_pretty_echo_and_log "Removed invalid database: $work_dir_sanesecurity/$db_file"
										fi
									fi
									false
								fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $work_dir_sanesecurity/$db_file $clam_dbs 2>/dev/null ; then
								perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
								if [ "$selinux_fixes" == "yes" ] ; then
									restorecon "$clam_dbs/$db_file"
								fi
								xshok_pretty_echo_and_log "Successfully updated Sanesecurity production database file: $db_file"
								sanesecurity_update=1
								do_clamd_reload=1
							else
								xshok_pretty_echo_and_log "Failed to successfully update Sanesecurity production database file: $db_file - SKIPPING"
								false
							fi
						else
							grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$work_dir_sanesecurity/$db_file" > "$test_dir/$db_file"
							$clamscan_bin --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$work_dir_work_configs/whitelist.txt"
							grep -h -f "$work_dir_work_configs/whitelist.txt" "$test_dir/$db_file" | cut -d "*" -f2 | sort | uniq >> "$work_dir_work_configs/whitelist.hex"
							grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
							mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
							if $clamscan_bin --quiet -d "$test_dir/$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null ; then
								xshok_pretty_echo_and_log "Clamscan reports Sanesecurity $db_file database integrity tested good"
								true
							else
								xshok_pretty_echo_and_log "Clamscan reports Sanesecurity $db_file database integrity tested BAD"
								##DO NOT KILL THIS DB
								false
							fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $test_dir/$db_file $clam_dbs 2>/dev/null ; then
							perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
							if [ "$selinux_fixes" == "yes" ] ; then
								restorecon "$clam_dbs/$db_file"
							fi
							xshok_pretty_echo_and_log "Successfully updated Sanesecurity production database file: $db_file"
							sanesecurity_update=1
							do_clamd_reload=1
						else
							xshok_pretty_echo_and_log "Failed to successfully update Sanesecurity production database file: $db_file - SKIPPING"
						fi
					fi
				fi
			fi
		done
		if [ "$sanesecurity_update" != "1" ] ; then
			xshok_pretty_echo_and_log "No Sanesecurity database file updates found" "-"
			break
		else
			break
		fi
	else
		xshok_pretty_echo_and_log "Connection to $sanesecurity_mirror_site_info failed - Trying next mirror site..."
	fi
done
			if [ "$sanesecurity_rsync_success" != "1" ] ; then
				xshok_pretty_echo_and_log "Access to all Sanesecurity mirror sites failed - Check for connectivity issues"
				xshok_pretty_echo_and_log "or signature database name(s) misspelled in the script's configuration file."
			fi
		else
			xshok_pretty_echo_and_log "No Sanesecurity mirror sites found - Check for dns/connectivity issues"
		fi
		fi
	fi
else
	if [ -n "$sanesecurity_dbs" ] ; then
		if [ "$remove_disabled_databases" == "yes" ] ; then
			xshok_pretty_echo_and_log "Removing disabled Sanesecurity Database files"
			for db_file in $sanesecurity_dbs ; do
				if [ -r "$work_dir_sanesecurity/$db_file" ] ; then
					rm -f "$work_dir_sanesecurity/$db_file"*
					do_clamd_reload=1
				fi
				if [ -r "$clam_dbs/$db_file" ] ; then
					rm -f "$clam_dbs/$db_file"
					do_clamd_reload=1
				fi
			done
		fi
	fi
fi

##############################################################################################################################################
# Check for updated SecuriteInfo database files every set number of  hours as defined in the "USER CONFIGURATION" section of this script #
##############################################################################################################################################
if [ "$securiteinfo_enabled" == "yes" ] ; then
	if [ "$securiteinfo_authorisation_signature" != "YOUR-SIGNATURE-NUMBER" ] ; then
		if [ -n "$securiteinfo_dbs" ] ; then
			if [ `xshok_array_count "$securiteinfo_dbs"` -lt "1" ] ; then
				xshok_pretty_echo_and_log "Failed securiteinfo_dbs config is invalid or not defined - SKIPPING"
			else
			rm -f "$work_dir_securiteinfo/*.gz"
			if [ -r "$work_dir_work_configs/last-si-update.txt" ] ; then
				last_securiteinfo_update=`cat $work_dir_work_configs/last-si-update.txt`
			else
				last_securiteinfo_update="0"
			fi
			db_file=""
			loop=""
			update_interval=$(($securiteinfo_update_hours * 3600))
			time_interval=$(($current_time - $last_securiteinfo_update))
			if [ "$time_interval" -ge $(($update_interval - 600)) ] ; then
				echo "$current_time" > "$work_dir_work_configs"/last-si-update.txt

				xshok_pretty_echo_and_log "SecuriteInfo Database File Updates" "="
				xshok_pretty_echo_and_log "Checking for SecuriteInfo updates..."
				securiteinfo_updates="0"
				for db_file in $securiteinfo_dbs ; do
					if [ "$loop" = "1" ] ; then
						xshok_pretty_echo_and_log "---"      
					fi
					xshok_pretty_echo_and_log "Checking for updated SecuriteInfo database file: $db_file"

					securiteinfo_db_update="0"
					if [ -r "$work_dir_securiteinfo/$db_file" ] ; then
						z_opt="-z $work_dir_securiteinfo/$db_file"
					else
						z_opt=""
					fi
					if $curl_bin $curl_proxy $curl_insecure $curl_output_level --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" -L -R $z_opt -o "$work_dir_securiteinfo/$db_file" "$securiteinfo_url/$securiteinfo_authorisation_signature/$db_file" 2>/dev/null ;	then
						loop="1"
						if ! cmp -s $work_dir_securiteinfo/$db_file $clam_dbs/$db_file ; then
							if [ "$?" = "0" ] ; then
								db_ext=`echo $db_file | cut -d "." -f2`

								xshok_pretty_echo_and_log "Testing updated SecuriteInfo database file: $db_file"
								if [ -z "$ham_dir" -o "$db_ext" != "ndb" ]
									then
									if $clamscan_bin --quiet -d "$work_dir_securiteinfo/$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null
										then
										xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo $db_file database integrity tested good"
										true
									else
										xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo $db_file database integrity tested BAD"
										if [ "$remove_bad_database" == "yes" ] ; then
											if rm -f "$work_dir_securiteinfo/$db_file" ; then
												xshok_pretty_echo_and_log "Removed invalid database: $work_dir_securiteinfo/$db_file"
											fi
										fi
										false
									fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $work_dir_securiteinfo/$db_file $clam_dbs 2>/dev/null ; then
									perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
									if [ "$selinux_fixes" == "yes" ] ; then
										restorecon "$clam_dbs/$db_file"
									fi
									xshok_pretty_echo_and_log "Successfully updated SecuriteInfo production database file: $db_file"
									securiteinfo_updates=1
									securiteinfo_db_update=1
									do_clamd_reload=1
								else
									xshok_pretty_echo_and_log "Failed to successfully update SecuriteInfo production database file: $db_file - SKIPPING"
								fi
							else
								grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$work_dir_securiteinfo/$db_file" > "$test_dir/$db_file"
								$clamscan_bin --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$work_dir_work_configs/whitelist.txt"
								grep -h -f "$work_dir_work_configs/whitelist.txt" "$test_dir/$db_file" | cut -d "*" -f2 | sort | uniq >> "$work_dir_work_configs/whitelist.hex"
								grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
								mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
								if $clamscan_bin --quiet -d "$test_dir/$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null
									then
									xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo $db_file database integrity tested good"
									true
								else
									xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo $db_file database integrity tested BAD"
									rm -f "$work_dir_securiteinfo/$db_file"
									if [ "$remove_bad_database" == "yes" ] ; then
										if rm -f "$work_dir_securiteinfo/$db_file" ; then
											xshok_pretty_echo_and_log "Removed invalid database: $work_dir_securiteinfo/$db_file"
										fi
									fi
									false
								fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $test_dir/$db_file $clam_dbs 2>/dev/null ; then
								perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
								if [ "$selinux_fixes" == "yes" ] ; then
									restorecon "$clam_dbs/$db_file"
								fi
								xshok_pretty_echo_and_log "Successfully updated SecuriteInfo production database file: $db_file"
								securiteinfo_updates=1
								securiteinfo_db_update=1
								do_clamd_reload=1
							else
								xshok_pretty_echo_and_log "Failed to successfully update SecuriteInfo production database file: $db_file - SKIPPING"
							fi
						fi
					fi
				fi
			else
				xshok_pretty_echo_and_log "Failed curl connection to $securiteinfo_url - SKIPPED SecuriteInfo $db_file update"
			fi
			if [ "$securiteinfo_db_update" != "1" ] ; then          
				xshok_pretty_echo_and_log "No updated SecuriteInfo $db_file database file found" "-"
			fi
		done
		if [ "$securiteinfo_updates" != "1" ] ; then
			xshok_pretty_echo_and_log "No SecuriteInfo database file updates found" "-"
		fi
	else
		xshok_pretty_echo_and_log "SecuriteInfo Database File Updates" "="

		time_remaining=$(($update_interval - $time_interval))
		hours_left=$(($time_remaining / 3600))
		minutes_left=$(($time_remaining % 3600 / 60))
		xshok_pretty_echo_and_log "$securiteinfo_update_hours hours have not yet elapsed since the last SecuriteInfo update check"
		xshok_pretty_echo_and_log "No update check was performed at this time" "-"
		xshok_pretty_echo_and_log "Next check will be performed in approximately $hours_left hour(s), $minutes_left minute(s)"
fi
fi
fi
fi
else
	if [ -n "$securiteinfo_dbs" ] ; then
		if [ "$remove_disabled_databases" == "yes" ] ; then
			xshok_pretty_echo_and_log "Removing disabled SecuriteInfo Database files"
			for db_file in $securiteinfo_dbs ; do
				if [ -r "$work_dir_securiteinfo/$db_file" ] ; then
					rm -f "$work_dir_securiteinfo/$db_file"
					do_clamd_reload=1
				fi
				if [ -r "$clam_dbs/$db_file" ] ; then
					rm -f "$clam_dbs/$db_file"
					do_clamd_reload=1
				fi
			done
		fi
	fi
fi


##############################################################################################################################################
# Check for updated linuxmalwaredetect database files every set number of hours as defined in the "USER CONFIGURATION" section of this script 
##############################################################################################################################################
if [ "$linuxmalwaredetect_enabled" == "yes" ] ; then
	if [ -n "$linuxmalwaredetect_dbs" ] ; then
		if [ `xshok_array_count "$linuxmalwaredetect_dbs"` -lt "1" ] ; then
			xshok_pretty_echo_and_log "Failed linuxmalwaredetect_dbs config is invalid or not defined - SKIPPING"
		else
		rm -f "$work_dir_linuxmalwaredetect/*.gz"
		if [ -r "$work_dir_work_configs/last-linuxmalwaredetect-update.txt" ] ; then
			last_linuxmalwaredetect_update=`cat $work_dir_work_configs/last-linuxmalwaredetect-update.txt`
		else
			last_linuxmalwaredetect_update="0"
		fi
		db_file=""
		loop=""
		update_interval=$(($linuxmalwaredetect_update_hours * 3600))
		time_interval=$(($current_time - $last_linuxmalwaredetect_update))
		if [ "$time_interval" -ge $(($update_interval - 600)) ] ; then
			echo "$current_time" > "$work_dir_work_configs"/last-linuxmalwaredetect-update.txt

			xshok_pretty_echo_and_log "linuxmalwaredetect Database File Updates" "="
			xshok_pretty_echo_and_log "Checking for linuxmalwaredetect updates..."
			linuxmalwaredetect_updates="0"
			for db_file in $linuxmalwaredetect_dbs ; do
				if [ "$loop" = "1" ] ; then
					xshok_pretty_echo_and_log "---"      
				fi
				xshok_pretty_echo_and_log "Checking for updated linuxmalwaredetect database file: $db_file"

				linuxmalwaredetect_db_update="0"
				if [ -r "$work_dir_linuxmalwaredetect/$db_file" ] ; then
					z_opt="-z $work_dir_linuxmalwaredetect/$db_file"
				else
					z_opt=""
				fi
				if $curl_bin $curl_proxy $curl_insecure $curl_output_level --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" -L -R $z_opt -o $work_dir_linuxmalwaredetect/$db_file "$linuxmalwaredetect_url/$db_file" 2>/dev/null ; then
					loop="1"
					if ! cmp -s $work_dir_linuxmalwaredetect/$db_file $clam_dbs/$db_file ; then
						if [ "$?" = "0" ] ; then
							db_ext=`echo $db_file | cut -d "." -f2`

							xshok_pretty_echo_and_log "Testing updated linuxmalwaredetect database file: $db_file"
							if [ -z "$ham_dir" -o "$db_ext" != "ndb" ] ; then
								if $clamscan_bin --quiet -d "$work_dir_linuxmalwaredetect/$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null
									then
									xshok_pretty_echo_and_log "Clamscan reports linuxmalwaredetect $db_file database integrity tested good"
									true
								else
									xshok_pretty_echo_and_log "Clamscan reports linuxmalwaredetect $db_file database integrity tested BAD"
									if [ "$remove_bad_database" == "yes" ] ; then
										if rm -f "$work_dir_linuxmalwaredetect/$db_file" ; then
											xshok_pretty_echo_and_log "Removed invalid database: $work_dir_linuxmalwaredetect/$db_file"
										fi
									fi
									false
								fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $work_dir_linuxmalwaredetect/$db_file $clam_dbs 2>/dev/null ; then
								perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
								if [ "$selinux_fixes" == "yes" ] ; then
									restorecon "$clam_dbs/local.ign"
								fi
								xshok_pretty_echo_and_log "Successfully updated linuxmalwaredetect production database file: $db_file"
								linuxmalwaredetect_updates=1
								linuxmalwaredetect_db_update=1
								do_clamd_reload=1
							else
								xshok_pretty_echo_and_log "Failed to successfully update linuxmalwaredetect production database file: $db_file - SKIPPING"
							fi
						else
							grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$work_dir_linuxmalwaredetect/$db_file" > "$test_dir/$db_file"
							$clamscan_bin --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$work_dir_work_configs/whitelist.txt"
							grep -h -f "$work_dir_work_configs/whitelist.txt" "$test_dir/$db_file" | cut -d "*" -f2 | sort | uniq >> "$work_dir_work_configs/whitelist.hex"
							grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
							mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
							if $clamscan_bin --quiet -d "$test_dir/$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null ; then
								xshok_pretty_echo_and_log "Clamscan reports linuxmalwaredetect $db_file database integrity tested good"
								true
							else
								xshok_pretty_echo_and_log "Clamscan reports linuxmalwaredetect $db_file database integrity tested BAD"
								if [ "$remove_bad_database" == "yes" ] ; then
									if rm -f "$work_dir_linuxmalwaredetect/$db_file" ; then
										xshok_pretty_echo_and_log "Removed invalid database: $work_dir_linuxmalwaredetect/$db_file"
									fi
								fi
								false
							fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $test_dir/$db_file $clam_dbs 2>/dev/null ;	then
							perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
							if [ "$selinux_fixes" == "yes" ] ; then
								restorecon "$clam_dbs/$db_file"
							fi
							xshok_pretty_echo_and_log "Successfully updated linuxmalwaredetect production database file: $db_file"
							linuxmalwaredetect_updates=1
							linuxmalwaredetect_db_update=1
							do_clamd_reload=1
						else
							xshok_pretty_echo_and_log "Failed to successfully update linuxmalwaredetect production database file: $db_file - SKIPPING"
						fi
					fi
				fi
			fi
		else
			xshok_pretty_echo_and_log "WARNING: Failed curl connection to $linuxmalwaredetect_url - SKIPPED linuxmalwaredetect $db_file update"
		fi
		if [ "$linuxmalwaredetect_db_update" != "1" ] ; then

			xshok_pretty_echo_and_log "No updated linuxmalwaredetect $db_file database file found"
		fi
	done
	if [ "$linuxmalwaredetect_updates" != "1" ] ; then
		xshok_pretty_echo_and_log "No linuxmalwaredetect database file updates found" "-"
	fi
else

	xshok_pretty_echo_and_log "linuxmalwaredetect Database File Updates" "="

	time_remaining=$(($update_interval - $time_interval))
	hours_left=$(($time_remaining / 3600))
	minutes_left=$(($time_remaining % 3600 / 60))
	xshok_pretty_echo_and_log "$linuxmalwaredetect_update_hours hours have not yet elapsed since the last linux malware detect update check"
	xshok_pretty_echo_and_log "No update check was performed at this time" "-"
	xshok_pretty_echo_and_log "Next check will be performed in approximately $hours_left hour(s), $minutes_left minute(s)"
fi
fi
fi
else
	if [ -n "$linuxmalwaredetect_dbs" ] ; then
		if [ "$remove_disabled_databases" == "yes" ] ; then
			xshok_pretty_echo_and_log "Removing disabled linuxmalwaredetect Database files"
			for db_file in $linuxmalwaredetect_dbs ; do
				if [ -r "$work_dir_linuxmalwaredetect/$db_file" ] ; then
					rm -f "$work_dir_linuxmalwaredetect/$db_file"
					do_clamd_reload=1
				fi
				if [ -r "$clam_dbs/$db_file" ] ; then
					rm -f "$clam_dbs/$db_file"
					do_clamd_reload=1
				fi
			done
		fi
	fi
fi


##########################################################################################################################################
# Download MalwarePatrol database file every set number of hours as defined in the "USER CONFIGURATION" section of this script.    #
##########################################################################################################################################
if [ "$malwarepatrol_enabled" == "yes" ] ; then
	if [ "$malwarepatrol_receipt_code" != "YOUR-RECEIPT-NUMBER" ] ; then
		if [ -n "$malwarepatrol_db" ] ; then
			if [ -r "$work_dir_work_configs/last-mbl-update.txt" ] ; then
				last_malwarepatrol_update=`cat $work_dir_work_configs/last-mbl-update.txt`
			else
				last_malwarepatrol_update="0"
			fi
			db_file=""
			update_interval=$(($malwarepatrol_update_hours * 3600))
			time_interval=$(($current_time - $last_malwarepatrol_update))
			if [ "$time_interval" -ge $(($update_interval - 600)) ] ; then
				echo "$current_time" > "$work_dir_work_configs"/last-mbl-update.txt
				xshok_pretty_echo_and_log "Checking for MalwarePatrol updates..."
				# Delete the old MBL (mbl.db) database file if it exists and start using the newer
				# format (mbl.ndb) database file instead.
				# test -e $clam_dbs/$malwarepatrol_db -o -e $clam_dbs/$malwarepatrol_db-bak && rm -f -- "$clam_dbs/mbl.d*"

				# remove the .db is th new format if ndb and
				# symetrically
				if [ "$malwarepatrol_db" == "malwarepatrol.db" -a -f "$clam_dbs/malwarepatrol.ndb" ] ; then
					rm "$clam_dbs/malwarepatrol.ndb";
				fi

				if [ "$malwarepatrol_db" == "malwarepatrol.ndb" -a -f "$clam_dbs/malwarepatrol.db" ] ; then
					rm "$clam_dbs/malwarepatrol.db";
				fi

				xshok_pretty_echo_and_log "MalwarePatrol $db_file Database File Update" "="

				malwarepatrol_reloaded=0
				if [ "$malwarepatrol_free" == "yes" ] ; then
					if $curl_bin $curl_proxy $curl_insecure $curl_output_level -R --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" -o $work_dir_malwarepatrol/$malwarepatrol_db "$malwarepatrol_url&receipt=$malwarepatrol_receipt_code" 2>/dev/null ; then
						if ! cmp -s $work_dir_malwarepatrol/$malwarepatrol_db $clam_dbs/$malwarepatrol_db ; then
							if [ "$?" = "0" ] ; then
								malwarepatrol_reloaded=1
							else
								malwarepatrol_reloaded=2
							fi
						fi
					else # curl failed
						malwarepatrol_reloaded=-1
					fi # if culr

				else # The not free branch
					if $curl_bin $curl_proxy $curl_insecure $curl_output_level -R --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" -o $work_dir_malwarepatrol/$malwarepatrol_db.md5 "$malwarepatrol_url&receipt=$malwarepatrol_receipt_code&hash=1" 2>/dev/null ;	then
						if [ -f $clam_dbs/$malwarepatrol_db ] ; then
							malwarepatrol_md5=`openssl md5 -r $clam_dbs/$malwarepatrol_db 2>/dev/null | cut -d" " -f1`
							if [ ! "$malwarepatrol_md5" ] ; then
								#fallback for missing -r option
								malwarepatrol_md5=`openssl md5 $clam_dbs/$malwarepatrol_db 2>/dev/null | cut -d" " -f2`
							fi
						fi
						malwarepatrol_md5_new=`cat $work_dir_malwarepatrol/$malwarepatrol_db.md5`
						if [ -n "$malwarepatrol_md5_new" -a "$malwarepatrol_md5" != "$malwarepatrol_md5_new" ] ; then
							if $curl_bin $curl_proxy $curl_insecure $curl_output_level -R --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" -o $work_dir_malwarepatrol/$malwarepatrol_db "$malwarepatrol_url&receipt=$malwarepatrol_receipt_code" 2>/dev/null ; then
								malwarepatrol_reloaded=1
							else # curl DB fail
								malwarepatrol_reloaded=-1
							fi # curl DB
						fi # MD5 not equal
					else # curl MD5 fail
						malwarepatrol_reloaded=-1
					fi # curl md5
				fi # if free

				case "$malwarepatrol_reloaded" in 
					1) # database was updated, need test and reload 
					xshok_pretty_echo_and_log "Testing updated MalwarePatrol database file: $malwarepatrol_db"
					if $clamscan_bin --quiet -d "$work_dir_malwarepatrol/$malwarepatrol_db" "$work_dir_work_configs/scan-test.txt" 2>/dev/null ; then
						xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol $malwarepatrol_db database integrity tested good"
						true
					else
						xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol $malwarepatrol_db database integrity tested BAD"
						if [ "$remove_bad_database" == "yes" ] ; then
							if rm -f "$work_dir_malwarepatrol/$malwarepatrol_db" ; then
								xshok_pretty_echo_and_log "Removed invalid database: $work_dir_malwarepatrol/$malwarepatrol_db"
							fi
						fi
						false
					fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$malwarepatrol_db $clam_dbs/$malwarepatrol_db-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $work_dir_malwarepatrol/$malwarepatrol_db $clam_dbs 2>/dev/null ;	then
					perms chown -f $clam_user:$clam_group $clam_dbs/$malwarepatrol_db
					if [ "$selinux_fixes" == "yes" ] ; then
						restorecon "$clam_dbs/$malwarepatrol_db"
					fi
					xshok_pretty_echo_and_log "Successfully updated MalwarePatrol production database file: $malwarepatrol_db"
					malwarepatrol_update=1
					do_clamd_reload=1
				else
					xshok_pretty_echo_and_log "Failed to successfully update MalwarePatrol production database file: $malwarepatrol_db - SKIPPING"
				fi
				;; # The strange case when $? != 0 in the original
				2)
				grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$work_dir_malwarepatrol/$malwarepatrol_db" > "$test_dir/$malwarepatrol_db"
				$clamscan_bin --infected --no-summary -d "$test_dir/$malwarepatrol_db" "$ham_dir"/* | command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$work_dir_work_configs/whitelist.txt"
				grep -h -f "$work_dir_work_configs/whitelist.txt" "$test_dir/$malwarepatrol_db" | cut -d "*" -f2 | sort | uniq >> "$work_dir_work_configs/whitelist.hex"
				grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$test_dir/$malwarepatrol_db" > "$test_dir/$malwarepatrol_db-tmp"
				mv -f "$test_dir/$malwarepatrol_db-tmp" "$test_dir/$malwarepatrol_db"
				if $clamscan_bin --quiet -d "$test_dir/$malwarepatrol_db" "$work_dir_work_configs/scan-test.txt" 2>/dev/null ; then
					xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol $malwarepatrol_db database integrity tested good"
					true
				else
					xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol $malwarepatrol_db database integrity tested BAD"
					if [ "$remove_bad_database" == "yes" ] ; then
						if rm -f "$test_dir/$malwarepatrol_db" ; then
							xshok_pretty_echo_and_log "Removed invalid database: $test_dir/$malwarepatrol_db"
						fi
					fi
					false
				fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$malwarepatrol_db $clam_dbs/$malwarepatrol_db-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $test_dir/$malwarepatrol_db $clam_dbs 2>/dev/null ; then
				perms chown -f $clam_user:$clam_group $clam_dbs/$malwarepatrol_db
				if [ "$selinux_fixes" == "yes" ] ; then
					restorecon "$clam_dbs/$malwarepatrol_db"
				fi
				xshok_pretty_echo_and_log "Successfully updated MalwarePatrol production database file: $malwarepatrol_db"
				malwarepatrol_update=1
				do_clamd_reload=1
			else
				xshok_pretty_echo_and_log "Failed to successfully update MalwarePatrol production database file: $malwarepatrol_db - SKIPPING"
			fi
			;;
			0) # The database did not update
			xshok_pretty_echo_and_log "MalwarePatrol signature database ($malwarepatrol_db) did not change - skipping"
			;;
			-1) # Curl failed
			xshok_pretty_echo_and_log "WARNING - Failed curl connection to $malwarepatrol_url - SKIPPED MalwarePatrol $malwarepatrol_db update"
			;;
		esac

	else

		xshok_pretty_echo_and_log "MalwarePatrol Database File Update" "="

		time_remaining=$(($update_interval - $time_interval))
		hours_left=$(($time_remaining / 3600))
		minutes_left=$(($time_remaining % 3600 / 60))
		xshok_pretty_echo_and_log "$malwarepatrol_update_hours hours have not yet elapsed since the last MalwarePatrol download"
		xshok_pretty_echo_and_log "No database download was performed at this time" "-"
		xshok_pretty_echo_and_log "Next download will be performed in approximately $hours_left hour(s), $minutes_left minute(s)"
	fi
fi
fi
else
	if [ -n "$malwarepatrol_db" ] ; then
		if [ "$remove_disabled_databases" == "yes" ] ; then
			xshok_pretty_echo_and_log "Removing disabled MalwarePatrol Database file"
			if [ -r "$work_dir_malwarepatrol/$malwarepatrol_db" ] ; then
				rm -f "$work_dir_malwarepatrol/$malwarepatrol_db"
				do_clamd_reload=1
			fi
			if [ -r "$clam_dbs/$malwarepatrol_db" ] ; then
				rm -f "$clam_dbs/$malwarepatrol_db"
				do_clamd_reload=1
			fi
		fi
	fi
fi
## MEOW POSSIBLY MISSING OR EXTRA fi....


##############################################################################################################################################
# Check for updated yararulesproject database files every set number of hours as defined in the "USER CONFIGURATION" section of this script 
##############################################################################################################################################
if [ "$yararulesproject_enabledd" == "yes" ] ; then
	if [ -n "$yararulesproject_dbs" ] ; then
		if [ `xshok_array_count "$yararulesproject_dbs"` -lt "1" ] ; then
			xshok_pretty_echo_and_log "Failed yararulesproject_dbs config is invalid or not defined - SKIPPING"
		else
		rm -f "$work_dir_yararulesproject/*.gz"
		if [ -r "$work_dir_work_configs/last-yararulesproject-update.txt" ] ; then
			last_yararulesproject_update=`cat $work_dir_work_configs/last-yararulesproject-update.txt`
		else
			last_yararulesproject_update="0"
		fi
		db_file=""
		loop=""
		update_interval=$(($yararulesproject_update_hours * 3600))
		time_interval=$(($current_time - $last_yararulesproject_update))
		if [ "$time_interval" -ge $(($update_interval - 600)) ] ; then
			echo "$current_time" > "$work_dir_work_configs"/last-yararulesproject-update.txt

			xshok_pretty_echo_and_log "Yara-Rules Database File Updates" "="
			xshok_pretty_echo_and_log "Checking for yararulesproject updates..."
			yararulesproject_updates="0"
			for db_file in $yararulesproject_dbs ; do
				if echo $db_file|grep -q "/"; then
					yr_dir="/"`echo $db_file | cut -d"/" -f1`
					db_file=`echo $db_file | cut -d"/" -f2`
				else yr_dir=""
				fi
				if [ "$loop" = "1" ] ; then
					xshok_pretty_echo_and_log "---"      
				fi
				xshok_pretty_echo_and_log "Checking for updated yararulesproject database file: $db_file"

				yararulesproject_db_update="0"
				if [ -r "$work_dir_yararulesproject/$db_file" ] ; then
					z_opt="-z $work_dir_yararulesproject/$db_file"
				else
					z_opt=""
				fi
				if $curl_bin $curl_proxy $curl_insecure $curl_output_level --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" -L -R $z_opt -o $work_dir_yararulesproject/$db_file "$yararulesproject_url$yr_dir/$db_file" 2>/dev/null ; then
					loop="1"
					if ! cmp -s $work_dir_yararulesproject/$db_file $clam_dbs/$db_file ; then
						if [ "$?" = "0" ] ; then
							db_ext=`echo $db_file | cut -d "." -f2`

							xshok_pretty_echo_and_log "Testing updated yararulesproject database file: $db_file"
							if [ -z "$ham_dir" -o "$db_ext" != "ndb" ] ; then
								if $clamscan_bin --quiet -d "$work_dir_yararulesproject/$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null
									then
									xshok_pretty_echo_and_log "Clamscan reports yararulesproject $db_file database integrity tested good"
									true
								else
									xshok_pretty_echo_and_log "Clamscan reports yararulesproject $db_file database integrity tested BAD"
									if [ "$remove_bad_database" == "yes" ] ; then
										if rm -f "$work_dir_yararulesproject/$db_file" ; then
											xshok_pretty_echo_and_log "Removed invalid database: $work_dir_yararulesproject/$db_file"
										fi
									fi
									false
								fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $work_dir_yararulesproject/$db_file $clam_dbs 2>/dev/null ; then
								perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
								if [ "$selinux_fixes" == "yes" ] ; then
									restorecon "$clam_dbs/$db_file"
								fi
								xshok_pretty_echo_and_log "Successfully updated yararulesproject production database file: $db_file"
								yararulesproject_updates=1
								yararulesproject_db_update=1
								do_clamd_reload=1
							else
								xshok_pretty_echo_and_log "Failed to successfully update yararulesproject production database file: $db_file - SKIPPING"
							fi
						else
							grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$work_dir_yararulesproject/$db_file" > "$test_dir/$db_file"
							$clamscan_bin --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$work_dir_work_configs/whitelist.txt"
							grep -h -f "$work_dir_work_configs/whitelist.txt" "$test_dir/$db_file" | cut -d "*" -f2 | sort | uniq >> "$work_dir_work_configs/whitelist.hex"
							grep -h -v -f "$work_dir_work_configs/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
							mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
							if $clamscan_bin --quiet -d "$test_dir/$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null ; then
								xshok_pretty_echo_and_log "Clamscan reports yararulesproject $db_file database integrity tested good"
								true
							else
								xshok_pretty_echo_and_log "Clamscan reports yararulesproject $db_file database integrity tested BAD"
								if [ "$remove_bad_database" == "yes" ] ; then
									if rm -f "$work_dir_yararulesproject/$db_file" ; then
										xshok_pretty_echo_and_log "Removed invalid database: $work_dir_yararulesproject/$db_file"
									fi
								fi
								false
							fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $test_dir/$db_file $clam_dbs 2>/dev/null ; then
							perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
							if [ "$selinux_fixes" == "yes" ] ; then
								restorecon "$clam_dbs/$db_file"
							fi
							xshok_pretty_echo_and_log "Successfully updated yararulesproject production database file: $db_file"
							yararulesproject_updates=1
							yararulesproject_db_update=1
							do_clamd_reload=1
						else
							xshok_pretty_echo_and_log "Failed to successfully update yararulesproject production database file: $db_file - SKIPPING"
						fi
					fi
				fi
			fi
		else
			xshok_pretty_echo_and_log "WARNING: Failed curl connection to $yararulesproject_url - SKIPPED yararulesproject $db_file update"
		fi
		if [ "$yararulesproject_db_update" != "1" ] ; then
			xshok_pretty_echo_and_log "No updated yararulesproject $db_file database file found"
		fi
	done
	if [ "$yararulesproject_updates" != "1" ] ; then
		xshok_pretty_echo_and_log "No yararulesproject database file updates found" "-"
	fi
else

	xshok_pretty_echo_and_log "Yara-Rules Database File Updates" "="

	time_remaining=$(($update_interval - $time_interval))
	hours_left=$(($time_remaining / 3600))
	minutes_left=$(($time_remaining % 3600 / 60))
	xshok_pretty_echo_and_log "$yararulesproject_update_hours hours have not yet elapsed since the last yararulesproject database update check"
	xshok_pretty_echo_and_log "No update check was performed at this time" "-"
	xshok_pretty_echo_and_log "Next check will be performed in approximately $hours_left hour(s), $minutes_left minute(s)"
fi
fi
fi
else
	if [ -n "$yararulesproject_dbs" ] ; then
		if [ "$remove_disabled_databases" == "yes" ] ; then
			xshok_pretty_echo_and_log "Removing disabled yararulesproject Database files"
			for db_file in $yararulesproject_dbs ; do
				if echo $db_file|grep -q "/"; then
					db_file=`echo $db_file | cut -d"/" -f2`
				fi
				if [ -r "$work_dir_yararulesproject/$db_file" ] ; then
					rm -f "$work_dir_yararulesproject/$db_file"
					do_clamd_reload=1
				fi
				if [ -r "$clam_dbs/$db_file" ] ; then
					rm -f "$clam_dbs/$db_file"
					do_clamd_reload=1
				fi
			done
		fi
	fi
fi

###################################################
# Check for user added signature database updates #
###################################################
if [ -n "$additional_dbs" ] ; then
		if [ `xshok_array_count "$additional_dbs"` -lt "1" ] ; then
			xshok_pretty_echo_and_log "Failed additional_dbs config is invalid or not defined - SKIPPING"
		else
	xshok_pretty_echo_and_log "User Added Signature Database File Update(s)" "="

	for db_url in $additional_dbs ; do
		base_url=`echo $db_url | cut -d "/" -f3`
		db_file=`basename $db_url`
		if [ "`echo $db_url | cut -d ":" -f1`" = "rsync" ] ; then
			if ! $rsync_bin $rsync_output_level $no_motd $connect_timeout --timeout="$rsync_max_time" --exclude=*.txt -crtuz --stats --exclude=*.sha256 --exclude=*.sig --exclude=*.gz $db_url $work_dir_add 2>/dev/null ;  then
				xshok_pretty_echo_and_log "Failed rsync connection to $base_url - SKIPPED $db_file update"
			fi
		else
			if [ -r "$work_dir_add/$db_file" ] ; then
				z_opt="-z $work_dir_add/$db_file"
			else
				z_opt=""
			fi
			if ! $curl_bin $curl_output_level --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" -L -R $z_opt -o $work_dir_add/$db_file $db_url 2>/dev/null ; then
				xshok_pretty_echo_and_log "Failed curl connection to $base_url - SKIPPED $db_file update"
			fi
		fi
	done
	db_file=""
	for db_file in `ls $work_dir_add`; do
		if ! cmp -s $work_dir_add/$db_file $clam_dbs/$db_file ; then

			xshok_pretty_echo_and_log "Testing updated database file: $db_file"
			$clamscan_bin --quiet -d "$work_dir_add/$db_file" "$work_dir_work_configs/scan-test.txt" 2>/dev/null
			if [ "$?" = "0" ] ; then
				xshok_pretty_echo_and_log "Clamscan reports $db_file database integrity tested good"
				true
			else
				xshok_pretty_echo_and_log "Clamscan reports User Added $db_file database integrity tested BAD"
				if [ "$remove_bad_database" == "yes" ] ; then
					if rm -f "$work_dir_add/$db_file" ; then
						xshok_pretty_echo_and_log "Removed invalid database: $work_dir_add/$db_file"
					fi
				fi
				false
			fi && (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && if $rsync_bin -pcqt $work_dir_add/$db_file $clam_dbs ; then
			perms chown -f $clam_user:$clam_group $clam_dbs/$db_file
			if [ "$selinux_fixes" == "yes" ] ; then
				restorecon "$clam_dbs/$db_file"
			fi
			xshok_pretty_echo_and_log "Successfully updated User-Added production database file: $db_file"
			add_update=1
			do_clamd_reload=1
		else
			xshok_pretty_echo_and_log "Failed to successfully update User-Added production database file: $db_file - SKIPPING"
		fi
	fi
done
if [ "$add_update" != "1" ] ; then      
	xshok_pretty_echo_and_log "No User-Defined database file updates found" "-"
fi
fi
fi

###################################################
# Generate whitelists
###################################################
# Check to see if the local.ign file exists, and if it does, check to see if any of the script
# added bypass entries can be removed due to offending signature modifications or removals.
if [ -r "$clam_dbs/local.ign" -a -s "$work_dir_work_configs/monitor-ign.txt" ] ; then
	ign_updated=0
	cd "$clam_dbs"
	cp -f local.ign "$work_dir_work_configs/local.ign"
	cp -f "$work_dir_work_configs/monitor-ign.txt" "$work_dir_work_configs/monitor-ign-old.txt"

	xshok_pretty_echo_and_log "" "=" "80"
	for entry in `cat "$work_dir_work_configs/monitor-ign-old.txt" 2>/dev/null` ; do
		sig_file=`echo "$entry" | tr -d "\r" | awk -F ":" '{print $1}'`
		sig_hex=`echo "$entry" | tr -d "\r" | awk -F ":" '{print $NF}'`
		sig_name_old=`echo "$entry" | tr -d "\r" | awk -F ":" '{print $3}'`
		sig_ign_old=`grep ":$sig_name_old" "$work_dir_work_configs/local.ign"`
		sig_old=`echo "$entry" | tr -d "\r" | cut -d ":" -f3-`
		sig_new=`grep -hwF ":$sig_hex" "$sig_file" | tr -d "\r" 2>/dev/null`
		sig_mon_new=`grep -HwF -n ":$sig_hex" "$sig_file" | tr -d "\r"`
		if [ -n "$sig_new" ] ; then
			if [ "$sig_old" != "$sig_new" -o "$entry" != "$sig_mon_new" ] ; then
				sig_name_new=`echo "$sig_new" | tr -d "\r" | awk -F ":" '{print $1}'`
				sig_ign_new=`echo "$sig_mon_new" | cut -d ":" -f1-3`
				perl -i -ne "print unless /$sig_ign_old/" "$work_dir_work_configs/monitor-ign.txt"
				echo "$sig_mon_new" >> "$work_dir_work_configs/monitor-ign.txt"
				perl -p -i -e "s/$sig_ign_old/$sig_ign_new/" "$work_dir_work_configs/local.ign"
				xshok_pretty_echo_and_log "$sig_name_old hexadecimal signature is unchanged, however signature name and/or line placement"
				xshok_pretty_echo_and_log "in $sig_file has changed to $sig_name_new - updated local.ign to reflect this change."
				ign_updated=1
			fi
		else
			perl -i -ne "print unless /$sig_ign_old/" "$work_dir_work_configs/monitor-ign.txt" "$work_dir_work_configs/local.ign"

			xshok_pretty_echo_and_log "$sig_name_old signature has been removed from $sig_file, entry removed from local.ign."
			ign_updated=1
		fi
	done
	if [ "$ign_updated" = "1" ] ; then
		if $clamscan_bin --quiet -d "$work_dir_work_configs/local.ign" "$work_dir_work_configs/scan-test.txt"
			then
			if $rsync_bin -pcqt $work_dir_work_configs/local.ign $clam_dbs
				then
				perms chown -f $clam_user:$clam_group "$clam_dbs/local.ign"
				perms chmod -f 0644 "$clam_dbs/local.ign" "$work_dir_work_configs/monitor-ign.txt"
				if [ "$selinux_fixes" == "yes" ] ; then
					restorecon "$clam_dbs/local.ign"
				fi
				do_clamd_reload=3
			else
				xshok_pretty_echo_and_log "Failed to successfully update local.ign file - SKIPPING"
			fi
		else
			xshok_pretty_echo_and_log "Clamscan reports local.ign database integrity is bad - SKIPPING"
		fi
	else
		xshok_pretty_echo_and_log "No whitelist signature changes found in local.ign" "="
	fi
fi

# Check to see if my-whitelist.ign2 file exists, and if it does, check to see if any of the script
# added whitelist entries can be removed due to offending signature modifications or removals.
if [ -r "$clam_dbs/my-whitelist.ign2" -a -s "$work_dir_work_configs/tracker.txt" ] ; then
	ign2_updated=0
	cd "$clam_dbs"
	cp -f my-whitelist.ign2 "$work_dir_work_configs/my-whitelist.ign2"

	xshok_pretty_echo_and_log "" "=" "80"
	for entry in `cat "$work_dir_work_configs/tracker.txt" 2>/dev/null` ; do
		sig_file=`echo "$entry" | cut -d ":" -f1`
		sig_full=`echo "$entry" | cut -d ":" -f2-`
		sig_name=`echo "$entry" | cut -d ":" -f2`
		if ! grep -F "$sig_full" "$sig_file" > /dev/null 2>&1 ; then
			perl -i -ne "print unless /$sig_name$/" "$work_dir_work_configs/my-whitelist.ign2"
			perl -i -ne "print unless /:$sig_name:/" "$work_dir_work_configs/tracker.txt"

			xshok_pretty_echo_and_log "$sig_name signature no longer exists in $sig_file, whitelist entry removed from my-whitelist.ign2"
			ign2_updated=1
		fi
	done

	xshok_pretty_echo_and_log "" "=" "80"
	if [ "$ign2_updated" = "1" ]
		then
		if $clamscan_bin --quiet -d "$work_dir_work_configs/my-whitelist.ign2" "$work_dir_work_configs/scan-test.txt"
			then
			if $rsync_bin -pcqt $work_dir_work_configs/my-whitelist.ign2 $clam_dbs
				then
				perms chown -f $clam_user:$clam_group "$clam_dbs/my-whitelist.ign2"
				perms chmod -f 0644 "$clam_dbs/my-whitelist.ign2" "$work_dir_work_configs/tracker.txt"
				if [ "$selinux_fixes" == "yes" ] ; then
					restorecon "$clam_dbs/my-whitelist.ign2"
					restorecon "$work_dir_work_configs/tracker.txt"
				fi
				do_clamd_reload=4
			else
				xshok_pretty_echo_and_log "Failed to successfully update my-whitelist.ign2 file - SKIPPING"
			fi
		else
			xshok_pretty_echo_and_log "Clamscan reports my-whitelist.ign2 database integrity is bad - SKIPPING"
		fi
	else
		xshok_pretty_echo_and_log "No whitelist signature changes found in my-whitelist.ign2"
	fi
fi

# Check for non-matching whitelist.hex signatures and remove them from the whitelist file (signature modified or removed).
if [ -n "$ham_dir" ] ; then
	if [ -r "$work_dir_work_configs/whitelist.hex" ] ; then
		grep -h -f "$work_dir_work_configs/whitelist.hex" "$work_dir"/*/*.ndb | cut -d "*" -f2 | tr -d "\r" | sort | uniq > "$work_dir_work_configs/whitelist.tmp"
		mv -f "$work_dir_work_configs/whitelist.tmp" "$work_dir_work_configs/whitelist.hex"
		rm -f "$work_dir_work_configs/whitelist.txt"
		rm -f "$test_dir"/*.*
		xshok_pretty_echo_and_log "WARNING: Signature(s) triggered on HAM directory scan - signature(s) removed" "*"
	else
		xshok_pretty_echo_and_log "No signatures triggered on HAM directory scan" "="
	fi
fi

# Set appropriate directory and file permissions to all production signature files
# and set file access mode to 0644 on all working directory files.
perms chown -f -R $clam_user:$clam_group "$work_dir"
if ! find "$work_dir" -type f -exec chmod -f 0644 {} + 2>/dev/null ; then
	if ! find "$work_dir" -type f -print0 | xargs -0 chmod -f 0644 2>/dev/null ; then
		if ! find "$work_dir" -type f | xargs chmod -f 0644 2>/dev/null ; then
			find "$work_dir" -type f -exec chmod -f 0644 {} \;
		fi
	fi
fi


# If enabled, set file access mode for all production signature database files to 0644.
if [ "$setmode" = "yes" ] ; then
	perms chown -f -R $clam_user:$clam_group "$clam_dbs"
	if ! find "$clam_dbs" -type f -exec chmod -f 0644 {} + 2>/dev/null ; then
		if ! find "$clam_dbs" -type f -print0 | xargs -0 chmod -f 0644 2>/dev/null ; then
			if ! find "$clam_dbs" -type f | xargs chmod -f 0644 2>/dev/null ; then
				find "$clam_dbs" -type f -exec chmod -f 0644 {} \;
			fi
		fi
	fi
fi

# Reload all clamd databases  
clamscan_reload_dbs

xshok_pretty_echo_and_log "Issue tracker : https://github.com/extremeshok/clamav-unofficial-sigs/issues" "-"

check_new_version

xshok_pretty_echo_and_log "      Powered By https://eXtremeSHOK.com      " "#"

# And lastly we exit, Note: the exit is always on the 2nd last line
exit $?
