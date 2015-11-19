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

default_config="/etc/clamav-unofficial-sigs.conf"

################################################################################

######  #######    #     # ####### #######    ####### ######  ### ####### 
#     # #     #    ##    # #     #    #       #       #     #  #     #    
#     # #     #    # #   # #     #    #       #       #     #  #     #    
#     # #     #    #  #  # #     #    #       #####   #     #  #     #    
#     # #     #    #   # # #     #    #       #       #     #  #     #    
#     # #     #    #    ## #     #    #       #       #     #  #     #    
######  #######    #     # #######    #       ####### ######  ###    #    

################################################################################

# Function to support user config settings for applying file and directory access permissions.
perms () {
 if [ -n "$clam_user" -a -n "$clam_group" ] ; then
  "${@:-}"
fi
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
xshok_pretty_echo_and_log () { #"string" "repeating" "count"
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
      for (( n = 0; n < $mycount; n++ )); do 
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
  if [ "$enable_logging" = "yes" ] ; then
    echo `date "+%b %d %T"` "$1" >> "$log_file_path/$log_file_name"
  fi
}

#Script Info
version="4.9"
minimum_required_config_version="53"
version_date="19 November 2015"

#Initialise 
do_clamd_reload="0"
comment_silence="no"
enable_logging="no"

if [ -t 1 ] ; then
  #Set fonts. #echo "${BOLD}-a${NORM}"
  BOLD=`tput bold`
  REV=`tput smso`
  NORM=`tput sgr0`
fi


#function for help and usage
help_and_usage () {

  echo "Usage: `basename $0` [OPTION] [PATH|FILE]"

  echo -e "\n${BOLD}-c${NORM}, ${BOLD}--config${NORM}\tDirect script to use a specific configuration file\n\teg: '-c /path/to/`basename $default_config`'\n\tOptional if the default config is available\n\tDefault: $default_config"

  echo -e "\n${BOLD}--force${NORM}\t\tForce all databases to be downloaded, could cause ip to be blocked"

  echo -e "\n${BOLD}-h${NORM}, ${BOLD}--help${NORM}\tDisplay this script's help and usage information"

  echo -e "\n${BOLD}-v${NORM}, ${BOLD}--version${NORM}\tOutput script version and date information"

  echo -e "\n${BOLD}-d${NORM}, ${BOLD}--decode-sig${NORM}\tDecode a third-party signature either by signature name\n\t(eg: Sanesecurity.Junk.15248) or hexadecimal string.\n\tThis flag will 'NOT' decode image signatures"

  echo -e "\n${BOLD}-e${NORM}, ${BOLD}--encode-string${NORM}\tHexadecimal encode an entire input string that can\n\tbe used in any '*.ndb' signature database file"

  echo -e "\n${BOLD}-f${NORM}, ${BOLD}--encode-formatted${NORM}\tHexadecimal encode a formatted input string containing\n\tsignature spacing fields '{}, (), *', without encoding\n\tthe spacing fields, so that the encoded signature\n\tcan be used in any '*.ndb' signature database file"

  echo -e "\n${BOLD}-g${NORM}, ${BOLD}--gpg-verify${NORM}\tGPG verify a specific Sanesecurity database file\n\teg: '-g filename.ext' (do not include file path)"

  echo -e "\n${BOLD}-i${NORM}, ${BOLD}--information${NORM}\tOutput system and configuration information for\n\tviewing or possible debugging purposes"

  echo -e "\n${BOLD}-m${NORM}, ${BOLD}--make-database${NORM}\tMake a signature database from an ascii file containing\n\tdata strings, with one data string per line.  Additional\n\tinformation is provided when using this flag"

  echo -e "\n${BOLD}-r${NORM}, ${BOLD}--remove-script${NORM}\tRemove the clamav-unofficial-sigs script and all of\n\tits associated files and databases from the system"

  echo -e "\n${BOLD}-s${NORM}, ${BOLD}--test-database${NORM}\tClamscan integrity test a specific database file\n\teg: '-s filename.ext' (do not include file path)"

  echo -e "\n${BOLD}-t${NORM}, ${BOLD}--output-triggered${NORM}\tIf HAM directory scanning is enabled in the script's\n\tconfiguration file, then output names of any third-party\n\tsignatures that triggered during the HAM directory scan"

  echo -e "\n${BOLD}-w${NORM}, ${BOLD}--whitelist${NORM}\tAdds a signature whitelist entry in the newer ClamAV IGN2\n\tformat to 'my-whitelist.ign2' in order to temporarily resolve\n\ta false-positive issue with a specific third-party signature.\n\tScript added whitelist entries will automatically be removed\n\tif the original signature is either modified or removed from\n\tthe third-party signature database" 

  echo -e "\n${BOLD}--check-clamav${NORM}\tIf ClamD status check is enabled and the socket path is correctly specified\n\tthen test to see if clamd is running or not"

  echo -e "\nMail suggestions and bug reports to ${BOLD}<admin@extremeshok.com>${NORM}"

}

xshok_pretty_echo_and_log "" "#" "80"
xshok_pretty_echo_and_log " eXtremeSHOK.com ClamAV Unofficial Signature Updater"
xshok_pretty_echo_and_log " Version: v$version ($version_date)"
xshok_pretty_echo_and_log " Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com"
xshok_pretty_echo_and_log "" "#" "80"

# Use the Default Config bt default
config_source=$default_config

#default disable forced updates
forced_updates="no"

# Generic command line options
while true; do
  case "$1" in
    -c | --config ) config_source="$2"; shift 2; break ;;
--force ) force_updates="yes"; shift 1; break ;;
-h | --help ) help_and_usage; exit; break ;;
-v | --version ) exit; break ;;
* ) break ;;
esac
done


## CONFIG LOADING AND ERROR CHECKING ##############################################

if [ ! -r "$config_source" ] ; then #exists and readable
  xshok_pretty_echo_and_log "ERROR: Config file does not exist / not readable at: $config_source" "="
  exit 1
fi

#config stripping
xshok_pretty_echo_and_log "Loading config: $config_source" "="

# delete lines beginning with #
# delete from ' #' or '# ' to end of the line
# delete both trailing and leading whitespace
# delete all empty lines
clean_config=`command sed -e '/^#.*/d' -e 's/\([[:space:]]#\|#[[:space:]]\).*//' -e 's/^[ \t]*//;s/[ \t]*$//' -e '/^\s*$/d' "$config_source"`

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
for i in "${clean_config[@]}"
do
  eval $(echo ${i} | command sed -e 's/[[:space:]]*$//')
done

#config version validation
if [ "$config_version" -lt "$minimum_required_config_version" ] ; then
  xshok_pretty_echo_and_log "ERROR: Your configuration version is not compatible with this version" "="
  exit 1
fi

################################################################################

# Check to see if the script's "USER CONFIGURATION FILE" has been completed.
if [ "$user_configuration_complete" != "yes" ] ; then
  xshok_pretty_echo_and_log "WARNING: SCRIPT CONFIGURATION HAS NOT BEEN COMPLETED" "*"
  xshok_pretty_echo_and_log "Please review the script configuration file: `basename $default_config`."
  exit 1
fi

# Reset the update timers to force a full update.
if [ "$force_updates" == "yes" ] ; then
  xshok_pretty_echo_and_log "Force Updates: enabled"     

  securiteinfo_update_hours="0"
  linuxmalwaredetect_update_hours="0"
  malwarepatrol_update_hours="0"
  yararules_update_hours="0"
fi

#decode a third-party signature either by signature name
decode_third_party_signature_by_signature_name (){
  echo ""
  echo "Input a third-party signature name to decode (e.g: Sanesecurity.Junk.15248) or"
  echo "a hexadecimal encoded data string and press enter (do not include '.UNOFFICIAL'"
  echo "in the signature name nor add quote marks to any input string):"
  read input
  input=`echo "$input" | tr -d "'" | tr -d '"'`
  if `echo "$input" | grep "\." > /dev/null`
   then
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
hexadecimal_encode_entire_input_string (){
  echo ""
  echo "Input the data string that you want to hexadecimal encode and then press enter.  Do not include"
  echo "any quotes around the string unless you want them included in the hexadecimal encoded output:"
  read input
  echo "Here is the hexadecimal encoded input string:"
  echo "$input" | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg'
}

#Hexadecimal encode a formatted input string
hexadecimal_encode_formatted_input_string (){
  echo ""
  echo "Input a formated data string containing spacing fields '{}, (), *' that you want to hexadecimal"
  echo "encode, without encoding the spacing fields, and then press enter.  Do not include any quotes"
  echo "around the string unless you want them included in the hexadecimal encoded output:"
  read input
  echo "Here is the hexadecimal encoded input string:"
  echo "$input" | perl -pe 's/(\{[^}]*\}|\([^)]*\)|\*)|(.)/defined $1 ? $1 : sprintf("%02lx", ord $2)/eg'
}

#GPG verify a specific Sanesecurity database file
gpg_verify_specific_sanesecurity_database_file () {
  echo ""
  db_file=`echo "$OPTARG" | awk -F '/' '{print $NF}'`
  if [ -r "$sanesecurity_dir/$db_file" ] ; then
   xshok_pretty_echo_and_log "GPG signature testing database file: $sanesecurity_dir/$db_file"

   if ! gpg --trust-model always -q --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg --verify $sanesecurity_dir/$db_file.sig $sanesecurity_dir/$db_file
     then
     gpg --always-trust -q --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg --verify $sanesecurity_dir/$db_file.sig $sanesecurity_dir/$db_file
   fi
 else
  xshok_pretty_echo_and_log "File '$db_file' cannot be found or is not a Sanesecurity database file."
  xshok_pretty_echo_and_log "Only the following Sanesecurity and OITC databases can be GPG signature tested:"
  xshok_pretty_echo_and_log "$sanesecurity_dbs"
fi
}

#Output system and configuration information
output_system_configuration_information () {
  echo ""
  echo "*** SCRIPT VERSION ***"
  echo "`basename $0` $version ($version_date)"
  echo "*** SYSTEM INFORMATION ***"
  uname=`which uname`
  $uname -a
  echo "*** CLAMSCAN LOCATION & VERSION ***"
  clamscan=`which clamscan`
  echo "$clamscan"
  $clamscan --version | head -1
  echo "*** RSYNC LOCATION & VERSION ***"
  rsync=`which rsync`
  echo "$rsync"
  $rsync --version | head -1
  echo "*** CURL LOCATION & VERSION ***"
  curl=`which curl`
  echo "$curl"
  $curl --version | head -1

  echo "*** GPG LOCATION & VERSION ***"
  gpg=`which gpg`
  echo "$gpg"
  $gpg --version | head -1

  echo "*** SCRIPT WORKING DIRECTORY INFORMATION ***"
  ls -ld $work_dir

  ls -lR $work_dir | grep -v total

  echo "*** CLAMAV DIRECTORY INFORMATION ***"
  ls -ld $clam_dbs
  echo "---"
  ls -l $clam_dbs | grep -v total

  echo "*** SCRIPT CONFIGURATION SETTINGS ***"
  egrep -v "^#|^$" $default_config
}

#Make a signature database from an ascii file
make_signature_database_from_ascii_file () {
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
  echo -n "Do you wish to continue? (y/n): "
  read reply
  if [ "$reply" = "y" -o "$reply" = "Y" ] ; then

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
if clamscan --quiet -d "$path_file" "$config_dir/scan-test.txt" 2>/dev/null
 then

 echo "Clamscan reports database integrity tested good."

 echo -n "Would you like to move '$db_file' into '$clam_dbs' and reload databases? (y/n): "
 read reply
 if [ "$reply" = "y" -o "$reply" = "Y" ] ; then
   if ! cmp -s "$path_file" "$clam_dbs/$db_file"
     then
     if rsync -pcqt "$path_file" "$clam_dbs"
       then
       perms chown $clam_user:$clam_group "$clam_dbs/$db_file"
       chmod 0644 "$clam_dbs/$db_file"
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
remove_script () {
  echo ""
  if [ -n "$pkg_mgr" -a -n "$pkg_rm" ] ; then
   echo "  This script (clamav-unofficial-sigs) was installed on the system"
   echo "  via '$pkg_mgr', use '$pkg_rm' to remove the script"
   echo "  and all of its associated files and databases from the system."

 else
  echo "  Are you sure you want to remove the clamav-unofficial-sigs script and all of its"
  echo -n "  associated files, third-party databases, and work directories from the system? (y/n): "
  read response
  if [ "$response" = "y" -o "$response" = "Y" ] ; then
   if [ -r "$config_dir/purge.txt" ] ; then

     for file in `cat $config_dir/purge.txt` ; do
       rm -f -- "$file"
       echo "     Removed file: $file"
     done
     cron_file="/etc/cron.d/clamav-unofficial-sigs-cron"
     if [ -r "$cron_file" ] ; then
       rm -f "$cron_file"
       echo "     Removed file: $cron_file"
     fi
     log_rotate_file="/etc/logrotate.d/clamav-unofficial-sigs-logrotate"
     if [ -r "$log_rotate_file" ] ; then
       rm -f "$log_rotate_file"
       echo "     Removed file: $log_rotate_file"
     fi
     man_file="/usr/share/man/man8/clamav-unofficial-sigs.8"
     if [ -r "$man_file" ] ; then
       rm -f "$man_file"
       echo "     Removed file: $man_file"
     fi
     rm -f -- "$default_config" && echo "     Removed file: $default_config"
     rm -f -- "$0" && echo "     Removed file: $0"
     rm -rf -- "$work_dir" && echo "     Removed script working directories: $work_dir"

     echo "  The clamav-unofficial-sigs script and all of its associated files, third-party"
     echo "  databases, and work directories have been successfully removed from the system."

   else
    echo "  Cannot locate 'purge.txt' file in $config_dir."
    echo "  Files and signature database will need to be removed manually."

  fi
else
  help_and_usage
fi
fi
}

#Clamscan integrity test a specific database file
clamscan_integrity_test_specific_database_file (){
  echo ""
  input=`echo "$OPTARG" | awk -F '/' '{print $NF}'`
  db_file=`find $work_dir -name $input`
  if [ -r "$db_file" ] ; then
   echo "Clamscan integrity testing: $db_file"

   if clamscan --quiet -d "$db_file" "$config_dir/scan-test.txt" ; then
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
output_signatures_triggered_during_ham_directory_scan () {
  echo ""
  if [ -n "$ham_dir" ] ; then
   if [ -r "$config_dir/whitelist.hex" ] ; then
     echo "The following third-party signatures triggered hits during the HAM Directory scan:"
     
     grep -h -f "$config_dir/whitelist.hex" "$work_dir"/*/*.ndb | cut -d ":" -f1
   else
    echo "No third-party signatures have triggered hits during the HAM Directory scan."
  fi
else
  echo "Ham directory scanning is not currently enabled in the script's configuration file."
fi
}

#Adds a signature whitelist entry in the newer ClamAV IGN2 format
add_signature_whitelist_entry () {
  echo ""
  echo "Input a third-party signature name that you wish to whitelist due to false-positives"
  echo "and press enter (do not include '.UNOFFICIAL' in the signature name nor add quote"
  echo "marks to the input string):"

  read input
  if [ -n "$input" ] ; then
   cd "$clam_dbs"
   input=`echo "$input" | tr -d "'" | tr -d '"'`
   sig_full=`grep -H "$input:" *.ndb`
   sig_name=`echo "$sig_full" | cut -d ":" -f2`
   if [ -n "$sig_name" ] ; then
     if ! grep "$sig_name" my-whitelist.ign2 > /dev/null 2>&1
       then
       cp -f my-whitelist.ign2 "$config_dir" 2>/dev/null
       echo "$sig_name" >> "$config_dir/my-whitelist.ign2"
       echo "$sig_full" >> "$config_dir/tracker.txt"
       if clamscan --quiet -d "$config_dir/my-whitelist.ign2" "$config_dir/scan-test.txt"
         then
         if rsync -pcqt $config_dir/my-whitelist.ign2 $clam_dbs
           then
           perms chown $clam_user:$clam_group my-whitelist.ign2

           if [ ! -s "$config_dir/monitor-ign.txt" ] ; then 
                                  # Create "monitor-ign.txt" file for clamscan database integrity testing.
                                  echo "This is the monitor ignore file..." > "$config_dir/monitor-ign.txt"
                                fi

                                chmod 0644 my-whitelist.ign2 "$config_dir/monitor-ign.txt"
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
                          echo "'UNOFFICIAL' third-Party signatures as found in the *.ndb databases."
                        fi
                      else
                        echo "No input detected - no action taken."
                      fi
                    }


#Clamscan reload database
clamscan_reload_dbs (){
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

    myresult=`clamdscan --reload 2>&1`
    if [[ "$myresult" =~ "ERROR" ]] ; then
      xshok_pretty_echo_and_log "ERROR: Failed to reload, trying again" "-"
      if [ -r "$clamd_pid" ] ; then
        $mypid=`cat clamd_pid`
        kill -USR2 $clamd_pid
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
  if [ -n "$start_clamd" ] ; then
    xshok_pretty_echo_and_log "Attempting to start ClamD..." "-"
    if [ -n "$io_socket1" ] ; then
      $clamd_stop > /dev/null && sleep 5
      $clamd_start > /dev/null && sleep 5
      if [ "`perl -MIO::Socket::UNIX -we '$s = IO::Socket::UNIX->new(shift); $s->print("PING"); print $s->getline; $s->close' "$clamd_socket" 2>/dev/null`" = "PONG" ] ; then
        xshok_pretty_echo_and_log "ClamD was successfully started" "="
      else
       xshok_pretty_echo_and_log "ERROR: CLAMD FAILED TO START" "="
       exit 1
     fi
   else
     if [ -n "$socket_cat1" ] ; then
      $clamd_stop > /dev/null && sleep 5
      $clamd_start > /dev/null && sleep 5
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

############### PROGRAM #########################
# Main options
while true; do
  case "$1" in
    -d | --decode-sig ) decode_third_party_signature_by_signature_name; exit; break ;;
-e | --encode-string ) hexadecimal_encode_entire_input_string; exit; break ;;
-f | --encode-formatted ) hexadecimal_encode_formatted_input_string; exit; break ;;
-g | --gpg-verify ) gpg_verify_specific_sanesecurity_database_file; exit; break ;;
-i | --information ) output_system_configuration_information; exit; break ;;
-m | --make-database ) make_signature_database_from_ascii_file; exit; break ;;
-r | --remove-script ) make_signature_database_from_ascii_file; exit; break ;;
-s | --test-database ) clamscan_integrity_test_specific_database_file; exit; break ;;
-t | --output-triggered ) output_signatures_triggered_during_ham_directory_scan; exit; break ;;
-w | --whitelist ) add_signature_whitelist_entry; exit; break ;;
--check-clamav ) check_clamav; exit; break ;;
* ) break ;;
esac
done

# If "ham_dir" variable is set, then create initial whitelist files (skipped if first-time script run).
test_dir="$work_dir/test"
if [ -n "$ham_dir" -a -d "$work_dir" -a ! -d "$test_dir" ] ; then
 if [ -d "$ham_dir" ] ; then
  mkdir -p "$test_dir"
  cp -f "$work_dir"/*/*.ndb "$test_dir"
  clamscan --infected --no-summary -d "$test_dir" "$ham_dir"/* | \
  command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' >> "$config_dir/whitelist.txt"
  grep -h -f "$config_dir/whitelist.txt" "$test_dir"/* | \
  cut -d "*" -f2 | sort | uniq > "$config_dir/whitelist.hex"
  cd "$test_dir"
  for db_file in `ls`; do
    grep -h -v -f "$config_dir/whitelist.hex" "$db_file" > "$db_file-tmp"
    mv -f "$db_file-tmp" "$db_file"
    if clamscan --quiet -d "$db_file" "$config_dir/scan-test.txt" 2>/dev/null ; then
     if rsync -pcqt $db_file $clam_dbs ; then
      perms chown $clam_user:$clam_group $clam_dbs/$db_file
      do_clamd_reload=1
    fi
  fi
done
if [ -r "$config_dir/whitelist.hex" ] ; then
  xshok_pretty_echo_and_log "Initial HAM directory scan whitelist file created in $config_dir"
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
mkdir -p "$work_dir" "$securiteinfo_dir" "$malwarepatrol_dir" "$linuxmalwaredetect_dir" "$sanesecurity_dir" "$config_dir" "$gpg_dir" "$add_dir"

# Set secured access permissions to the GPG directory
chmod 0700 "$gpg_dir"

# If we haven't done so yet, download Sanesecurity public GPG key and import to custom keyring.
if [ ! -s "$gpg_dir/publickey.gpg" ] ; then
 if ! curl -s -S $curl_proxy $curl_insecure --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" -L -R "$sanesecurity_gpg_url" -o $gpg_dir/publickey.gpg
  then
  xshok_pretty_echo_and_log "ALERT: Could not download Sanesecurity public GPG key" "*"
  exit 1
else

 xshok_pretty_echo_and_log "Sanesecurity public GPG key successfully downloaded"
 rm -f -- "$gpg_dir/ss-keyring.gp*"
 if ! gpg -q --no-options --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg --import $gpg_dir/publickey.gpg 2>/dev/null
  then
  xshok_pretty_echo_and_log "ALERT: could not import Sanesecurity public GPG key to custom keyring" "*"
  exit 1
else
 chmod 0644 $gpg_dir/*.*
 xshok_pretty_echo_and_log "Sanesecurity public GPG key successfully imported to custom keyring"
fi
fi
fi

# If custom keyring is missing, try to re-import Sanesecurity public GPG key.
if [ ! -s "$gpg_dir/ss-keyring.gpg" ] ; then
 rm -f -- "$gpg_dir/ss-keyring.gp*"
 if ! gpg -q --no-options --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg --import $gpg_dir/publickey.gpg
  then
  xshok_pretty_echo_and_log "ALERT: Custom keyring MISSING or CORRUPT!  Could not import Sanesecurity public GPG key to custom keyring" "*"
  exit 1
else
 chmod 0644 $gpg_dir/*.*
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
else
 curl_silence="no"
 rsync_silence="no"
 gpg_silence="no"
 comment_silence="no"
 xshok_pretty_echo_and_log "Script was run manually"
fi
fi

# Create "scan-test.txt" file for clamscan database integrity testing.
if [ ! -s "$config_dir/scan-test.txt" ] ; then
 echo "This is the clamscan test file..." > "$config_dir/scan-test.txt"
fi

# Create the Sanesecurity rsync "include" file (defines which files to download).
sanesecurity_include_dbs="$config_dir/ss-include-dbs.txt"
if [ -n "$sanesecurity_dbs" ] ; then
 rm -f -- "$sanesecurity_include_dbs" "$sanesecurity_dir/*.sha256"
 for db_name in $sanesecurity_dbs ; do
  echo "$db_name" >> "$sanesecurity_include_dbs"
  echo "$db_name.sig" >> "$sanesecurity_include_dbs"
done
fi

# If rsync proxy is defined in the config file, then export it for use.
if [ -n "$rsync_proxy" ] ; then
 RSYNC_PROXY="$rsync_proxy"
 export RSYNC_PROXY
fi

# Create files containing lists of current and previously active 3rd-party databases
# so that databases and/or backup files that are no longer being used can be removed.
current_tmp="$config_dir/current-dbs.tmp"
current_dbs="$config_dir/current-dbs.txt"
previous_dbs="$config_dir/previous-dbs.txt"
sort "$current_dbs" > "$previous_dbs" 2>/dev/null
rm -f "$current_dbs"
clamav_files () {
 echo "$clam_dbs/$db" >> "$current_tmp"
 if [ "$keep_db_backup" = "yes" ] ; then
  echo "$clam_dbs/$db-bak" >> "$current_tmp"
fi
}
if [ -n "$sanesecurity_dbs" ] ; then
 for db in $sanesecurity_dbs ; do
  echo "$sanesecurity_dir/$db" >> "$current_tmp"
  echo "$sanesecurity_dir/$db.sig" >> "$current_tmp"
  clamav_files
done
fi
if [ -n "$securiteinfo_dbs" ] ; then
 for db in $securiteinfo_dbs ; do
  echo "$securiteinfo_dir/$db" >> "$current_tmp"
  clamav_files
done
fi
if [ -n "$malwarepatrol_db" ] ; then
  echo "$malwarepatrol_dir/$malwarepatrol_db" >> "$current_tmp"
  clamav_files
fi
if [ -n "$add_dbs" ] ; then
 for db in $add_dbs ; do
  echo "$add_dir/$db" >> "$current_tmp"
  clamav_files
done
fi

# Remove 3rd-party databases and/or backup files that are no longer being used.
sort "$current_tmp" > "$current_dbs" 2>/dev/null
rm -f "$current_tmp"
db_changes="$config_dir/db-changes.txt"
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
purge="$config_dir/purge.txt"
cp -f "$current_dbs" "$purge"
echo "$config_dir/current-dbs.txt" >> "$purge"
echo "$config_dir/db-changes.txt" >> "$purge"
echo "$config_dir/last-mbl-update.txt" >> "$purge"
echo "$config_dir/last-si-update.txt" >> "$purge"
echo "$config_dir/local.ign" >> "$purge"
echo "$config_dir/monitor-ign.txt" >> "$purge"
echo "$config_dir/my-whitelist.ign2" >> "$purge"
echo "$config_dir/tracker.txt"  >> "$purge"
echo "$config_dir/previous-dbs.txt" >> "$purge"
echo "$config_dir/scan-test.txt" >> "$purge"
echo "$config_dir/ss-include-dbs.txt" >> "$purge"
echo "$config_dir/whitelist.hex" >> "$purge"
echo "$gpg_dir/publickey.gpg" >> "$purge"
echo "$gpg_dir/secring.gpg" >> "$purge"
echo "$gpg_dir/ss-keyring.gpg*" >> "$purge"
echo "$gpg_dir/trustdb.gpg" >> "$purge"
echo "$log_file_path/$log_file_name*" >> "$purge"
echo "$purge" >> "$purge"

# Silence rsync output and only report errors - useful if script is run via cron.
if [ "$silence_ssl" = "yes" ] ; then
  curl_insecure="--insecure"
fi

# Silence rsync output and only report errors - useful if script is run via cron.
if [ "$rsync_silence" = "yes" ] ; then
 rsync_output_level="-q"
fi

# If the local rsync client supports the '--no-motd' flag, then enable it.
if rsync --help | grep 'no-motd' > /dev/null ; then
 no_motd="--no-motd"
fi

# If the local rsync client supports the '--contimeout' flag, then enable it.
if rsync --help | grep 'contimeout' > /dev/null ; then
 connect_timeout="--contimeout=$rsync_connect_timeout"
fi

# Silence curl output and only report errors - useful if script is run via cron.
if [ "$curl_silence" = "yes" ] ; then
 curl_output_level="-s -S"
fi

#check_clamav

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
   db_file=""
   
   xshok_pretty_echo_and_log "Sanesecurity Database & GPG Signature File Updates" "="
   sanesecurity_mirror_ips=`dig +ignore +short $sanesecurity_url`
   for sanesecurity_mirror_ip in $sanesecurity_mirror_ips ; do
    sanesecurity_mirror_name=`dig +short -x $sanesecurity_mirror_ip | command sed 's/\.$//'`
    sanesecurity_mirror_site_info="$sanesecurity_mirror_name $sanesecurity_mirror_ip"
    xshok_pretty_echo_and_log "Sanesecurity mirror site used: $sanesecurity_mirror_site_info"
    rsync $rsync_output_level $no_motd --files-from=$sanesecurity_include_dbs -ctuz $connect_timeout --timeout="$rsync_max_time" --stats rsync://$sanesecurity_mirror_ip/sanesecurity $sanesecurity_dir
      if [ "$?" -eq "0" ] ; then #the correct way
       sanesecurity_rsync_success="1"
       for db_file in $sanesecurity_dbs ; do
         if ! cmp -s $sanesecurity_dir/$db_file $clam_dbs/$db_file ; then

          xshok_pretty_echo_and_log "Testing updated Sanesecurity database file: $db_file"
          if ! gpg --trust-model always -q --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg \
           --verify $sanesecurity_dir/$db_file.sig $sanesecurity_dir/$db_file 2>/dev/null
           then
           gpg --always-trust -q --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg \
           --verify $sanesecurity_dir/$db_file.sig $sanesecurity_dir/$db_file 2>/dev/null
         fi
         if [ "$?" = "0" ] ; then
           test "$gpg_silence" = "no" && xshok_pretty_echo_and_log "Sanesecurity GPG Signature tested good on $db_file database" ; true
         else
          xshok_pretty_echo_and_log "Sanesecurity GPG Signature test FAILED on $db_file database - SKIPPING" ; false
        fi
        if [ "$?" = "0" ] ; then
         db_ext=`echo $db_file | cut -d "." -f2`
         if [ -z "$ham_dir" -o "$db_ext" != "ndb" ] ; then
          if clamscan --quiet -d "$sanesecurity_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
            then
            xshok_pretty_echo_and_log "Clamscan reports Sanesecurity $db_file database integrity tested good" ; true
          else
           xshok_pretty_echo_and_log "Clamscan reports Sanesecurity $db_file database integrity tested BAD - SKIPPING" ; false
         fi && \
         (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
         if rsync -pcqt $sanesecurity_dir/$db_file $clam_dbs
          then
          perms chown $clam_user:$clam_group $clam_dbs/$db_file
          xshok_pretty_echo_and_log "Successfully updated Sanesecurity production database file: $db_file"
          sanesecurity_update=1
          do_clamd_reload=1
        else
         xshok_pretty_echo_and_log "Failed to successfully update Sanesecurity production database file: $db_file - SKIPPING" ; false
       fi
     else
       grep -h -v -f "$config_dir/whitelist.hex" "$sanesecurity_dir/$db_file" > "$test_dir/$db_file"
       clamscan --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | \
       command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$config_dir/whitelist.txt"
       grep -h -f "$config_dir/whitelist.txt" "$test_dir/$db_file" | \
       cut -d "*" -f2 | sort | uniq >> "$config_dir/whitelist.hex"
       grep -h -v -f "$config_dir/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
       mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
       if clamscan --quiet -d "$test_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
        then
        xshok_pretty_echo_and_log "Clamscan reports Sanesecurity $db_file database integrity tested good" ; true
      else
       xshok_pretty_echo_and_log "Clamscan reports Sanesecurity $db_file database integrity tested BAD - SKIPPING" ; false
     fi && \
     (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
     if rsync -pcqt $test_dir/$db_file $clam_dbs
      then
      perms chown $clam_user:$clam_group $clam_dbs/$db_file
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
fi
fi

##############################################################################################################################################
# Check for updated SecuriteInfo database files every set number of  hours as defined in the "USER CONFIGURATION" section of this script #
##############################################################################################################################################
if [ "$securiteinfo_enabled" == "yes" ] ; then
  if [ "$securiteinfo_authorisation_signature" != "YOUR-SIGNATURE-NUMBER" ] ; then
    if [ -n "$securiteinfo_dbs" ] ; then
     rm -f "$securiteinfo_dir/*.gz"
     if [ -r "$config_dir/last-si-update.txt" ] ; then
      last_securiteinfo_update=`cat $config_dir/last-si-update.txt`
    else
     last_securiteinfo_update="0"
   fi
   db_file=""
   loop=""
   update_interval=$(($securiteinfo_update_hours * 3600))
   time_interval=$(($current_time - $last_securiteinfo_update))
   if [ "$time_interval" -ge $(($update_interval - 600)) ] ; then
    echo "$current_time" > "$config_dir"/last-si-update.txt

    xshok_pretty_echo_and_log "SecuriteInfo Database File Updates" "="
    xshok_pretty_echo_and_log "Checking for SecuriteInfo updates..."
    securiteinfo_updates="0"
    for db_file in $securiteinfo_dbs ; do
      if [ "$loop" = "1" ] ; then
        xshok_pretty_echo_and_log "---"      
      fi
      xshok_pretty_echo_and_log "Checking for updated SecuriteInfo database file: $db_file"

      securiteinfo_db_update="0"
      if [ -r "$securiteinfo_dir/$db_file" ] ; then
       z_opt="-z $securiteinfo_dir/$db_file"
     else
      z_opt=""
    fi
    if curl $curl_proxy $curl_insecure $curl_output_level --connect-timeout "$curl_connect_timeout" \
     --max-time "$curl_max_time" -L -R $z_opt -o "$securiteinfo_dir/$db_file" "$securiteinfo_url/$securiteinfo_authorisation_signature/$db_file"
     then
     loop="1"
     if ! cmp -s $securiteinfo_dir/$db_file $clam_dbs/$db_file ; then
       if [ "$?" = "0" ] ; then
        db_ext=`echo $db_file | cut -d "." -f2`

        xshok_pretty_echo_and_log "Testing updated SecuriteInfo database file: $db_file"
        if [ -z "$ham_dir" -o "$db_ext" != "ndb" ]
         then
         if clamscan --quiet -d "$securiteinfo_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
           then
           xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo $db_file database integrity tested good" ; true
         else
          xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo $db_file database integrity tested BAD - SKIPPING" ; false
          rm -f "$securiteinfo_dir/$db_file"
        fi && \
        (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
        if rsync -pcqt $securiteinfo_dir/$db_file $clam_dbs
         then
         perms chown $clam_user:$clam_group $clam_dbs/$db_file
         xshok_pretty_echo_and_log "Successfully updated SecuriteInfo production database file: $db_file"
         securiteinfo_updates=1
         securiteinfo_db_update=1
         do_clamd_reload=1
       else
        xshok_pretty_echo_and_log "Failed to successfully update SecuriteInfo production database file: $db_file - SKIPPING"
      fi
    else
      grep -h -v -f "$config_dir/whitelist.hex" "$securiteinfo_dir/$db_file" > "$test_dir/$db_file"
      clamscan --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | \
      command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$config_dir/whitelist.txt"
      grep -h -f "$config_dir/whitelist.txt" "$test_dir/$db_file" | \
      cut -d "*" -f2 | sort | uniq >> "$config_dir/whitelist.hex"
      grep -h -v -f "$config_dir/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
      mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
      if clamscan --quiet -d "$test_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
       then
       xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo $db_file database integrity tested good" ; true
     else
      xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo $db_file database integrity tested BAD - SKIPPING" ; false
      rm -f "$securiteinfo_dir/$db_file"
    fi && \
    (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
    if rsync -pcqt $test_dir/$db_file $clam_dbs
     then
     perms chown $clam_user:$clam_group $clam_dbs/$db_file
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

##############################################################################################################################################
# Check for updated linuxmalwaredetect database files every set number of hours as defined in the "USER CONFIGURATION" section of this script 
##############################################################################################################################################
if [ "$linuxmalwaredetect_enabled" == "yes" ] ; then
  if [ -n "$linuxmalwaredetect_dbs" ] ; then
   rm -f "$linuxmalwaredetect_dir/*.gz"
   if [ -r "$config_dir/last-linuxmalwaredetect-update.txt" ] ; then
    last_linuxmalwaredetect_update=`cat $config_dir/last-linuxmalwaredetect-update.txt`
  else
   last_linuxmalwaredetect_update="0"
 fi
 db_file=""
 loop=""
 update_interval=$(($linuxmalwaredetect_update_hours * 3600))
 time_interval=$(($current_time - $last_linuxmalwaredetect_update))
 if [ "$time_interval" -ge $(($update_interval - 600)) ] ; then
  echo "$current_time" > "$config_dir"/last-linuxmalwaredetect-update.txt

  xshok_pretty_echo_and_log "linuxmalwaredetect Database File Updates" "="
  xshok_pretty_echo_and_log "Checking for linuxmalwaredetect updates..."
  linuxmalwaredetect_updates="0"
  for db_file in $linuxmalwaredetect_dbs ; do
    if [ "$loop" = "1" ] ; then
      xshok_pretty_echo_and_log "---"      
    fi
    xshok_pretty_echo_and_log "Checking for updated linuxmalwaredetect database file: $db_file"

    linuxmalwaredetect_db_update="0"
    if [ -r "$linuxmalwaredetect_dir/$db_file" ] ; then
     z_opt="-z $linuxmalwaredetect_dir/$db_file"
   else
    z_opt=""
  fi
  if curl $curl_proxy $curl_insecure $curl_output_level --connect-timeout "$curl_connect_timeout" \
   --max-time "$curl_max_time" -L -R $z_opt -o $linuxmalwaredetect_dir/$db_file "$linuxmalwaredetect_url/$db_file"
   then
   loop="1"
   if ! cmp -s $linuxmalwaredetect_dir/$db_file $clam_dbs/$db_file ; then
     if [ "$?" = "0" ] ; then
      db_ext=`echo $db_file | cut -d "." -f2`

      xshok_pretty_echo_and_log "Testing updated linuxmalwaredetect database file: $db_file"
      if [ -z "$ham_dir" -o "$db_ext" != "ndb" ] ; then
       if clamscan --quiet -d "$linuxmalwaredetect_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
         then
         xshok_pretty_echo_and_log "Clamscan reports linuxmalwaredetect $db_file database integrity tested good" ; true
       else
        xshok_pretty_echo_and_log "Clamscan reports linuxmalwaredetect $db_file database integrity tested BAD - SKIPPING" ; false
        rm -f "$linuxmalwaredetect_dir/$db_file"
      fi && \
      (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
      if rsync -pcqt $linuxmalwaredetect_dir/$db_file $clam_dbs
       then
       perms chown $clam_user:$clam_group $clam_dbs/$db_file
       xshok_pretty_echo_and_log "Successfully updated linuxmalwaredetect production database file: $db_file"
       linuxmalwaredetect_updates=1
       linuxmalwaredetect_db_update=1
       do_clamd_reload=1
     else
      xshok_pretty_echo_and_log "Failed to successfully update linuxmalwaredetect production database file: $db_file - SKIPPING"
    fi
  else
    grep -h -v -f "$config_dir/whitelist.hex" "$linuxmalwaredetect_dir/$db_file" > "$test_dir/$db_file"
    clamscan --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | \
    command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$config_dir/whitelist.txt"
    grep -h -f "$config_dir/whitelist.txt" "$test_dir/$db_file" | \
    cut -d "*" -f2 | sort | uniq >> "$config_dir/whitelist.hex"
    grep -h -v -f "$config_dir/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
    mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
    if clamscan --quiet -d "$test_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
     then
     xshok_pretty_echo_and_log "Clamscan reports linuxmalwaredetect $db_file database integrity tested good" ; true
   else
    xshok_pretty_echo_and_log "Clamscan reports linuxmalwaredetect $db_file database integrity tested BAD - SKIPPING" ; false
    rm -f "$linuxmalwaredetect_dir/$db_file"
  fi && \
  (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
  if rsync -pcqt $test_dir/$db_file $clam_dbs
   then
   perms chown $clam_user:$clam_group $clam_dbs/$db_file
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


##########################################################################################################################################
# Download MalwarePatrol database file every set number of hours as defined in the "USER CONFIGURATION" section of this script.    #
##########################################################################################################################################
if [ "$malwarepatrol_enabled" == "yes" ] ; then
  if [ "$malwarepatrol_receipt_code" != "YOUR-RECEIPT-NUMBER" ] ; then
    if [ -n "$malwarepatrol_db" ] ; then
     if [ -r "$config_dir/last-mbl-update.txt" ] ; then
       last_malwarepatrol_update=`cat $config_dir/last-mbl-update.txt`
     else
       last_malwarepatrol_update="0"
     fi
     db_file=""
     update_interval=$(($malwarepatrol_update_hours * 3600))
     time_interval=$(($current_time - $last_malwarepatrol_update))
     if [ "$time_interval" -ge $(($update_interval - 600)) ] ; then
      echo "$current_time" > "$config_dir"/last-mbl-update.txt
      xshok_pretty_echo_and_log "Checking for MalwarePatrol updates..."
              # Delete the old MBL (mbl.db) database file if it exists and start using the newer
              # format (mbl.ndb) database file instead.
              # test -e $clam_dbs/$malwarepatrol_db -o -e $clam_dbs/$malwarepatrol_db-bak && rm -f -- "$clam_dbs/mbl.d*"

              xshok_pretty_echo_and_log "MalwarePatrol $db_file Database File Update" "="
              
              if [ "$malwarepatrol_free" == "yes" ] ; then
                malwarepatrol_url=$malwarepatrol_free_url
              else
                malwarepatrol_url=$malwarepatrol_subscription_url
              fi

              if curl $curl_proxy $curl_insecure $curl_output_level -R --connect-timeout "$curl_connect_timeout" \
               --max-time "$curl_max_time" -o $malwarepatrol_dir/$malwarepatrol_db "$malwarepatrol_url&receipt=$malwarepatrol_receipt_code"
               then
               if ! cmp -s $malwarepatrol_dir/$malwarepatrol_db $clam_dbs/$malwarepatrol_db 
                 then
                 if [ "$?" = "0" ] ; then

                   xshok_pretty_echo_and_log "Testing updated MalwarePatrol database file: $malwarepatrol_db"
                   if clamscan --quiet -d "$malwarepatrol_dir/$malwarepatrol_db" "$config_dir/scan-test.txt" 2>/dev/null
                    then
                    xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol $malwarepatrol_db database integrity tested good" ; true
                  else
                   xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol $malwarepatrol_db database integrity tested BAD - SKIPPING" ; false
                 fi && \
                 (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$malwarepatrol_db $clam_dbs/$malwarepatrol_db-bak 2>/dev/null ; true) && \
                 if rsync -pcqt $malwarepatrol_dir/$malwarepatrol_db $clam_dbs
                  then
                  perms chown $clam_user:$clam_group $clam_dbs/$malwarepatrol_db
                  xshok_pretty_echo_and_log "Successfully updated MalwarePatrol production database file: $malwarepatrol_db"
                  malwarepatrol_update=1
                  do_clamd_reload=1
                else
                 xshok_pretty_echo_and_log "Failed to successfully update MalwarePatrol production database file: $malwarepatrol_db - SKIPPING"
               fi
             else
               grep -h -v -f "$config_dir/whitelist.hex" "$malwarepatrol_dir/$malwarepatrol_db" > "$test_dir/$malwarepatrol_db"
               clamscan --infected --no-summary -d "$test_dir/$malwarepatrol_db" "$ham_dir"/* | \
               command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$config_dir/whitelist.txt"
               grep -h -f "$config_dir/whitelist.txt" "$test_dir/$malwarepatrol_db" | \
               cut -d "*" -f2 | sort | uniq >> "$config_dir/whitelist.hex"
               grep -h -v -f "$config_dir/whitelist.hex" "$test_dir/$malwarepatrol_db" > "$test_dir/$malwarepatrol_db-tmp"
               mv -f "$test_dir/$malwarepatrol_db-tmp" "$test_dir/$malwarepatrol_db"
               if clamscan --quiet -d "$test_dir/$malwarepatrol_db" "$config_dir/scan-test.txt" 2>/dev/null
                then
                xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol $malwarepatrol_db database integrity tested good" ; true
              else
               xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol $malwarepatrol_db database integrity tested BAD - SKIPPING" ; false
             fi && \
             (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$malwarepatrol_db $clam_dbs/$malwarepatrol_db-bak 2>/dev/null ; true) && \
             if rsync -pcqt $test_dir/$malwarepatrol_db $clam_dbs
              then
              perms chown $clam_user:$clam_group $clam_dbs/$malwarepatrol_db
              xshok_pretty_echo_and_log "Successfully updated MalwarePatrol production database file: $malwarepatrol_db"
              malwarepatrol_update=1
              do_clamd_reload=1
            else
             xshok_pretty_echo_and_log "Failed to successfully update MalwarePatrol production database file: $malwarepatrol_db - SKIPPING"
           fi
         fi
       else

        xshok_pretty_echo_and_log "MalwarePatrol signature database ($malwarepatrol_db) did not change - skipping"
      fi
    else
      xshok_pretty_echo_and_log "WARNING - Failed curl connection to $malwarepatrol_url - SKIPPED MalwarePatrol $malwarepatrol_db update"
    fi
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
fi

##############################################################################################################################################
# Check for updated yararules database files every set number of hours as defined in the "USER CONFIGURATION" section of this script 
##############################################################################################################################################
if [ "yararules_enabled" == "yes" ] ; then
  if [ -n "$yararules_dbs" ] ; then
   rm -f "$yararules_dir/*.gz"
   if [ -r "$config_dir/last-yararules-update.txt" ] ; then
    last_yararules_update=`cat $config_dir/last-yararules-update.txt`
  else
   last_yararules_update="0"
 fi
 db_file=""
 loop=""
 update_interval=$(($yararules_update_hours * 3600))
 time_interval=$(($current_time - $last_yararules_update))
 if [ "$time_interval" -ge $(($update_interval - 600)) ] ; then
  echo "$current_time" > "$config_dir"/last-yararules-update.txt

  cxshok_pretty_echo_and_log "Yara-Rules Database File Updates" "="
  xshok_pretty_echo_and_log "Checking for yararules updates..."
  yararules_updates="0"
  for db_file in $yararules_dbs ; do
    if [ "$loop" = "1" ] ; then
      xshok_pretty_echo_and_log "---"      
    fi
    xshok_pretty_echo_and_log "Checking for updated yararules database file: $db_file"

    yararules_db_update="0"
    if [ -r "$yararules_dir/$db_file" ] ; then
     z_opt="-z $yararules_dir/$db_file"
   else
    z_opt=""
  fi
  if curl $curl_proxy $curl_insecure $curl_output_level --connect-timeout "$curl_connect_timeout" \
   --max-time "$curl_max_time" -L -R $z_opt -o $yararules_dir/$db_file "$yararules_url/$db_file"
   then
   loop="1"
   if ! cmp -s $yararules_dir/$db_file $clam_dbs/$db_file ; then
     if [ "$?" = "0" ] ; then
      db_ext=`echo $db_file | cut -d "." -f2`

      xshok_pretty_echo_and_log "Testing updated yararules database file: $db_file"
      if [ -z "$ham_dir" -o "$db_ext" != "ndb" ] ; then
       if clamscan --quiet -d "$yararules_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
         then
         xshok_pretty_echo_and_log "Clamscan reports yararules $db_file database integrity tested good" ; true
       else
        xshok_pretty_echo_and_log "Clamscan reports yararules $db_file database integrity tested BAD - SKIPPING" ; false
        rm -f "$yararules_dir/$db_file"
      fi && \
      (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
      if rsync -pcqt $yararules_dir/$db_file $clam_dbs
       then
       perms chown $clam_user:$clam_group $clam_dbs/$db_file
       xshok_pretty_echo_and_log "Successfully updated yararules production database file: $db_file"
       yararules_updates=1
       yararules_db_update=1
       do_clamd_reload=1
     else
      xshok_pretty_echo_and_log "Failed to successfully update yararules production database file: $db_file - SKIPPING"
    fi
  else
    grep -h -v -f "$config_dir/whitelist.hex" "$yararules_dir/$db_file" > "$test_dir/$db_file"
    clamscan --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | \
    command sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$config_dir/whitelist.txt"
    grep -h -f "$config_dir/whitelist.txt" "$test_dir/$db_file" | \
    cut -d "*" -f2 | sort | uniq >> "$config_dir/whitelist.hex"
    grep -h -v -f "$config_dir/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
    mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
    if clamscan --quiet -d "$test_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
     then
     xshok_pretty_echo_and_log "Clamscan reports yararules $db_file database integrity tested good" ; true
   else
    xshok_pretty_echo_and_log "Clamscan reports yararules $db_file database integrity tested BAD - SKIPPING" ; false
    rm -f "$yararules_dir/$db_file"
  fi && \
  (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
  if rsync -pcqt $test_dir/$db_file $clam_dbs
   then
   perms chown $clam_user:$clam_group $clam_dbs/$db_file
   xshok_pretty_echo_and_log "Successfully updated yararules production database file: $db_file"
   yararules_updates=1
   yararules_db_update=1
   do_clamd_reload=1
 else
  xshok_pretty_echo_and_log "Failed to successfully update yararules production database file: $db_file - SKIPPING"
fi
fi
fi
fi
else
  xshok_pretty_echo_and_log "WARNING: Failed curl connection to $yararules_url - SKIPPED yararules $db_file update"
fi
if [ "$yararules_db_update" != "1" ] ; then
 xshok_pretty_echo_and_log "No updated yararules $db_file database file found"
fi
done
if [ "$yararules_updates" != "1" ] ; then
  xshok_pretty_echo_and_log "No yararules database file updates found" "-"
fi
else

 xshok_pretty_echo_and_log "Yara-Rules Database File Updates" "="

 time_remaining=$(($update_interval - $time_interval))
 hours_left=$(($time_remaining / 3600))
 minutes_left=$(($time_remaining % 3600 / 60))
 xshok_pretty_echo_and_log "$yararules_update_hours hours have not yet elapsed since the last linux malware detect update check"
 xshok_pretty_echo_and_log "No update check was performed at this time" "-"
 xshok_pretty_echo_and_log "Next check will be performed in approximately $hours_left hour(s), $minutes_left minute(s)"
fi
fi
fi


###################################################
# Check for user added signature database updates #
###################################################
if [ -n "$add_dbs" ] ; then

 xshok_pretty_echo_and_log "User Added Signature Database File Update(s)" "="

 for db_url in $add_dbs ; do
  base_url=`echo $db_url | cut -d "/" -f3`
  db_file=`basename $db_url`
  if [ "`echo $db_url | cut -d ":" -f1`" = "rsync" ] ; then
   if ! rsync $rsync_output_level $no_motd $connect_timeout --timeout="$rsync_max_time" --exclude=*.txt \
     -crtuz --stats --exclude=*.sha256 --exclude=*.sig --exclude=*.gz $db_url $add_dir ; then
     xshok_pretty_echo_and_log "Failed rsync connection to $base_url - SKIPPED $db_file update"
   fi
 else
   if [ -r "$add_dir/$db_file" ] ; then
    z_opt="-z $add_dir/$db_file"
  else
   z_opt=""
 fi
 if ! curl $curl_output_level --connect-timeout "$curl_connect_timeout" --max-time \
  "$curl_max_time" -L -R $z_opt -o $add_dir/$db_file $db_url ; then
  xshok_pretty_echo_and_log "Failed curl connection to $base_url - SKIPPED $db_file update"
fi
fi
done
db_file=""
for db_file in `ls $add_dir`; do
  if ! cmp -s $add_dir/$db_file $clam_dbs/$db_file ; then

   xshok_pretty_echo_and_log "Testing updated database file: $db_file"
   clamscan --quiet -d "$add_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
   if [ "$?" = "0" ] ; then
    xshok_pretty_echo_and_log "Clamscan reports $db_file database integrity tested good" ; true
  else
   xshok_pretty_echo_and_log "Clamscan reports User Added $db_file database integrity tested BAD - SKIPPING" ; false
 fi && \
 (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
 if rsync -pcqt $add_dir/$db_file $clam_dbs
  then
  perms chown $clam_user:$clam_group $clam_dbs/$db_file
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

###################################################
# Generate whitelists
###################################################
# Check to see if the local.ign file exists, and if it does, check to see if any of the script
# added bypass entries can be removed due to offending signature modifications or removals.
if [ -r "$clam_dbs/local.ign" -a -s "$config_dir/monitor-ign.txt" ] ; then
 ign_updated=0
 cd "$clam_dbs"
 cp -f local.ign "$config_dir/local.ign"
 cp -f "$config_dir/monitor-ign.txt" "$config_dir/monitor-ign-old.txt"

 xshok_pretty_echo_and_log "" "=" "80"
 for entry in `cat "$config_dir/monitor-ign-old.txt" 2>/dev/null` ; do
  sig_file=`echo "$entry" | tr -d "\r" | awk -F ":" '{print $1}'`
  sig_hex=`echo "$entry" | tr -d "\r" | awk -F ":" '{print $NF}'`
  sig_name_old=`echo "$entry" | tr -d "\r" | awk -F ":" '{print $3}'`
  sig_ign_old=`grep ":$sig_name_old" "$config_dir/local.ign"`
  sig_old=`echo "$entry" | tr -d "\r" | cut -d ":" -f3-`
  sig_new=`grep -hwF ":$sig_hex" "$sig_file" | tr -d "\r" 2>/dev/null`
  sig_mon_new=`grep -HwF -n ":$sig_hex" "$sig_file" | tr -d "\r"`
  if [ -n "$sig_new" ] ; then
   if [ "$sig_old" != "$sig_new" -o "$entry" != "$sig_mon_new" ] ; then
     sig_name_new=`echo "$sig_new" | tr -d "\r" | awk -F ":" '{print $1}'`
     sig_ign_new=`echo "$sig_mon_new" | cut -d ":" -f1-3`
     perl -i -ne "print unless /$sig_ign_old/" "$config_dir/monitor-ign.txt"
     echo "$sig_mon_new" >> "$config_dir/monitor-ign.txt"
     perl -p -i -e "s/$sig_ign_old/$sig_ign_new/" "$config_dir/local.ign"
     xshok_pretty_echo_and_log "$sig_name_old hexadecimal signature is unchanged, however signature name and/or line placement"
     xshok_pretty_echo_and_log "in $sig_file has changed to $sig_name_new - updated local.ign to reflect this change."
     ign_updated=1
   fi
 else
  perl -i -ne "print unless /$sig_ign_old/" "$config_dir/monitor-ign.txt" "$config_dir/local.ign"

  xshok_pretty_echo_and_log "$sig_name_old signature has been removed from $sig_file, entry removed from local.ign."
  ign_updated=1
fi
done
if [ "$ign_updated" = "1" ] ; then
  if clamscan --quiet -d "$config_dir/local.ign" "$config_dir/scan-test.txt"
    then
    if rsync -pcqt $config_dir/local.ign $clam_dbs
      then
      perms chown $clam_user:$clam_group "$clam_dbs/local.ign"
      chmod 0644 "$clam_dbs/local.ign" "$config_dir/monitor-ign.txt"
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
if [ -r "$clam_dbs/my-whitelist.ign2" -a -s "$config_dir/tracker.txt" ] ; then
 ign2_updated=0
 cd "$clam_dbs"
 cp -f my-whitelist.ign2 "$config_dir/my-whitelist.ign2"

 xshok_pretty_echo_and_log "" "=" "80"
 for entry in `cat "$config_dir/tracker.txt" 2>/dev/null` ; do
  sig_file=`echo "$entry" | cut -d ":" -f1`
  sig_full=`echo "$entry" | cut -d ":" -f2-`
  sig_name=`echo "$entry" | cut -d ":" -f2`
  if ! grep -F "$sig_full" "$sig_file" > /dev/null 2>&1 ; then
   perl -i -ne "print unless /$sig_name$/" "$config_dir/my-whitelist.ign2"
   perl -i -ne "print unless /:$sig_name:/" "$config_dir/tracker.txt"

   xshok_pretty_echo_and_log "$sig_name signature no longer exists in $sig_file, whitelist entry removed from my-whitelist.ign2"
   ign2_updated=1
 fi
done

xshok_pretty_echo_and_log "" "=" "80"
if [ "$ign2_updated" = "1" ]
  then
  if clamscan --quiet -d "$config_dir/my-whitelist.ign2" "$config_dir/scan-test.txt"
    then
    if rsync -pcqt $config_dir/my-whitelist.ign2 $clam_dbs
      then
      perms chown $clam_user:$clam_group "$clam_dbs/my-whitelist.ign2"
      chmod 0644 "$clam_dbs/my-whitelist.ign2" "$config_dir/tracker.txt"
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
 if [ -r "$config_dir/whitelist.hex" ] ; then
  grep -h -f "$config_dir/whitelist.hex" "$work_dir"/*/*.ndb | cut -d "*" -f2 | tr -d "\r" | sort | uniq > "$config_dir/whitelist.tmp"
  mv -f "$config_dir/whitelist.tmp" "$config_dir/whitelist.hex"
  rm -f "$config_dir/whitelist.txt"
  rm -f "$test_dir"/*.*
  xshok_pretty_echo_and_log "WARNING: Signature(s) triggered on HAM directory scan - signature(s) removed" "*"
else
 xshok_pretty_echo_and_log "No signatures triggered on HAM directory scan" "="
fi
fi

# Set appropriate directory and file permissions to all production signature files
# and set file access mode to 0644 on all working directory files.
perms chown -R $clam_user:$clam_group "$clam_dbs"
if ! find "$work_dir" -type f -exec chmod 0644 {} + 2>/dev/null ; then
 if ! find "$work_dir" -type f -print0 | xargs -0 chmod 0644 2>/dev/null ; then
  if ! find "$work_dir" -type f | xargs chmod 0644 2>/dev/null ; then
   find "$work_dir" -type f -exec chmod 0644 {} \;
 fi
fi
fi

# If enabled, set file access mode for all production signature database files to 0644.
if [ "$setmode" = "yes" ] ; then
 if ! find "$clam_dbs" -type f -exec chmod 0644 {} + 2>/dev/null ; then
  if ! find "$clam_dbs" -type f -print0 | xargs -0 chmod 0644 2>/dev/null ; then
   if ! find "$clam_dbs" -type f | xargs chmod 0644 2>/dev/null ; then
    find "$clam_dbs" -type f -exec chmod 0644 {} \;
  fi
fi
fi
fi

# Reload all clamd databases  
clamscan_reload_dbs


xshok_pretty_echo_and_log "      Powered By https://eXtremeSHOK.com      " "#"

# And lastly we exit
exit $?
