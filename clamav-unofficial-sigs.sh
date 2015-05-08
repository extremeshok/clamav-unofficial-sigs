#!/bin/sh

# This script freely provided by Bill Landry (unofficialsigs@gmail.com).
# Comments, suggestions, and recommendations for improving this script
# are always welcome.
#
# Script updates can be found at: http://sourceforge.net/projects/unofficial-sigs
#
# License: BSD (Berkeley Software Distribution)

################################################################################
#                                                                              #
#            THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT             #
#                                    * * *                                     #
#   ALL CONFIGURATION OPTIONS ARE LOCATED IN THE INCLUDED CONFIGURATION FILE   #
#                                                                              #
################################################################################

default_config="/etc/clamav-unofficial-sigs.conf"

version="v3.7.2 (updated 2013-08-25)"
output_ver="
   `basename $0` $version
"

usage="
ClamAV Unofficial Signature Databases Update Script - $version

   Usage: `basename $0` [OPTION] [PATH|FILE]

        -b      DEPRECATED - Consider using -w instead, it supports
                the newer ClamAV signature whitelist funtionality.
                ----------------------------------------------------------
                Add a bypass signature entry to local.ign in order to
                temporarily resolve a false-positive issue with a specific
                third-party signature.  The script added local.ign entries
                will automatically be removed if the original signature is
                either modified or removed from the third-party database.

        -c      Direct script to use a specific configuration file
                e.g.: '-c /path/to/`basename "$default_config"`'.

        -d      Decode a third-party signature either by signature name
                (e.g: Sanesecurity.Junk.15248) or hexadecimal string.
                This flag will 'NOT' decode image signatures.

        -e      Hexadecimal encode an entire input string that can be
                used in any '*.ndb' signature database file.

        -f      Hexadecimal encode a formatted input string containing
                signature spacing fields '{}, (), *', without encoding 
                the spacing fields, so that the encoded signature can
                be used in any '*.ndb' signature database file.

        -g      GPG verify a specific Sanesecurity database file
                e.g.: '-g filename.ext' (do not include file path).

        -h      Display this script's help and usage information.

        -i      Output system and configuration information for
                viewing or possible debugging purposes.

        -m      Make a signature database from an ascii file containing
                data strings, with one data string per line.  Additional
                information is provided when using this flag.

        -r      Remove the clamav-unofficial-sigs script and all of
                its associated files and databases from the system.

        -s      Clamscan integrity test a specific database file
                e.g.: '-s filename.ext' (do not include file path).

        -t      If HAM directory scanning is enabled in the script's
                configuration file, then output names of any third-party
                signatures that triggered during the HAM directory scan.

        -v      Output script version and date information.

        -w      Adds a signature whitelist entry in the newer ClamAV IGN2
                format to 'my-whitelist.ign2' in order to temporarily resolve
                a false-positive issue with a specific third-party signature.
                Script added whitelist entries will automatically be removed
                if the original signature is either modified or removed from
                the third-party signature database.

Alternative to using '-c': Place config file in /etc ($default_config)
"

# Function to handle general response if script cannot find the config file in /etc.
no_default_config () {
if [ ! -s "$default_config" ] ; then
   echo ""
   echo "Cannot find your configuration file - place a copy in /etc and try again..."
   echo ""
   echo "     e.g.: $default_config"
   echo ""
   exit
fi
. "$default_config"
echo ""
}

# Function to support user config settings for applying file and directory access permissions.
perms () {
   if [ -n "$clam_user" -a -n "$clam_group" ] ; then
      "${@:-}"
   fi
}

# Take input from the commandline and process.
while getopts 'bc:defg:himrs:tvw' option ; do
   case $option in
      b)  no_default_config
          echo "Input a third-party signature name that you wish to bypass due to false-positives"
          echo "and press enter (do not include '.UNOFFICIAL' in the signature name nor add quote"
          echo "marks to any input string):"
          echo ""
          read input
          if [ -n "$input" ]
             then
                cd "$clam_dbs"
                input=`echo "$input" | tr -d "'" | tr -d '"'`
                file_sig=`grep -n "$input:" *.ndb`
                sig_ign=`echo "$file_sig" | cut -d ":" -f-3`
                if [ -n "$sig_ign" ]
                   then
                      if ! grep "$sig_ign" local.ign > /dev/null 2>&1
                         then
                            cp -f local.ign "$config_dir" 2>/dev/null
                            echo "$sig_ign" | tr -d "\r" >> "$config_dir/local.ign"
                            echo "$file_sig" | tr -d "\r" >> "$config_dir/monitor-ign.txt"
                            if clamscan --quiet -d "$config_dir/local.ign" "$config_dir/scan-test.txt"
                               then
                                  if rsync -pcqt $config_dir/local.ign $clam_dbs
                                     then
                                        perms chown $clam_user:$clam_group local.ign
                                        chmod 0644 local.ign "$config_dir/monitor-ign.txt"
                                        $reload_opt
                                        echo ""
                                        echo "Signature '$input' has been added to the local.ign signature bypass"
                                        echo "file and databases have been reloaded.  The script will track any changes to the"
                                        echo "offending third-party signature and will automatically remove the signature bypass"
                                        echo "entry if either the signature is modified or removed from the third-party database."
                                     else
                                        echo ""
                                        echo "Failed to successfully update local.ign file - SKIPPING."
                                  fi
                               else
                                  echo ""
                                  echo "Clamscan reports local.ign database integrity is bad - SKIPPING."
                            fi
                         else
                            echo ""
                            echo "Signature '$input' already exists in local.ign - no action taken."
                      fi
                   else
                      echo ""
                      echo "Signature '$input' could not be found."
                      echo ""
                      echo "This script will only create a bypass entry in local.ign for ClamAV"
                      echo "'UNOFFICIAL' third-Party signatures as found in the *.ndb databases."
                fi
             else
                echo "No input detected - no action taken."
          fi
          echo ""
          exit
          ;;
      c)  conf_file="$OPTARG"
          ;;
      d)  no_default_config
          echo "Input a third-party signature name to decode (e.g: Sanesecurity.Junk.15248) or"
          echo "a hexadecimal encoded data string and press enter (do not include '.UNOFFICIAL'"
          echo "in the signature name nor add quote marks to any input string):"
          echo ""
          read input
          input=`echo "$input" | tr -d "'" | tr -d '"'`
          echo ""
          if `echo "$input" | grep "\." > /dev/null`
             then
                cd "$clam_dbs"
                sig=`grep "$input:" *.ndb`
                if [ -n "$sig" ]
                   then
                      db_file=`echo "$sig" | cut -d ':' -f1`
                      echo "$input found in: $db_file"
                      echo "$input signature decodes to:"
                      echo ""
                      echo "$sig" | cut -d ":" -f5 | perl -pe 's/([a-fA-F0-9]{2})|(\{[^}]*\}|\([^)]*\))/defined $2 ? $2 : chr(hex $1)/eg'
                   else
                      echo "Signature '$input' could not be found."
                      echo ""
                      echo "This script will only decode ClamAV 'UNOFFICIAL' third-Party,"
                      echo "non-image based, signatures as found in the *.ndb databases."
                fi
            else
               echo "Here is the decoded hexadecimal input string:"
               echo ""
               echo "$input" | perl -pe 's/([a-fA-F0-9]{2})|(\{[^}]*\}|\([^)]*\))/defined $2 ? $2 : chr(hex $1)/eg'
          fi
          echo ""
          exit
          ;;
      e)  no_default_config
          echo "Input the data string that you want to hexadecimal encode and then press enter.  Do not include"
          echo "any quotes around the string unless you want them included in the hexadecimal encoded output:"
          echo ""
          read input
          echo ""
          echo "Here is the hexadecimal encoded input string:"
          echo ""
          echo "$input" | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg'
          echo ""
          exit
          ;;
      f)  no_default_config
          echo "Input a formated data string containing spacing fields '{}, (), *' that you want to hexadecimal"
          echo "encode, without encoding the spacing fields, and then press enter.  Do not include any quotes"
          echo "around the string unless you want them included in the hexadecimal encoded output:"
          echo ""
          read input
          echo ""
          echo "Here is the hexadecimal encoded input string:"
          echo ""
          echo "$input" | perl -pe 's/(\{[^}]*\}|\([^)]*\)|\*)|(.)/defined $1 ? $1 : sprintf("%02lx", ord $2)/eg'
          echo ""
          exit
          ;;
      g)  no_default_config
          db_file=`echo "$OPTARG" | awk -F '/' '{print $NF}'`
          if [ -s "$ss_dir/$db_file" ]
             then
                echo "GPG signature testing database file: $ss_dir/$db_file"
                echo ""
                if ! gpg --trust-model always -q --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg \
                     --verify $ss_dir/$db_file.sig $ss_dir/$db_file
                   then
                     gpg --always-trust -q --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg \
                     --verify $ss_dir/$db_file.sig $ss_dir/$db_file
                fi
             else
                echo "File '$db_file' cannot be found or is not a Sanesecurity database file."
                echo "Only the following Sanesecurity and OITC databases can be GPG signature tested:"
                echo "$ss_dbs"
                echo "Check the file name and try again..."
          fi
          echo ""
          exit
          ;;
      h)  echo "$usage"
          exit
          ;;
      i)  no_default_config
          echo "*** SCRIPT VERSION ***"
          echo "`basename $0` $version"
          echo ""
          echo "*** SYSTEM INFORMATION ***"
          uname=`which uname`
          $uname -a
          echo ""
          echo "*** CLAMSCAN LOCATION & VERSION ***"
          clamscan=`which clamscan`
          echo "$clamscan"
          $clamscan --version | head -1
          echo ""
          echo "*** RSYNC LOCATION & VERSION ***"
          rsync=`which rsync`
          echo "$rsync"
          $rsync --version | head -1
          echo ""
          echo "*** CURL LOCATION & VERSION ***"
          curl=`which curl`
          echo "$curl"
          $curl --version | head -1
          echo ""
          echo "*** GPG LOCATION & VERSION ***"
          gpg=`which gpg`
          echo "$gpg"
          $gpg --version | head -1
          echo ""
          echo "*** SCRIPT WORKING DIRECTORY INFORMATION ***"
          ls -ld $work_dir
          echo ""
          ls -lR $work_dir | grep -v total
          echo ""
          echo "*** CLAMAV DIRECTORY INFORMATION ***"
          ls -ld $clam_dbs
          echo "---"
          ls -l $clam_dbs | grep -v total
          echo ""
          echo "*** SCRIPT CONFIGURATION SETTINGS ***"
          egrep -v "^#|^$" $default_config
          echo ""
          exit
          ;;
      m)  no_default_config
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
          " | sed 's/^          //g'
          echo -n "Do you wish to continue? (y/n): "
          read reply
          if [ "$reply" = "y" -o "$reply" = "Y" ]
             then
                echo ""
                echo -n "Enter the source file as /path/filename: "
                read source
                if [ -s "$source" ]
                   then
                      source_file=`basename "$source"`
                      echo ""
                      echo "What signature prefix would you like to use?  For example: 'Phish.Domains'"
                      echo "will create signatures that looks like: 'Phish.Domains.1:4:*:HexSigHere'"
                      echo ""
                      echo -n "Enter signature prefix: "
                      read prefix
                      path_file=`echo "$source" | cut -d "." -f-1 | sed 's/$/.ndb/'`
                      db_file=`basename $path_file`
                      rm -f "$path_file"
                      total=`wc -l "$source" | cut -d " " -f1`
                      line_num=1
                      echo ""
                      cat "$source" | while read line ; do
                         line_prefix=`echo "$line" | awk -F ':' '{print $1}'`
                         if [ "$line_prefix" = "-" ]
                            then
                               echo "$line" | cut -d ":" -f2- | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg' | \
                               sed "s/^/$prefix\.$line_num:4:\*:/" >> "$path_file"
                            elif [ "$line_prefix" = "=" ] ; then
                               echo "$line" | cut -d ":" -f2- | perl -pe 's/(\{[^}]*\}|\([^)]*\)|\*)|(.)/defined \
                               $1 ? $1 : sprintf("%02lx", ord $2)/eg' | sed "s/^/$prefix\.$line_num:4:\*:/" >> "$path_file"
                            else
                               echo "$line" | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg' | sed "s/^/$prefix\.$line_num:4:\*:/" >> "$path_file"
                         fi
                         printf "Hexadecimal encoding $source_file line: $line_num of $total\r"
                         line_num=$(($line_num + 1))
                      done
                   else
                      echo ""
                      echo "Source file not found, exiting..."
                      echo ""
                      exit
                fi
                echo ""
                echo ""
                echo "Signature database file created at: $path_file"
                if clamscan --quiet -d "$path_file" "$config_dir/scan-test.txt" 2>/dev/null
                   then
                      echo ""
                      echo "Clamscan reports database integrity tested good."
                      echo ""
                      echo -n "Would you like to move '$db_file' into '$clam_dbs' and reload databases? (y/n): "
                      read reply
                      if [ "$reply" = "y" -o "$reply" = "Y" ]
                         then
                            if ! cmp -s "$path_file" "$clam_dbs/$db_file"
                               then
                                  if rsync -pcqt "$path_file" "$clam_dbs"
                                     then
                                        perms chown $clam_user:$clam_group "$clam_dbs/$db_file"
                                        chmod 0644 "$clam_dbs/$db_file"
                                        $reload_opt
                                        echo ""
                                        echo "Signature database '$db_file' was successfully implemented and ClamD databases reloaded."
                                     else
                                        echo ""
                                        echo "Failed to add/update '$db_file', ClamD database not reloaded."
                                  fi
                               else
                                  echo ""
                                  echo "Database '$db_file' has not changed - skipping"
                            fi
                         else
                            echo ""
                            echo "No action taken."
                      fi
                   else
                      echo ""
                      echo "Clamscan reports that '$db_file' signature database integrity tested bad."
                fi
          fi
          echo ""
          exit
          ;;
      r)  no_default_config
          if [ -n "$pkg_mgr" -a -n "$pkg_rm" ]
             then
                echo "  This script (clamav-unofficial-sigs) was installed on the system"
                echo "  via '$pkg_mgr', use '$pkg_rm' to remove the script"
                echo "  and all of its associated files and databases from the system."
                echo ""
             else
                echo "  Are you sure you want to remove the clamav-unofficial-sigs script and all of its"
                echo -n "  associated files, third-party databases, and work directories from the system? (y/n): "
                read response
                if [ "$response" = "y" -o "$response" = "Y" ]
                   then
                      if [ -s "$config_dir/purge.txt" ] 
                         then
                            echo ""
                            for file in `cat $config_dir/purge.txt` ; do
                               rm -f -- "$file"
                               echo "     Removed file: $file"
                            done
                            cron_file=`find /etc/ -name clamav-unofficial-sigs-cron`
                            if [ -s "$cron_file" ] ; then
                               rm -f "$cron_file"
                               echo "     Removed file: $cron_file"
                            fi
                            log_rotate_file=`find /etc/ -name clamav-unofficial-sigs-logrotate`
                            if [ -s "$log_rotate_file" ] ; then
                               rm -f "$log_rotate_file"
                               echo "     Removed file: $log_rotate_file"
                            fi
                            rm -f -- "$default_config" && echo "     Removed file: $default_config"
                            rm -f -- "$0" && echo "     Removed file: $0"
                            rm -rf -- "$work_dir" && echo "     Removed script working directories: $work_dir"
                            echo ""
                            echo "  The clamav-unofficial-sigs script and all of its associated files, third-party"
                            echo "  databases, and work directories have been successfully removed from the system."
                            echo ""
                         else
                            echo "  Cannot locate 'purge.txt' file in $config_dir."
                            echo "  Files and signature database will need to be removed manually."
                            echo ""
                      fi
                   else
                      echo "$usage"
                fi
          fi
          exit
          ;;
      s)  no_default_config
          input=`echo "$OPTARG" | awk -F '/' '{print $NF}'`
          db_file=`find $work_dir -name $input`
          if [ -s "$db_file" ]
             then
                echo "Clamscan integrity testing: $db_file"
                echo ""
                if clamscan --quiet -d "$db_file" "$config_dir/scan-test.txt" ; then
                   echo "Clamscan reports that '$input' database integrity tested GOOD"
                fi
             else
                echo "File '$input' cannot be found."
                echo "Here is a list of third-party databases that can be clamscan integrity tested:"
                echo ""
                echo "Sanesecurity $ss_dbs""SecuriteInfo $si_dbs""MalwarePatrol $mbl_dbs"
                echo "Check the file name and try again..."
          fi
          echo ""
          exit
          ;;
      t)  no_default_config
          if [ -n "$ham_dir" ]
             then
                if [ -s "$config_dir/whitelist.hex" ]
                   then
                      echo "The following third-party signatures triggered hits during the HAM Directory scan:"
                      echo ""
                      grep -h -f "$config_dir/whitelist.hex" "$work_dir"/*/*.ndb | cut -d ":" -f1
                   else
                      echo "No third-party signatures have triggered hits during the HAM Directory scan."
                fi
             else
                echo "Ham directory scanning is not currently enabled in the script's configuration file."
          fi
          echo ""
          exit
          ;;
      v)  echo "$output_ver"
          exit
          ;;
      w)  no_default_config
          echo "Input a third-party signature name that you wish to whitelist due to false-positives"
          echo "and press enter (do not include '.UNOFFICIAL' in the signature name nor add quote"
          echo "marks to the input string):"
          echo ""
          read input
          if [ -n "$input" ]
             then
                cd "$clam_dbs"
                input=`echo "$input" | tr -d "'" | tr -d '"'`
                sig_full=`grep -H "$input:" *.ndb`
                sig_name=`echo "$sig_full" | cut -d ":" -f2`
                if [ -n "$sig_name" ]
                   then
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
                                        chmod 0644 my-whitelist.ign2 "$config_dir/monitor-ign.txt"
                                        $reload_opt
                                        echo ""
                                        echo "Signature '$input' has been added to my-whitelist.ign2 and"
                                        echo "all databases have been reloaded.  The script will track any changes"
                                        echo "to the offending signature and will automatically remove it if the"
                                        echo "signature is modified or removed from the third-party database."
                                     else
                                        echo ""
                                        echo "Failed to successfully update my-whitelist.ign2 file - SKIPPING."
                                  fi
                               else
                                  echo ""
                                  echo "Clamscan reports my-whitelist.ign2 database integrity is bad - SKIPPING."
                            fi
                         else
                            echo ""
                            echo "Signature '$input' already exists in my-whitelist.ign2 - no action taken."
                      fi
                   else
                      echo ""
                      echo "Signature '$input' could not be found."
                      echo ""
                      echo "This script will only create a whitelise entry in my-whitelist.ign2 for ClamAV"
                      echo "'UNOFFICIAL' third-Party signatures as found in the *.ndb databases."
                fi
             else
                echo "No input detected - no action taken."
          fi
          echo ""
          exit
          ;;
      *)  echo "$usage"
          exit
          ;;
   esac
done

# Handle '-c' config file location issues.
if [ "$1" = -c ] ;
   then
      if [ ! -s "$conf_file" ] ; then
         echo ""
         echo "   Config file does not exist at: $2"
         echo "   Check the config file path and try again..."
         echo "$usage"
         exit
      fi
      if [ "`basename "$conf_file"`" != "`basename "$default_config"`" ] ; then
         echo ""
         echo "   Invalid config file: $2"
         echo "   Config file must be named: `basename $default_config`"
         echo "$usage"
         exit
      fi
      config_source="$conf_file"
   else
      if [ $# -ne 0 ] ; then
         echo ""
         echo "   Invalid option: $1"
         echo "$usage"
         exit
      fi
      if [ ! -s "$default_config" ] ; then
         echo ""
         echo "   Cannot find default config file at: $default_config"
         echo "$usage"
         exit
      fi
      config_source="$default_config"
fi

. "$config_source"

################################################################################

# Using functions here to handle config settings for script comments and logging.
comment () {
   test "$comment_silence" = "no" && echo "${@:-}"
}

log () {
   test "$enable_logging" = "yes" && echo `date "+%b %d %T"` "${@:-}" >> "$log_file_path/$log_file_name"
}

# Check to see if the script's "USER CONFIGURATION FILE" has been completed.
if [ "$user_configuration_complete" != "yes" ]
   then
      echo ""
      echo "              *** SCRIPT CONFIGURATION HAS NOT BEEN COMPLETED ***"
      echo "   Please review the script configuration file: `basename $default_config`."
      echo "       Once the user configuration has been completed, rerun the script."
      echo ""
      log "ALERT - SCRIPT HALTED, user configuration not completed"
   exit 1
fi

# If "ham_dir" variable is set, then create initial whitelist files (skipped if first-time script run).
test_dir="$work_dir/test"
if [ -n "$ham_dir" -a -d "$work_dir" -a ! -d "$test_dir" ] ; then
   if [ -d "$ham_dir" ]
      then
         mkdir -p "$test_dir"
         cp -f "$work_dir"/*/*.ndb "$test_dir"
         clamscan --infected --no-summary -d "$test_dir" "$ham_dir"/* | \
         sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' >> "$config_dir/whitelist.txt"
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
         if [ -s "$config_dir/whitelist.hex" ]
            then
               echo "*** Initial HAM directory scan whitelist file created in $config_dir ***"
               echo ""
               log "INFO - Initial HAM directory scan whitelist file created in $config_dir"
            else
               echo "No false-positives detected in initial HAM directory scan"
               log "No false-positives detected in initial HAM directory scan"
         fi
      else
         echo "Cannot locate HAM directory: $ham_dir"
         echo "Skipping initial whitelist file creation.  Fix 'ham_dir' path in config file"
         log "WARNING - Cannot locate HAM directory: $ham_dir"
         log "WARNING - Skipping initial whitelist file creation.  Fix 'ham_dir' path in config file"
   fi
fi

# Check to see if the working directories have been created.
# If not, create them.  Otherwise, ignore and proceed with script.
mkdir -p "$work_dir" "$ss_dir" "$si_dir" "$mbl_dir" "$config_dir" "$gpg_dir" "$add_dir"

# Set secured access permissions to the GPG directory
chmod 0700 "$gpg_dir"

# If we haven't done so yet, download Sanesecurity public GPG key and import to custom keyring.
if [ ! -s "$gpg_dir/publickey.gpg" ] ; then
   if ! curl -s -S $curl_proxy --connect-timeout "$curl_connect_timeout" --max-time "$curl_max_time" \
        -L -R http://www.sanesecurity.net/publickey.gpg -o $gpg_dir/publickey.gpg
      then
         echo ""
         echo "Could not download Sanesecurity public GPG key"
         log "ALERT - Could not download Sanesecurity public GPG key"
         exit 1
      else
         comment ""
         comment "Sanesecurity public GPG key successfully downloaded"
         comment ""
         log "INFO - Sanesecurity public GPG key successfully downloaded"
         rm -f -- "$gpg_dir/ss-keyring.gp*"
         if ! gpg -q --no-options --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg \
              --import $gpg_dir/publickey.gpg 2>/dev/null
            then
               echo "Could not import Sanesecurity public GPG key to custom keyring"
               log "ALERT - Could not import Sanesecurity public GPG key to custom keyring"
               exit 1
            else
               chmod 0644 $gpg_dir/*.*
               comment "Sanesecurity public GPG key successfully imported to custom keyring"
               log "INFO - Sanesecurity public GPG key successfully imported to custom keyring"
         fi
   fi
fi

# If custom keyring is missing, try to re-import Sanesecurity public GPG key.
if [ ! -s "$gpg_dir/ss-keyring.gpg" ] ; then
   rm -f -- "$gpg_dir/ss-keyring.gp*"
   if ! gpg -q --no-options --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg --import $gpg_dir/publickey.gpg
      then
         echo "Custom keyring MISSING or CORRUPT!  Could not import Sanesecurity public GPG key to custom keyring"
         log "ALERT - Custom keyring MISSING or CORRUPT!  Could not import Sanesecurity public GPG key to custom keyring"
         exit 1
      else
         chmod 0644 $gpg_dir/*.*
         comment "Sanesecurity custom keyring MISSING!  GPG key successfully re-imported to custom keyring"
         comment ""
         log "INFO - Sanesecurity custom keyring MISSING!  GPG key successfully re-imported to custom keyring"
   fi
fi

# Database update check, time randomization section.  This script now
# provides support for both bash and non-bash enabled system shells.
if [ "$enable_random" = "yes" ] ; then
   if [ -n "$RANDOM" ]
      then
         sleep_time=$(($RANDOM * $(($max_sleep_time - $min_sleep_time)) / 32767 + $min_sleep_time))
      else
         sleep_time=0
         while [ "$sleep_time" -lt "$min_sleep_time" -o "$sleep_time" -gt "$max_sleep_time" ] ; do
            sleep_time=`head -1 /dev/urandom | cksum | awk '{print $2}'`
         done
   fi
   if [ ! -t 0 ]
      then
         comment "`date` - Pausing database file updates for $sleep_time seconds..."
         log "INFO - Pausing database file updates for $sleep_time seconds..."
         sleep $sleep_time
         comment ""
         comment "`date` - Pause complete, checking for new database files..."
      else
         curl_silence="no"
         rsync_silence="no"
         gpg_silence="no"
         comment_silence="no"
         log "INFO - Script was run manually"
   fi
fi

# Create "scan-test.txt" file for clamscan database integrity testing.
if [ ! -s "$config_dir/scan-test.txt" ] ; then
   echo "This is the clamscan test file..." > "$config_dir/scan-test.txt"
fi

# Unofficial ClamAV database provider URLs
ss_url="rsync.sanesecurity.net"
si_url="clamav.securiteinfo.com"
mbl_url="www.malwarepatrol.net"

# Create the Sanesecurity rsync "include" file (defines which files to download).
ss_include_dbs="$config_dir/ss-include-dbs.txt"
if [ -n "$ss_dbs" ] ; then
   rm -f -- "$ss_include_dbs" "$ss_dir/*.sha256"
   for db_name in $ss_dbs ; do
      echo "$db_name" >> "$ss_include_dbs"
      echo "$db_name.sig" >> "$ss_include_dbs"
   done
fi

# If rsync proxy is defined in the config file, then export it for use.
if [ -n "$rsync_proxy" ]; then
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
if [ -n "$ss_dbs" ] ; then
   for db in $ss_dbs ; do
      echo "$ss_dir/$db" >> "$current_tmp"
      echo "$ss_dir/$db.sig" >> "$current_tmp"
      clamav_files
   done
fi
if [ -n "$si_dbs" ] ; then
   for db in $si_dbs ; do
      echo "$si_dir/$db" >> "$current_tmp"
      clamav_files
   done
fi
if [ -n "$mbl_dbs" ] ; then
   for db in $mbl_dbs ; do
      echo "$mbl_dir/$db" >> "$current_tmp"
      clamav_files
   done
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
if [ -s "$db_changes" ] ; then
   if grep -vq "bak" $db_changes 2>/dev/null ; then
      do_clamd_reload=2
   fi
   comment ""
   for file in `cat $db_changes` ; do
      rm -f -- "$file"
      comment "File removed: $file"
      log "INFO - File removed: $file"
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

# If ClamD status check is enabled ("clamd_socket" variable is uncommented
# and the socket path is correctly specified in "User Edit" section above),
# then test to see if clamd is running or not.
if [ -n "$clamd_socket" ] ; then
   if [ "`perl -e 'use IO::Socket::UNIX; print $IO::Socket::UNIX::VERSION,"\n"' 2>/dev/null`" ]
      then
         io_socket1=1
         if [ "`perl -MIO::Socket::UNIX -we '$s = IO::Socket::UNIX->new(shift); $s->print("PING"); \
            print $s->getline; $s->close' "$clamd_socket" 2>/dev/null`" = "PONG" ] ; then
            io_socket2=1
            comment "===================="
            comment "= ClamD is running ="
            comment "===================="
            log "INFO - ClamD is running"
         fi
      else
         socat="`which socat 2>/dev/null`"
         if [ -n "$socat" -a -x "$socat" ] ; then
            socket_cat1=1
            if [ "`(echo "PING"; sleep 1;) | socat - "$clamd_socket" 2>/dev/null`" = "PONG" ] ; then
               socket_cat2=1
               comment "===================="
               comment "= ClamD is running ="
               comment "===================="
               log "INFO - ClamD is running"
            fi
         fi
   fi
   if [ -z "$io_socket1" -a -z "$socket_cat1" ]
      then
         echo ""
         echo "                         --- WARNING ---"
         echo "   It appears that neither 'SOcket CAT' (socat) nor the perl module"
         echo "   'IO::Socket::UNIX' are installed on the system.  In order to run"
         echo "   the ClamD socket test to determine whether ClamD is running or"
         echo "   or not, either 'socat' or 'IO::Socket::UNIX' must be installed."
         echo ""
         echo "   You can silence this warning by either installing 'socat' or the"
         echo "   'IO::Socket::UNIX' perl module, or by simply commenting out the"
         echo "   'clamd_socket' variable in the clamav-unofficial-sigs.conf file."
         log "WARNING - Neither socat nor IO::Socket::UNIX perl module found, cannot test whether ClamD is running"
      else
         if [ -z "$io_socket2" -a -z "$socket_cat2" ] ; then
            echo ""
            echo "     *************************"
            echo "     *     !!! ALERT !!!     *"
            echo "     * CLAMD IS NOT RUNNING! *"
            echo "     *************************"
            echo ""
            log "ALERT - ClamD is not running"
            if [ -n "$start_clamd" ] ; then
               echo "    Attempting to start ClamD..."
               echo ""
               if [ -n "$io_socket1" ]
                  then
                     rm -f -- "$clamd_pid" "$clamd_lock" "$clamd_socket" 2>/dev/null
                     $start_clamd > /dev/null && sleep 5
                     if [ "`perl -MIO::Socket::UNIX -we '$s = IO::Socket::UNIX->new(shift); $s->print("PING"); \
                        print $s->getline; $s->close' "$clamd_socket" 2>/dev/null`" = "PONG" ]
                        then
                           echo "=================================="
                           echo "= ClamD was successfully started ="
                           echo "=================================="
                           log "NOTICE - ClamD was successfuly started"
                        else
                           echo "     *************************"
                           echo "     *     !!! PANIC !!!     *"
                           echo "     * CLAMD FAILED TO START *"
                           echo "     *************************"
                           echo ""
                           echo "Check to confirm that the clamd start process defined for"
                           echo "the 'start_clamd' variable in the 'USER EDIT SECTION' is"
                           echo "set correctly for your particular distro.  If it is, then"
                           echo "check your logs to determine why clamd failed to start."
                           echo ""
                           log "CRITICAL - ClamD failed to start"
                        exit 1
                     fi
                  else
                     if [ -n "$socket_cat1" ] ; then
                        rm -f -- "$clamd_pid" "$clamd_lock" "$clamd_socket" 2>/dev/null
                        $start_clamd > /dev/null && sleep 5
                        if [ "`(echo "PING"; sleep 1;) | socat - "$clamd_socket" 2>/dev/null`" = "PONG" ]
                           then
                              echo "=================================="
                              echo "= ClamD was successfully started ="
                              echo "=================================="
                              log "NOTICE - ClamD was successfuly started"
                           else
                              echo "     *************************"
                              echo "     *     !!! PANIC !!!     *"
                              echo "     * CLAMD FAILED TO START *"
                              echo "     *************************"
                              echo ""
                              echo "Check to confirm that the clamd start process defined for"
                              echo "the 'start_clamd' variable in the 'USER EDIT SECTION' is"
                              echo "set correctly for your particular distro.  If it is, then"
                              echo "check your logs to determine why clamd failed to start."
                              echo ""
                              log "CRITICAL - ClamD failed to start"
                           exit 1
                        fi
                     fi
               fi
            fi
         fi
   fi
fi

# Check and save current system time since epoch for time related database downloads.
# However, if unsuccessful, issue a warning that we cannot calculate times since epoch.
if [ -n "$si_dbs" -o -n "mbl_dbs" ]
   then
      if [ `date +%s` -gt 0 2>/dev/null ]
         then
            current_time=`date +%s`
         else
            if [ `perl -le print+time 2>/dev/null` ] ; then
               current_time=`perl -le print+time`
            fi
      fi
   else
      echo ""
      echo "                           --- WARNING ---"
      echo "The system's date function does not appear to support 'date +%s', nor was 'perl' found"
      echo "on the system.  The SecuriteInfo and MalwarePatrol updates were bypassed at this time."
      echo ""
      echo "You can silence this warning by either commenting out the 'si_dbs' and 'mbl_dbs'"
      echo "variables in the 'USER CONFIGURATION' section of the script, or by installing perl or"
      echo "the GNU date utility, either of which can calculate the needed seconds since epoch."
      log "WARNING - Systems does not support calculating time since epoch, SecuriteInfo and MalwarePatrol updates bypassed"
      si_dbs=""
      mbl_dbs=""
fi

################################################################
# Check for Sanesecurity database & GPG signature file updates #
################################################################
if [ -n "$ss_dbs" ] ; then
   db_file=""
   comment ""
   comment "======================================================================"
   comment "Sanesecurity Database & GPG Signature File Updates"
   comment "======================================================================"
   ss_mirror_ips=`dig +ignore +short $ss_url`
   for ss_mirror_ip in $ss_mirror_ips ; do
      ss_mirror_name=`dig +short -x $ss_mirror_ip | sed 's/\.$//'`
      ss_mirror_site_info="$ss_mirror_name $ss_mirror_ip"
      comment ""
      comment "Sanesecurity mirror site used: $ss_mirror_site_info"
      log "INFO - Sanesecurity mirror site used: $ss_mirror_site_info"
      if rsync $rsync_output_level $no_motd --files-from=$ss_include_dbs -ctuz $connect_timeout \
         --timeout="$rsync_max_time" --stats rsync://$ss_mirror_ip/sanesecurity $ss_dir 2>/dev/null
         then
            ss_rsync_success="1"
            for db_file in $ss_dbs ; do
               if ! cmp -s $ss_dir/$db_file $clam_dbs/$db_file ; then
                  comment ""
                  comment "Testing updated Sanesecurity database file: $db_file"
                  log "INFO - Testing updated Sanesecurity database file: $db_file"
                  if ! gpg --trust-model always -q --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg \
                       --verify $ss_dir/$db_file.sig $ss_dir/$db_file 2>/dev/null
                     then
                        gpg --always-trust -q --no-default-keyring --homedir $gpg_dir --keyring $gpg_dir/ss-keyring.gpg \
                        --verify $ss_dir/$db_file.sig $ss_dir/$db_file 2>/dev/null
                  fi
                  if [ "$?" = "0" ]
                     then
                        test "$gpg_silence" = "no" && echo "Sanesecurity GPG Signature tested good on $db_file database"
                        log "INFO - Sanesecurity GPG Signature tested good on $db_file database" ; true
                     else
                        echo "Sanesecurity GPG Signature test FAILED on $db_file database - SKIPPING"
                        log "WARNING - Sanesecurity GPG Signature test FAILED on $db_file database - SKIPPING" ; false
                  fi
                  if [ "$?" = "0" ] ; then
                     db_ext=`echo $db_file | cut -d "." -f2`
                     if [ -z "$ham_dir" -o "$db_ext" != "ndb" ]
                        then
                           if clamscan --quiet -d "$ss_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
                              then
                                 comment "Clamscan reports Sanesecurity $db_file database integrity tested good"
                                 log "INFO - Clamscan reports Sanesecurity $db_file database integrity tested good" ; true
                              else
                                 echo "Clamscan reports Sanesecurity $db_file database integrity tested BAD - SKIPPING"
                                 log "WARNING - Clamscan reports Sanesecurity $db_file database integrity tested BAD - SKIPPING" ; false
                           fi && \
                           (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
                           if rsync -pcqt $ss_dir/$db_file $clam_dbs
                              then
                                 perms chown $clam_user:$clam_group $clam_dbs/$db_file
                                 comment "Successfully updated Sanesecurity production database file: $db_file"
                                 log "INFO - Successfully updated Sanesecurity production database file: $db_file"
                                 ss_update=1
                                 do_clamd_reload=1
                              else
                                 echo "Failed to successfully update Sanesecurity production database file: $db_file - SKIPPING"
                                 log "WARNING - Failed to successfully update Sanesecurity production database file: $db_file - SKIPPING" ; false
                           fi
                        else
                           grep -h -v -f "$config_dir/whitelist.hex" "$ss_dir/$db_file" > "$test_dir/$db_file"
                           clamscan --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | \
                           sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$config_dir/whitelist.txt"
                           grep -h -f "$config_dir/whitelist.txt" "$test_dir/$db_file" | \
                           cut -d "*" -f2 | sort | uniq >> "$config_dir/whitelist.hex"
                           grep -h -v -f "$config_dir/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
                           mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
                           if clamscan --quiet -d "$test_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
                              then
                                 comment "Clamscan reports Sanesecurity $db_file database integrity tested good"
                                 log "INFO - Clamscan reports Sanesecurity $db_file database integrity tested good" ; true
                              else
                                 echo "Clamscan reports Sanesecurity $db_file database integrity tested BAD - SKIPPING"
                                 log "WARNING - Clamscan reports Sanesecurity $db_file database integrity tested BAD - SKIPPING" ; false
                           fi && \
                           (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
                           if rsync -pcqt $test_dir/$db_file $clam_dbs
                              then
                                 perms chown $clam_user:$clam_group $clam_dbs/$db_file
                                 comment "Successfully updated Sanesecurity production database file: $db_file"
                                 log "INFO - Successfully updated Sanesecurity production database file: $db_file"
                                 ss_update=1
                                 do_clamd_reload=1
                              else
                                 echo "Failed to successfully update Sanesecurity production database file: $db_file - SKIPPING"
                                 log "WARNING - Failed to successfully update Sanesecurity production database file: $db_file - SKIPPING"
                           fi
                     fi
                  fi
               fi
            done
            if [ "$ss_update" != "1" ]
               then
                  comment ""
                  comment "No Sanesecurity database file updates found"
                  log "INFO - No Sanesecurity database file updates found"
                  break
               else
                  break
            fi
         else
            comment "Connection to $ss_mirror_site_info failed - Trying next mirror site..."
            log "WARNING - Connection to $ss_mirror_site_info failed - Trying next mirror site..."
      fi
   done
   if [ "$ss_rsync_success" != "1" ] ; then
      echo ""
      echo "Access to all Sanesecurity mirror sites failed - Check for connectivity issues"
      echo "or signature database name(s) misspelled in the script's configuration file."
      log "WARNING - Access to all Sanesecurity mirror sites failed - Check for connectivity issues"
      log "WARNING - or signature database name(s) misspelled in the script's configuration file."
   fi
fi

#######################################################################
# Check for updated SecuriteInfo database files every set number of   #
# hours as defined in the "USER CONFIGURATION" section of this script #
#######################################################################
if [ -n "$si_dbs" ] ; then
   rm -f "$si_dir/*.gz"
   if [ -s "$config_dir/last-si-update.txt" ]
      then
         last_si_update=`cat $config_dir/last-si-update.txt`
      else
         last_si_update="0"
   fi
   db_file=""
   loop=""
   update_interval=$(($si_update_hours * 3600))
   time_interval=$(($current_time - $last_si_update))
   if [ "$time_interval" -ge $(($update_interval - 600)) ]
      then
         echo "$current_time" > "$config_dir"/last-si-update.txt
         comment ""
         comment "======================================================================"
         comment "SecuriteInfo Database File Updates"
         comment "======================================================================"
         log "INFO - Checking for SecuriteInfo updates..."
         si_updates="0"
         for db_file in $si_dbs ; do
            if [ "$loop" = "1" ]
               then
                  comment "---"
               else
                  comment ""
            fi
            comment "Checking for updated SecuriteInfo database file: $db_file"
            comment ""
            si_db_update="0"
            if [ -s "$si_dir/$db_file" ]
               then
                  z_opt="-z $si_dir/$db_file"
               else
                  z_opt=""
            fi
            if curl $curl_proxy $curl_output_level --connect-timeout "$curl_connect_timeout" \
               --max-time "$curl_max_time" -L -R $z_opt -o $si_dir/$db_file http://$si_url/$db_file
               then
                  loop="1"
                  if ! cmp -s $si_dir/$db_file $clam_dbs/$db_file ; then
                     if [ "$?" = "0" ] ; then
                        db_ext=`echo $db_file | cut -d "." -f2`
			comment ""
                        comment "Testing updated SecuriteInfo database file: $db_file"
                        log "INFO - Testing updated SecuriteInfo database file: $db_file"
                        if [ -z "$ham_dir" -o "$db_ext" != "ndb" ]
                           then
                              if clamscan --quiet -d "$si_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
                                 then
                                    comment "Clamscan reports SecuriteInfo $db_file database integrity tested good"
                                    log "INFO - Clamscan reports SecuriteInfo $db_file database integrity tested good" ; true
                                 else
                                    echo "Clamscan reports SecuriteInfo $db_file database integrity tested BAD - SKIPPING"
                                    log "WARNING - Clamscan reports SecuriteInfo $db_file database integrity tested BAD - SKIPPING" ; false
                                    rm -f "$si_dir/$db_file"
                              fi && \
                              (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
                              if rsync -pcqt $si_dir/$db_file $clam_dbs
                                 then
                                    perms chown $clam_user:$clam_group $clam_dbs/$db_file
                                    comment "Successfully updated SecuriteInfo production database file: $db_file"
                                    log "INFO - Successfully updated SecuriteInfo production database file: $db_file"
                                    si_updates=1
                                    si_db_update=1
                                    do_clamd_reload=1
                                 else
                                    echo "Failed to successfully update SecuriteInfo production database file: $db_file - SKIPPING"
                                    log "WARNING - Failed to successfully update SecuriteInfo production database file: $db_file - SKIPPING"
                              fi
                           else
                              grep -h -v -f "$config_dir/whitelist.hex" "$si_dir/$db_file" > "$test_dir/$db_file"
                              clamscan --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | \
                              sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$config_dir/whitelist.txt"
                              grep -h -f "$config_dir/whitelist.txt" "$test_dir/$db_file" | \
                              cut -d "*" -f2 | sort | uniq >> "$config_dir/whitelist.hex"
                              grep -h -v -f "$config_dir/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
                              mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
                              if clamscan --quiet -d "$test_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
                                 then
                                    comment "Clamscan reports SecuriteInfo $db_file database integrity tested good"
                                    log "INFO - Clamscan reports SecuriteInfo $db_file database integrity tested good" ; true
                                 else
                                    echo "Clamscan reports SecuriteInfo $db_file database integrity tested BAD - SKIPPING"
                                    log "WARNING - Clamscan reports SecuriteInfo $db_file database integrity tested BAD - SKIPPING" ; false
                                    rm -f "$si_dir/$db_file"
                              fi && \
                              (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
                              if rsync -pcqt $test_dir/$db_file $clam_dbs
                                 then
                                    perms chown $clam_user:$clam_group $clam_dbs/$db_file
                                    comment "Successfully updated SecuriteInfo production database file: $db_file"
                                    log "INFO - Successfully updated SecuriteInfo production database file: $db_file"
                                    si_updates=1
                                    si_db_update=1
                                    do_clamd_reload=1
                                 else
                                    echo "Failed to successfully update SecuriteInfo production database file: $db_file - SKIPPING"
                                    log "WARNING - Failed to successfully update SecuriteInfo production database file: $db_file - SKIPPING"
                              fi
                        fi
                     fi
                  fi
               else
                  log "WARNING - Failed curl connection to $si_url - SKIPPED SecuriteInfo $db_file update"
            fi
            if [ "$si_db_update" != "1" ] ; then
               comment ""
               comment "No updated SecuriteInfo $db_file database file found"
            fi
         done
         if [ "$si_updates" != "1" ] ; then
            log "INFO - No SecuriteInfo database file updates found"
         fi
      else
         comment ""
         comment "======================================================================"
         comment "SecuriteInfo Database File Updates"
         comment "======================================================================"
         comment ""
         time_remaining=$(($update_interval - $time_interval))
         hours_left=$(($time_remaining / 3600))
         minutes_left=$(($time_remaining % 3600 / 60))
         comment "$si_update_hours hours have not yet elapsed since the last SecuriteInfo update check"
         comment ""
         comment "     --- No update check was performed at this time ---"
         comment ""
         comment "Next check will be performed in approximately $hours_left hour(s), $minutes_left minute(s)"
         log "INFO - Next SecuriteInfo check will be performed in approximately $hours_left hour(s), $minutes_left minute(s)"
   fi
fi

#####################################################################
# Download MalwarePatrol database file(s) every set number of hours #
# as defined in the "USER CONFIGURATION" section of this script.    #
#####################################################################
if [ -n "$mbl_dbs" ] ; then
   if [ -s "$config_dir/last-mbl-update.txt" ]
      then
         last_mbl_update=`cat $config_dir/last-mbl-update.txt`
      else
         last_mbl_update="0"
   fi
   db_file=""
   update_interval=$(($mbl_update_hours * 3600))
   time_interval=$(($current_time - $last_mbl_update))
   if [ "$time_interval" -ge $(($update_interval - 600)) ]
      then
         echo "$current_time" > "$config_dir"/last-mbl-update.txt
         log "INFO - Checking for MalwarePatrol updates..."
         for db_file in $mbl_dbs ; do
            # Delete the old MBL (mbl.db) database file if it exists and start using the newer
            # format (mbl.ndb) database file instead.
            test -e $clam_dbs/$db_file -o -e $clam_dbs/$db_file-bak && rm -f -- "$clam_dbs/mbl.d*"
            comment ""
            comment "======================================================================"
            comment "MalwarePatrol $db_file Database File Update"
            comment "======================================================================"
            comment ""
            if curl $curl_proxy $curl_output_level -R --connect-timeout "$curl_connect_timeout" \
               --max-time "$curl_max_time" -o $mbl_dir/$db_file http://$mbl_url/cgi/submit?action=list_clamav_ext
               then
                  if ! cmp -s $mbl_dir/$db_file $clam_dbs/$db_file 
                     then
                        if [ "$?" = "0" ] ; then
                           db_ext=`echo $db_file | cut -d "." -f2`
                           comment ""
                           comment "Testing updated MalwarePatrol database file: $db_file"
                           log "INFO - Testing updated database file: $db_file"
                           if [ -z "$ham_dir" -o "$db_ext" != "ndb" ]
                              then
                                 if clamscan --quiet -d "$mbl_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
                                    then
                                       comment "Clamscan reports MalwarePatrol $db_file database integrity tested good"
                                       log "INFO - Clamscan reports MalwarePatrol $db_file database integrity tested good" ; true
                                    else
                                       echo "Clamscan reports MalwarePatrol $db_file database integrity tested BAD - SKIPPING"
                                       log "WARNING - Clamscan reports MalwarePatrol $db_file database integrity tested BAD - SKIPPING" ; false
                                 fi && \
                                 (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
                                 if rsync -pcqt $mbl_dir/$db_file $clam_dbs
                                    then
                                       perms chown $clam_user:$clam_group $clam_dbs/$db_file
                                       comment "Successfully updated MalwarePatrol production database file: $db_file"
                                       log "INFO - Successfully updated MalwarePatrol production database file: $db_file"
                                       mbl_update=1
                                       do_clamd_reload=1
                                    else
                                       echo "Failed to successfully update MalwarePatrol production database file: $db_file - SKIPPING"
                                       log "WARNING - Failed to successfully update MalwarePatrol production database file: $db_file - SKIPPING"
                                 fi
                              else
                                 grep -h -v -f "$config_dir/whitelist.hex" "$mbl_dir/$db_file" > "$test_dir/$db_file"
                                 clamscan --infected --no-summary -d "$test_dir/$db_file" "$ham_dir"/* | \
                                 sed 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "$config_dir/whitelist.txt"
                                 grep -h -f "$config_dir/whitelist.txt" "$test_dir/$db_file" | \
                                 cut -d "*" -f2 | sort | uniq >> "$config_dir/whitelist.hex"
                                 grep -h -v -f "$config_dir/whitelist.hex" "$test_dir/$db_file" > "$test_dir/$db_file-tmp"
                                 mv -f "$test_dir/$db_file-tmp" "$test_dir/$db_file"
                                 if clamscan --quiet -d "$test_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
                                    then
                                       comment "Clamscan reports MalwarePatrol $db_file database integrity tested good"
                                       log "INFO - Clamscan reports MalwarePatrol $db_file database integrity tested good" ; true
                                    else
                                       echo "Clamscan reports MalwarePatrol $db_file database integrity tested BAD - SKIPPING"
                                       log "WARNING - Clamscan reports MalwarePatrol $db_file database integrity tested BAD - SKIPPING" ; false
                                 fi && \
                                 (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
                                 if rsync -pcqt $test_dir/$db_file $clam_dbs
                                    then
                                       perms chown $clam_user:$clam_group $clam_dbs/$db_file
                                       comment "Successfully updated MalwarePatrol production database file: $db_file"
                                       log "INFO - Successfully updated MalwarePatrol production database file: $db_file"
                                       mbl_update=1
                                       do_clamd_reload=1
                                    else
                                       echo "Failed to successfully update MalwarePatrol production database file: $db_file - SKIPPING"
                                       log "WARNING - Failed to successfully update MalwarePatrol production database file: $db_file - SKIPPING"
                                 fi
                           fi
                        fi
                     else
                        comment ""
                        comment "MalwarePatrol signature database ($db_file) did not change - skipping"
                        log "INFO - MalwarePatrol signature database ($db_file) did not change - skipping"
                  fi
               else
                  log "WARNING - Failed curl connection to $mbl_url - SKIPPED MalwarePatrol $db_file update"
            fi
         done
      else
         comment ""
         comment "======================================================================"
         comment "MalwarePatrol Database File Update"
         comment "======================================================================"
         comment ""
         time_remaining=$(($update_interval - $time_interval))
         hours_left=$(($time_remaining / 3600))
         minutes_left=$(($time_remaining % 3600 / 60))
         comment "$mbl_update_hours hours have not yet elapsed since the last MalwarePatrol download"
         comment ""
         comment "     --- No database download was performed at this time ---"
         comment ""
         comment "Next download will be performed in approximately $hours_left hour(s), $minutes_left minute(s)"
         log "INFO - Next MalwarePatrol download will be performed in approximately $hours_left hour(s), $minutes_left minute(s)"
   fi
fi

###################################################
# Check for user added signature database updates #
###################################################
if [ -n "$add_dbs" ] ; then
   comment ""
   comment "======================================================================"
   comment "User Added Signature Database File Update(s)"
   comment "======================================================================"
   comment ""
   for db_url in $add_dbs ; do
      base_url=`echo $db_url | cut -d "/" -f3`
      db_file=`basename $db_url`
      if [ "`echo $db_url | cut -d ":" -f1`" = "rsync" ]
         then
            if ! rsync $rsync_output_level $no_motd $connect_timeout --timeout="$rsync_max_time" --exclude=*.txt \
                 -crtuz --stats --exclude=*.sha256 --exclude=*.sig --exclude=*.gz $db_url $add_dir ; then
               echo "Failed rsync connection to $base_url - SKIPPED $db_file update"
               log "WARNING - Failed rsync connection to $base_url - SKIPPED $db_file update"
            fi
         else
             if [ -s "$add_dir/$db_file" ]
                then
                   z_opt="-z $add_dir/$db_file"
                else
                   z_opt=""
             fi
             if ! curl $curl_output_level --connect-timeout "$curl_connect_timeout" --max-time \
                  "$curl_max_time" -L -R $z_opt -o $add_dir/$db_file $db_url ; then
                echo "Failed curl connection to $base_url - SKIPPED $db_file update"
                log "WARNING - Failed curl connection to $base_url - SKIPPED $db_file update"
             fi
      fi
   done
   db_file=""
   for db_file in `ls $add_dir`; do
      if ! cmp -s $add_dir/$db_file $clam_dbs/$db_file ; then
         comment ""
         comment "Testing updated database file: $db_file"
         clamscan --quiet -d "$add_dir/$db_file" "$config_dir/scan-test.txt" 2>/dev/null
         if [ "$?" = "0" ]
            then
               comment "Clamscan reports $db_file database integrity tested good"
               log "INFO - Clamscan reports $db_file database integrity tested good" ; true
            else
               echo "Clamscan reports User Added $db_file database integrity tested BAD - SKIPPING"
               log "WARNING - Clamscan reports User Added $db_file database integrity tested BAD - SKIPPING" ; false
         fi && \
         (test "$keep_db_backup" = "yes" && cp -f $clam_dbs/$db_file $clam_dbs/$db_file-bak 2>/dev/null ; true) && \
         if rsync -pcqt $add_dir/$db_file $clam_dbs
            then
               perms chown $clam_user:$clam_group $clam_dbs/$db_file
               comment "Successfully updated User-Added production database file: $db_file"
               log "INFO - Successfully updated User-Added production database file: $db_file"
               add_update=1
               do_clamd_reload=1
            else
               echo "Failed to successfully update User-Added production database file: $db_file - SKIPPING"
               log "WARNING - Failed to successfully update User-Added production database file: $db_file - SKIPPING"
         fi
      fi
   done
   if [ "$add_update" != "1" ] ; then
      comment ""
      comment "No User-Defined database file updates found"
      log "INFO - No User-Defined database file updates found"
   fi
fi

# Check to see if the local.ign file exists, and if it does, check to see if any of the script
# added bypass entries can be removed due to offending signature modifications or removals.
if [ -s "$clam_dbs/local.ign" -a -s "$config_dir/monitor-ign.txt" ] ; then
   ign_updated=0
   cd "$clam_dbs"
   cp -f local.ign "$config_dir/local.ign"
   comment ""
   comment "======================================================================"
   for entry in `cat "$config_dir/monitor-ign.txt" 2>/dev/null` ; do
      sig_file=`echo "$entry" | tr -d "\r" | awk -F ":" '{print $1}'`
      sig_hex=`echo "$entry" | tr -d "\r" | awk -F ":" '{print $NF}'`
      sig_name_old=`echo "$entry" | tr -d "\r" | awk -F ":" '{print $3}'`
      sig_ign_old=`grep "$sig_name_old" "$config_dir/local.ign"`
      sig_old=`echo "$entry" | tr -d "\r" | cut -d ":" -f3-`
      sig_new=`grep -hwF "$sig_hex" "$sig_file" | tr -d "\r" 2>/dev/null`
      sig_mon_new=`grep -HwF -n "$sig_hex" "$sig_file" | tr -d "\r"`
      if [ -n "$sig_new" ]
         then
            if [ "$sig_old" != "$sig_new" -o "$entry" != "$sig_mon_new" ] ; then
               sig_name_new=`echo "$sig_new" | tr -d "\r" | awk -F ":" '{print $1}'`
               sig_ign_new=`echo "$sig_mon_new" | cut -d ":" -f1-3`
               perl -i -ne "print unless /$sig_ign_old/" "$config_dir/monitor-ign.txt"
               echo "$sig_mon_new" >> "$config_dir/monitor-ign.txt"
               perl -p -i -e "s/$sig_ign_old/$sig_ign_new/" "$config_dir/local.ign"
               comment ""
               comment "$sig_name_old hexadecimal signature unchanged, however signature name and/or line placement"
               comment "in $sig_file has change to $sig_name_new - updated local.ign to reflect this change."
               log "INFO - $sig_name_old hexadecimal signature unchanged, however signature name and/or line placement"
               log "INFO - in $sig_file has change to $sig_name_new - updated local.ign to reflect this change."
               ign_updated=1
            fi
         else
            perl -i -ne "print unless /$sig_ign_old/" "$config_dir/monitor-ign.txt" "$config_dir/local.ign"
            comment ""
            comment "$sig_name_old signature has been removed from $sig_file, entry removed from local.ign."
            log "INFO - $sig_name_old signature has been removed from $sig_file, entry removed from local.ign."
            ign_updated=1
      fi
   done
   if [ "$ign_updated" = "1" ]
      then
         if clamscan --quiet -d "$config_dir/local.ign" "$config_dir/scan-test.txt"
            then
               if rsync -pcqt $config_dir/local.ign $clam_dbs
                  then
                     perms chown $clam_user:$clam_group "$clam_dbs/local.ign"
                     chmod 0644 "$clam_dbs/local.ign" "$config_dir/monitor-ign.txt"
                     do_clamd_reload=3
                  else
                     echo "Failed to successfully update local.ign file - SKIPPING"
                     log "WARNING - Failed to successfully update local.ign file - SKIPPING"
               fi
            else
               echo "Clamscan reports local.ign database integrity is bad - SKIPPING"
               log "WARNING - Clamscan reports local.ign database integrity is bad - SKIPPING"
         fi
      else
         comment "No whitelist signature changes found in local.ign."
         comment "======================================================================"
         log "INFO - No whitelist signature changes found in local.ign."
   fi
fi

# Check to see if my-whitelist.ign2 file exists, and if it does, check to see if any of the script
# added whitelist entries can be removed due to offending signature modifications or removals.
if [ -s "$clam_dbs/my-whitelist.ign2" -a -s "$config_dir/tracker.txt" ] ; then
   ign2_updated=0
   cd "$clam_dbs"
   cp -f my-whitelist.ign2 "$config_dir/my-whitelist.ign2"
   comment ""
   comment "======================================================================"
   for entry in `cat "$config_dir/tracker.txt" 2>/dev/null` ; do
      sig_file=`echo "$entry" | cut -d ":" -f1`
      sig_full=`echo "$entry" | cut -d ":" -f2-`
      sig_name=`echo "$entry" | cut -d ":" -f2`
      if ! grep -F "$sig_full" "$sig_file" > /dev/null 2>&1 ; then
         perl -i -ne "print unless /$sig_name$/" "$config_dir/my-whitelist.ign2"
         perl -i -ne "print unless /:$sig_name:/" "$config_dir/tracker.txt"
         comment ""
         comment "$sig_name signature no longer exists in"
         comment "$sig_file, whitelist entry removed from my-whitelist.ign2."
         log "INFO - $sig_name signature no longer exists in"
         log "INFO - $sig_file, whitelist entry removed from my-whitelist.ign2."
         ign2_updated=1
      fi
   done
   comment ""
   comment "======================================================================"
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
                     echo "Failed to successfully update my-whitelist.ign2 file - SKIPPING"
                     log "WARNING - Failed to successfully update my-whitelist.ign2 file - SKIPPING"
               fi
            else
               echo "Clamscan reports my-whitelist.ign2 database integrity is bad - SKIPPING"
               log "WARNING - Clamscan reports my-whitelist.ign2 database integrity is bad - SKIPPING"
         fi
      else
         comment "No whitelist signature changes found in my-whitelist.ign2."
         comment "======================================================================"
         log "INFO - No whitelist signature changes found in my-whitelist.ign2."
   fi
fi

# Check for non-matching whitelist.hex signatures and remove them from the whitelist file (signature modified or removed).
if [ -n "$ham_dir" ] ; then
   if [ -s "$config_dir/whitelist.hex" ]
      then
         grep -h -f "$config_dir/whitelist.hex" "$work_dir"/*/*.ndb | cut -d "*" -f2 | tr -d "\r" | sort | uniq > "$config_dir/whitelist.tmp"
         mv -f "$config_dir/whitelist.tmp" "$config_dir/whitelist.hex"
         rm -f "$config_dir/whitelist.txt"
         rm -f "$test_dir"/*.*
         echo ""
         echo "***********************************************************************"
         echo "* Signature(s) triggered on HAM directory scan - signature(s) removed *"
         echo "***********************************************************************"
         log "WARNING - Signature(s) triggered on HAM directory scan - signature(s) removed"
      else
         comment ""
         comment "================================================="
         comment "= No signatures triggered on HAM directory scan ="
         comment "================================================="
         log "INFO - No signatures triggered on HAM directory scan"
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

# Reload all clamd databases if updates detected and $reload_dbs" is
# set to "yes", and neither $reload_opt nor $do_clamd_reload are null.
if [ "$reload_dbs" = "yes" -a -z "$reload_opt" ]
   then
      echo ""
      echo "********************************************************************************************"
      echo "* Check the script's configuration file, 'reload_dbs' enabled but no 'reload_opt' selected *"
      echo "********************************************************************************************"
      log "WARNING - Check the script's configuration file, 'reload_dbs' enabled but no 'reload_opt' selected"
   elif [ "$reload_dbs" = "yes" -a "$do_clamd_reload" = "1" -a -n "$reload_opt" ] ; then
      comment ""
      comment "================================================="
      comment "= Update(s) detected, reloaded ClamAV databases ="
      comment "================================================="
      log "INFO - Update(s) detected, reloaded ClamAV databases"
      $reload_opt
   elif [ "$reload_dbs" = "yes" -a "$do_clamd_reload" = "2" -a -n "$reload_opt" ] ; then
      comment ""
      comment "==========================================================="
      comment "= Database removal(s) detected, reloaded ClamAV databases ="
      comment "==========================================================="
      log "INFO - Database removal(s) detected, reloaded ClamAV databases"
      $reload_opt
   elif [ "$reload_dbs" = "yes" -a "$do_clamd_reload" = "3" -a -n "$reload_opt" ] ; then
      comment ""
      comment "==========================================================="
      comment "= File 'local.ign' has changed, reloaded ClamAV databases ="
      comment "==========================================================="
      log "INFO - File 'local.ign' has changed, reloaded ClamAV databases"
      $reload_opt
   elif [ "$reload_dbs" = "yes" -a "$do_clamd_reload" = "4" -a -n "$reload_opt" ] ; then
      comment ""
      comment "==================================================================="
      comment "= File 'my-whitelist.ign2' has changed, reloaded ClamAV databases ="
      comment "==================================================================="
      log "INFO - File 'my-whitelist.ign2' has changed, reloaded ClamAV databases"
      $reload_opt
   elif [ "$reload_dbs" = "yes" -a -z "$do_clamd_reload" ] ; then
      comment ""
      comment "==========================================================="
      comment "= No updates detected, ClamAV databases were not reloaded ="
      comment "==========================================================="
      log "INFO - No updates detected, ClamAV databases were not reloaded"
   else
      comment ""
      comment "==============================================================="
      comment "= Database reload has been disabled in the configuration file ="
      comment "==============================================================="
      log "INFO - Database reload has been disabled in the configuration file"
      true
fi

exit $?
