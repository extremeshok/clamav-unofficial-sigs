#!/usr/bin/env bash
# shellcheck disable=SC2119
# shellcheck disable=SC2120
# shellcheck disable=SC2128
# shellcheck disable=SC2154
################################################################################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
################################################################################
#
# Script updates can be found at: https://github.com/extremeshok/clamav-unofficial-sigs
#
# Originially based on Script provided by Bill Landry (unofficialsigs@gmail.com).
#
################################################################################
#
#    THERE ARE NO USER CONFIGURABLE OPTIONS IN THIS SCRIPT
#   ALL CONFIGURATION OPTIONS ARE LOCATED IN THE INCLUDED CONFIGURATION FILE
#
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
if [ "$(tail -n 1 "${0}" | head -n 1 | cut -c 1-7)" != "exit \$?" ] ; then
    echo "FATAL ERROR: Script is incomplete, please redownload"
    exit 1
fi

# Trap the keyboard interrupt (Ctrl + C)
trap xshok_control_c SIGINT
################################################################################
# HELPER FUNCTIONS
################################################################################

# Support user config settings for applying file and directory access permissions.
function perms() {
  if [ -n "${clam_user}" ] && [ -n "${clam_group}" ] ; then
    "${@:-}"
  fi
}

# Prompt a user if they should complete an action with Y or N
# Usage: xshok_prompt_confirm
# if xshok_prompt_confirm ; then
# xshok_prompt_confirm && echo "accepted"
# xshok_prompt_confirm && echo "yes" || echo "no"
# shellcheck disable=SC2120
function xshok_prompt_confirm() { # optional_message
  message="${1:-Are you sure?}"
  while true; do
    read -r -p "${message} [y/N]" response < /dev/tty
    case "${response}" in
      [yY]) return 0 ;;
      [nN]) return 1 ;;
      *) printf " \\033[31m %s \\n\\033[0m" "invalid input"
    esac
  done
}

# Create a pid file
function xshok_create_pid_file() { # pid.file
  if [ "${1}" ] ; then
    pidfile="${1}"
    if ! echo $$ > "${pidfile}" ; then
      xshok_pretty_echo_and_log "ERROR: Could not create PID file: ${pidfile}"
      exit 1
    fi
  else
    xshok_pretty_echo_and_log "ERROR: Missing value for option"
    exit 1
  fi
}

# Intercept ctrl+c and calls the cleanup function
function xshok_control_c() {
  echo
  xshok_pretty_echo_and_log "---------------| Exiting ... Please wait |---------------" "-"
  xshok_cleanup
  exit $?
}

# Cleanup function
function xshok_cleanup() {
  # Wait for all processes to end
  wait
  xshok_pretty_echo_and_log "      Powered By https://eXtremeSHOK.com      " "#"
  return $?
}

# Check if the current running user is the root user, otherwise return false
function xshok_is_root() {
  if [ "$(uname -s)" == "SunOS" ] ; then
    id_bin="/usr/xpg4/bin/id"
  else
    id_bin="$(command -v id 2> /dev/null)"
  fi
  if [ "$($id_bin -u)" == 0 ] ; then
    return 0
  else
    return 1 # Not root
  fi
}

# Check if its a file, otherwise return false
function xshok_is_file() { # filepath
  filepath="${1}"
  if [ -f "${filepath}" ] ; then
    return 0 ;
  else
    return 1 ; # Not a file
  fi
}

# Check if filepath is a subdir, otherwise return false
# Usage: xshok_is_subdir "filepath"
# xshok_is_subdir "/root/" - false
# xshok_is_subdir "/usr/local/etc" && echo "yes" - yes
function xshok_is_subdir() { # filepath
  shopt -s extglob; filepath="${filepath%%+(/)}"
  if [ -d "$filepath" ] ; then
    res="${filepath//[^\/]}"
    if [ "${#res}" -gt 1 ] ; then
      return 0 ;
    else
      return 1 ; # Not a subdir
    fi
  else
    return 1 ; # Not a dir
  fi
}

# Create a dir and set the ownership
function xshok_mkdir_ownership() { # path
  if [ "${1}" ] ; then
    if ! mkdir -p "${1}" 2>/dev/null ; then
      xshok_pretty_echo_and_log "ERROR: Could not create directory: ${1}"
      exit 1
    fi
    perms chown -f "${clam_user}:${clam_group}" "${1}" > /dev/null 2>&1
  else
    xshok_pretty_echo_and_log "ERROR: Missing value for option"
    exit 1
  fi
}

# Check if a user and group exists on the system otherwise return false
# Usage:
# xshok_is_subdir "username" && echo "user found" || echo "no"
# xshok_is_subdir "username" "groupname" && echo "user and group found" || echo "no"
function xshok_user_group_exists() { # username groupname
  if [ "$(uname -s)" == "SunOS" ] ; then
    id_bin="/usr/xpg4/bin/id"
  else
    id_bin="$(command -v id 2> /dev/null)"
  fi

  if [ "${2}" ] ; then
    if [ "$(uname -s)" == "Darwin" ] ; then
      #use ruby, as this is the best way. Ruby is always avilable as brew uses ruby
      ruby -e 'require "etc"; puts Etc::getgrnam("_clamav").gid' > /dev/null 2>&1
      ret="$?"
    else
      getent_bin="$(command -v getent 2> /dev/null)"
      $getent_bin group "${2}" >/dev/null 2>&1
      ret="$?"
    fi
  fi

  if [ "${1}" ] ; then
    if $id_bin -u "${1}" > /dev/null 2>&1 ; then
      if [ "${2}" ] ; then
        if [ "$ret" -eq 0 ] ; then
          return 0 ; # User and group exists
        else
          return 1 ; # Group does NOT exist
        fi
      else
        return 0 ; # User exists
      fi
    else
      return 1 ; # User does NOT exist
    fi
  else
    xshok_pretty_echo_and_log "ERROR: Missing value for option"
    exit 1
  fi
}

# Handle comments with/out borders and logging.
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
# type: e = error, w= warning, a = alert, n = notice
# will auto detect using the first word "error,warning,alert,notice"
# type e will make a == border
# type w will make a -- border
# type a will make a ** border
# type n will make a ++ border
function xshok_pretty_echo_and_log() { # "string" "repeating" "count" "type"
    #detect if running under cron and silence
    mystring="$1"
    myrepeating="$2"
    mycount="$3"
    mytype="$4"
    if [ "$comment_silence" != "yes" ] && [ "$force_verbose" != "yes" ]; then
        if [ ! -t 1 ] ; then
            comment_silence="yes"
        fi
    fi
    # always show errors and alerts
    if [ -z "$mytype" ] ; then
        shopt -s nocasematch
        if [[ "$mystring" =~ "ERROR:" ]] || [[ "$mystring" =~ "ERROR " ]] ; then
            mytype="e"
        elif [[ "$mystring" =~ "WARNING:" ]] || [[ "$mystring" =~ "WARNING " ]] ; then
            mytype="w"
        elif [[ "$mystring" =~ "ALERT:" ]] || [[ "$mystring" =~ "ALERT " ]] ; then
            mytype="a"
        elif [[ "$mystring" =~ "NOTICE:" ]] || [[ "$mystring" =~ "NOTICE " ]] ; then
            mytype="n"
        fi
    fi
    if [ "$mytype" == "e" ] || [ "$mytype" == "a" ] ; then
            comment_silence="no"
    fi
    # Handle comments is not silenced or type
  if [ "$comment_silence" != "yes" ] ; then
        if [ -z "$myrepeating" ] ; then
            if [ "$mytype" == "e" ] ; then
                myrepeating="="
            elif [ "$mytype" == "w" ] ; then
                myrepeating="-"
            elif [ "$mytype" == "a" ] ; then
                myrepeating="*"
            elif [ "$mytype" == "n" ] ; then
                myrepeating="+"
            fi
        fi
    if [ -z "$myrepeating" ] ; then
      echo "${mystring}"
    else
      myvar=""
      if [ -z "$mycount" ] ; then
        mycount="${#mystring}"
      fi
      for (( n = 0; n < mycount; n++ )) ; do
        myvar="${myvar}${myrepeating}"
      done
      if [ -n "${mystring}" ] ; then
        echo -e "${myvar}\\n${1}\\n${myvar}"
      else
        echo -e "${myvar}"
      fi
    fi
  fi
  # Handle logging
  if [ "$enable_log" == "yes" ] ; then

        #filter ===, ---
        mystring=${1//===}
        mystring=${mystring//---}

        if [ -n "$mystring" ] ; then
        if [ -n "$log_pipe_cmd" ] ; then
          echo "${mystring}" | $log_pipe_cmd
        else
          if [ ! -e "${log_file_path}/${log_file_name}" ] ; then
            # xshok_mkdir_ownership "$log_file_path"
            mkdir -p "$log_file_path"
            touch "${log_file_path}/${log_file_name}" 2>/dev/null
            perms chown -f "${clam_user}:${clam_group}" "${log_file_path}/${log_file_name}"
          fi
          if [ ! -w "${log_file_path}/${log_file_name}" ] ; then
            echo "WARNING: Logging Disabled, as file not writable: ${log_file_path}/${log_file_name}"
            enable_log="no"
          else
            echo "$(date "+%b %d %T")" "${mystring}" >> "${log_file_path}/${log_file_name}"
          fi
        fi
        fi
  fi
}

# Check if the $2 value is not null and does not start with -
function xshok_check_s2() { # value1 value2
  if [ "${1}" ] ; then
    if [[ "${1}" =~ ^-.* ]] ; then
      xshok_pretty_echo_and_log "ERROR: Missing value for option or value begins with -"
      exit 1
    fi
  else
    xshok_pretty_echo_and_log "ERROR: Missing value for option"
    exit 1
  fi
}

# Time remaining information function
function xshok_draw_time_remaining() { #time_remaining #update_hours #name
  if [ "${1}" ] && [ "${2}" ] ; then
    time_remaining="${1}"
    hours_left="$((time_remaining / 3600))"
    minutes_left="$((time_remaining % 3600 / 60))"
    xshok_pretty_echo_and_log "${2} hours have not yet elapsed since the last ${3} update check"
    xshok_pretty_echo_and_log "No update check was performed at this time" "-"
    xshok_pretty_echo_and_log "Next check will be performed in approximately ${hours_left} hour(s), ${minutes_left} minute(s)"
  fi
}

# Download function
function xshok_file_download() { #outputfile #url #notimestamp
    if [ "$downloader_debug" == "yes" ] ; then
        xshok_pretty_echo_and_log "url: ${2} >> outputfile: ${1} | ${3}"
    fi
  if [ "${1}" ] && [ "${2}" ] ; then
        if [ -n "$curl_bin" ] ; then
            if [ -f "${1}" ] ; then
                # shellcheck disable=SC2086
                $curl_bin --fail --compressed $curl_proxy $curl_insecure $curl_output_level --connect-timeout "${downloader_connect_timeout}" --remote-time --location --retry "${downloader_tries}" --max-time "${downloader_max_time}" --time-cond "${1}" --output "${1}" "${2}"  2>&11
                result=$?
            else
                # shellcheck disable=SC2086
                $curl_bin --fail --compressed $curl_proxy $curl_insecure $curl_output_level --connect-timeout "${downloader_connect_timeout}" --remote-time --location --retry "${downloader_tries}" --max-time "${downloader_max_time}" --output "${1}" "${2}"  2>&11
                result=$?
            fi
        else
            if [ ! "${3}" ] ; then
                # the following is required because wget, cannot do --timestamping and --output-document together
                this_dir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
                output_file="$1"
                url="$2"
                output_dir="${output_file%/*}"
                output_file="${output_file##*/}"
                url_file="${url##*/}"
                wget_output_link=""

                cd "${output_dir}" || exit
                if [ "$output_file" != "$url_file" ] ; then
                    if [ ! -f "$url_file" ] ; then
                        if [ ! -f "$output_file" ] ; then
                            touch "$output_file"
                        fi
                        ln -s  "$output_file" "$url_file"
                        wget_output_link="$url_file"
                    fi
                fi
          # shellcheck disable=SC2086
                $wget_bin $wget_compression $wget_proxy $wget_insecure $wget_output_level --connect-timeout="${downloader_connect_timeout}" --random-wait --tries="${downloader_tries}" --timeout="${downloader_max_time}" --timestamping "${2}" 2>&12
                result=$?
                if [ -z "$wget_output_link" ] ; then
                    if [ -L "$wget_output_link" ] ; then
                        rm -f "$wget_output_link"
                    fi
                fi
                cd "$this_dir" || exit
            else
                # shellcheck disable=SC2086
                $wget_bin $wget_compression $wget_proxy $wget_insecure $wget_output_level --connect-timeout="${downloader_connect_timeout}" --random-wait --tries="${downloader_tries}" --timeout="${downloader_max_time}" --output-document="${1}" "${2}" 2>&12
                result=$?
            fi
    fi
    return $result
  fi
}

# Handle list of database files
function clamav_files() {
  echo "${clam_dbs}/${db}" >> "${current_tmp}"
  if [ "$keep_db_backup" == "yes" ] ; then
    echo "${clam_dbs}/${db}-bak" >> "${current_tmp}"
  fi
}

# Manage the databases and allow multi-dimensions as well as global overrides
# Since the datbases are basically a multi-dimentional associative arrays in bash
# ratings: LOW | MEDIUM | HIGH | REQUIRED | LOWONLY | MEDIUMONLY | LOWMEDIUMONLY | DISABLED
function xshok_database() { # rating database_array
  # Assign
  current_rating="${1}"
  declare -a current_dbs=( "${@:2}" )
  # Zero
  declare -a new_dbs=( )
  if [ -n "${current_dbs[0]}" ] ; then
    if [ ${#current_dbs} -ge 1 ] ; then
      for db_name in "${current_dbs[@]}" ; do
        # Checks
        if [ "$enable_yararules" == "no" ] ; then # YARA rules are disabled
          if [[ "$db_name" == *".yar"* ]] ; then # If it's the value you want to delete
            continue # Skip to the next value
          fi
        fi
        if [ -z "$current_rating" ] ; then
          new_dbs+=( "$db_name" )
        else
            if [[ ! "$db_name" = *"|"* ]] ; then # This old format
                new_dbs+=( "$db_name" )
            else
            db_name_rating="${db_name#*|}"
            db_name="${db_name%|*}"

            if [ "$db_name_rating" != "DISABLED" ] ; then
              if [ "$db_name_rating" == "$current_rating" ] ; then
                new_dbs+=( "$db_name" )
              elif [ "$db_name_rating" == "REQUIRED" ] ; then
                new_dbs+=( "$db_name" )
              elif [ "$current_rating" == "LOW" ] ; then
                if [ "$db_name_rating" == "LOWONLY" ] || [ "$db_name_rating" == "LOW" ] || [ "$db_name_rating" == "LOWMEDIUMONLY" ] ; then
                  new_dbs+=( "$db_name" )
                fi
              elif [ "$current_rating" == "MEDIUM" ] ; then
                if [ "$db_name_rating" == "MEDIUMONLY" ] || [ "$db_name_rating" == "MEDIUM" ] || [ "$db_name_rating" == "LOW" ] || [ "$db_name_rating" == "LOWMEDIUMONLY" ] ; then
                  new_dbs+=( "$db_name" )
                fi
              elif [ "$current_rating" == "HIGH" ] ; then
                if [ "$db_name_rating" == "HIGH" ] || [ "$db_name_rating" == "MEDIUM" ] || [ "$db_name_rating" == "LOW" ]; then
                  new_dbs+=( "$db_name" )
                fi
            fi
        fi
        fi
    fi
      done
    fi
  fi
  echo "${new_dbs[@]}" | xargs # Remove extra whitespace
}

# Manage the databases to be removed and allow multi-dimensions as well as global overrides
# Since the datbases are basically a multi-dimentional associative arrays in bash
# ratings: LOW | MEDIUM | HIGH | REQUIRED | LOWONLY | MEDIUMONLY | LOWMEDIUMONLY | DISABLED
function xshok_remove_database() { # rating database_array
    # Assign
    current_rating="${1}"
    declare -a current_dbs=( "${@:2}" )
    # Zero
    declare -a new_dbs=( )

    if [ ${#current_dbs} -ge 1 ] ; then
      for db_name in "${current_dbs[@]}" ; do
          db_name_rating="${db_name#*|}"
          db_name="${db_name%|*}"
          removed="no"
        # Checks
            if [ "$current_rating" == "DISABLED" ] ; then
                new_dbs+=( "$db_name" )
                removed="yes"
            elif [ "$current_rating" == "HIGH" ] ; then
                if [ "$db_name_rating" == "LOWONLY" ] ||  [ "$db_name_rating" == "LOWMEDIUMONLY" ] ||[ "$db_name_rating" == "MEDIUMONLY" ] ; then
                    new_dbs+=( "$db_name" )
                    removed="yes"
                fi
            elif [ "$current_rating" == "MEDIUM" ] ; then
                if [ "$db_name_rating" == "HIGH" ] || [ "$db_name_rating" == "LOWONLY" ] ; then
                    new_dbs+=( "$db_name" )
                    removed="yes"
                fi
            elif [ "$current_rating" == "LOW" ] ; then
                if [ "$db_name_rating" == "MEDIUMONLY" ] ||  [ "$db_name_rating" == "MEDIUM" ] || [ "$db_name_rating" == "HIGH" ]; then
                    new_dbs+=( "$db_name" )
                    removed="yes"
                fi
            fi
            if [ "$removed" == "no" ] ; then # not already removed, process futher
                if [ "$enable_yararules" == "no" ] && [[ "$db_name" == *".yar"* ]] ; then # YARA rules are disabled AND it's the value you want to delete
                    new_dbs+=( "$db_name" )
                fi
            fi
      done
    fi
    echo "${new_dbs[@]}" | xargs # Remove extra whitespace
}



################################################################################
# ADDITIONAL PROGRAM FUNCTIONS
################################################################################


# Generates a man config and installs it
function install_man() {

  if [ -n "$pkg_mgr" ] || [ -n "$pkg_rm" ] ; then
    xshok_pretty_echo_and_log "This script (clamav-unofficial-sigs) was installed on the system via ${pkg_mgr}"
    exit 1
  fi

  xshok_pretty_echo_and_log ""
  xshok_pretty_echo_and_log "Generating man file for install...."

  # Use defined varibles or attempt to use default varibles

  if [ ! -e "${man_dir}/${man_filename}" ] ; then
    mkdir -p "$man_dir"
    touch "${man_dir}/${man_filename}" 2>/dev/null
  fi
  if [ ! -w "${man_dir}/${man_filename}" ] ; then
    xshok_pretty_echo_and_log "ERROR: man install aborted, as file not writable: ${man_dir}/${man_filename}"
  else

    BOLD="\\fB"
    #REV=""
    NORM="\\fR"
    manresult="$(help_and_usage "man")"

    # Our template..
    cat << EOF > "${man_dir}/${man_filename}"

.\\" Manual page for eXtremeSHOK.com ClamAV Unofficial Signature Updater
.TH clamav-unofficial-sigs 8 "${script_version_date}" "Version: ${script_version}" "SCRIPT COMMANDS"
.SH NAME
clamav-unofficial-sigs \\- Download, test, and install third-party ClamAV signature databases.
.SH SYNOPSIS
.B clamav-unofficial-sigs
.RI [ options ]
.SH DESCRIPTION
\\fBclamav-unofficial-sigs\\fP provides a simple way to download, test, and update third-party signature databases provided by Sanesecurity, FOXHOLE, OITC, BOFHLAND, CRDF, Porcupine, Securiteinfo, MalwarePatrol, Yara-Rules Project, etc. It will also generate and install cron, logrotate, and man files.
.SH UPDATES
Script updates can be found at: \\fBhttps://github.com/extremeshok/clamav-unofficial-sigs\\fP
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
Report bugs to \\fBhttps://github.com/extremeshok/clamav-unofficial-sigs\\fP
.SH AUTHOR
Adrian Jon Kriel :: admin@extremeshok.com
Originially based on Script provide by Bill Landry


EOF

  fi
  xshok_pretty_echo_and_log "Completed: man installed, as file: ${man_dir}/${man_filename}"
}


# Generate a logrotate config and install it
function install_logrotate() {

  if [ -n "$pkg_mgr" ] || [ -n "$pkg_rm" ] ; then
    xshok_pretty_echo_and_log "This script (clamav-unofficial-sigs) was installed on the system via ${pkg_mgr}"
    exit 1
  fi

  xshok_pretty_echo_and_log ""
  xshok_pretty_echo_and_log "Generating logrotate file for install...."

  # Use defined varibles or attempt to use default varibles

  if [ -z "$logrotate_user" ] ; then
    logrotate_user="${clam_user}";
  fi
  if [ -z "$logrotate_group" ] ; then
    logrotate_group="${clam_group}";
  fi
  if [ -z "$logrotate_log_file_full_path" ] ; then
    logrotate_log_file_full_path="${log_file_path}/${log_file_name}"
  fi


  if [ ! -e "${logrotate_dir}/${logrotate_filename}" ] ; then
    mkdir -p "$logrotate_dir"
    touch "${logrotate_dir}/${logrotate_filename}" 2>/dev/null
  fi
  if [ ! -w "${logrotate_dir}/${logrotate_filename}" ] ; then
    xshok_pretty_echo_and_log "ERROR: logrotate install aborted, as file not writable: ${logrotate_dir}/${logrotate_filename}"
  else
    # Our template..
    cat << EOF > "${logrotate_dir}/${logrotate_filename}"
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
  create 0640 ${logrotate_user} ${logrotate_group}
}

EOF

  fi
  xshok_pretty_echo_and_log "Completed: logrotate installed, as file: ${logrotate_dir}/${logrotate_filename}"
}

# Generate a cron config and install it
function install_cron() {

  if [ -n "$pkg_mgr" ] || [ -n "$pkg_rm" ] ; then
    xshok_pretty_echo_and_log "This script (clamav-unofficial-sigs) was installed on the system via {$pkg_mgr}"
    exit 1
  fi

  xshok_pretty_echo_and_log ""
  xshok_pretty_echo_and_log "Generating cron file for install...."

  # Use defined varibles or attempt to use default varibles
  if [ -z "$cron_minute" ] ; then
    cron_minute="$(( ( RANDOM % 59 ) + 1 ))"
  fi
  if [ -z "$cron_user" ] ; then
    cron_user="${clam_user}";
  fi
  if [ -z "$cron_bash" ] ; then
    cron_bash="$(command -v bash 2> /dev/null)"
  fi
  if [ -z "$cron_script_full_path" ] ; then
    cron_script_full_path="$this_script_full_path"
  fi
  if [ "$cron_sudo" == "yes" ] ; then
    cron_sudo="sudo -u"
  fi
  if [ ! -e "${cron_dir}/${cron_filename}" ] ; then
    mkdir -p "$cron_dir"
    touch "${cron_dir}/${cron_filename}" 2>/dev/null
  fi
  if [ ! -w "${cron_dir}/${cron_filename}" ] ; then
    xshok_pretty_echo_and_log "ERROR: cron install aborted, as file not writable: ${cron_dir}/${cron_filename}"
  else
    # Our template..
    cat << EOF > "${cron_dir}/${cron_filename}"
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
# Uncomment to enable emails to the root user
#MAILTO=root
$cron_minute * * * * ${cron_sudo} ${cron_user} [ -x ${cron_script_full_path} ] && ${cron_bash} ${cron_script_full_path}

# https://eXtremeSHOK.com ######################################################

EOF

  fi
  xshok_pretty_echo_and_log "Completed: cron installed, as file: ${cron_dir}/${cron_filename}"
}

# Auto upgrade the master.conf and the
function xshok_upgrade() {

    if [ "$allow_upgrades" == "no" ] ; then
        xshok_pretty_echo_and_log "ERROR: --upgrade has been disabled, allow_upgrades=no"
        exit 1
    fi
    if ! xshok_is_root ; then
        xshok_pretty_echo_and_log "ERROR: Only root can run the upgrade"
        exit 1
    fi

    xshok_pretty_echo_and_log "Checking for updates ..."

    found_upgrade="no"
    if [ -n "$curl_bin" ] ; then
        # shellcheck disable=SC2086
        latest_version="$($curl_bin --compressed $curl_proxy $curl_insecure $curl_output_level --connect-timeout "${downloader_connect_timeout}" --remote-time --location --retry "${downloader_tries}" --max-time "${downloader_max_time}" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/clamav-unofficial-sigs.sh" 2>&11 | $grep_bin "^script_version=" | head -n1 | cut -d '"' -f 2)"
        # shellcheck disable=SC2086
        latest_config_version="$($curl_bin --compressed $curl_proxy $curl_insecure $curl_output_level --connect-timeout "${downloader_connect_timeout}" --remote-time --location --retry "${downloader_tries}" --max-time "${downloader_max_time}" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/config/master.conf" 2>&11 | $grep_bin "^config_version=" | head -n1 | cut -d '"' -f 2)"
    else
        # shellcheck disable=SC2086
        latest_version="$($wget_bin $wget_compression $wget_proxy $wget_insecure $wget_output_level --connect-timeout="${downloader_connect_timeout}" --random-wait --tries="${downloader_tries}" --timeout="${downloader_max_time}" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/clamav-unofficial-sigs.sh" -O - 2>&12 | $grep_bin "^script_version=" | head -n1 | cut -d '"' -f 2)"
        # shellcheck disable=SC2086
        latest_config_version="$($wget_bin $wget_compression $wget_proxy $wget_insecure $wget_output_level --connect-timeout="${downloader_connect_timeout}" --random-wait --tries="${downloader_tries}" --timeout="${downloader_max_time}" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/config/master.conf" -O - 2>&12 | $grep_bin "^config_version=" | head -n1 | cut -d '"' -f 2)"
    fi

  # config_dir/master.conf
    if [ "$latest_config_version" ] ; then
        # shellcheck disable=SC2183,SC2086
        if [ "$(printf "%02d%02d%02d%02d" ${latest_config_version//./ })" -gt "$(printf "%02d%02d%02d%02d" ${config_version//./ })" ] ; then
            found_upgrade="yes"
            xshok_pretty_echo_and_log "ALERT: Upgrading config from v${config_version} to v${latest_config_version}"
            if [ -w "${config_dir}/master.conf" ] && [ -f "${config_dir}/master.conf" ] ; then
                echo "Downloading https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/config/master.conf"
                xshok_file_download "${work_dir}/master.conf.tmp" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/config/master.conf" "notimestamp"
                ret="$?"
                if [ "$ret" -ne 0 ] ; then
                    xshok_pretty_echo_and_log "ERROR: Could not download https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/config/master.conf"
                    exit 1
                fi
                if ! $grep_bin -m 1 "config_version" "${work_dir}/master.conf.tmp" > /dev/null 2>&1 ; then
                    echo "ERROR: Downloaded master.conf is incomplete, please re-run"
                    exit 1
                fi
                # Copy over permissions from old version
                OCTAL_MODE="$(stat -c "%a" "${config_dir}/master.conf" 2> /dev/null)"
                if [ -z "$OCTAL_MODE" ]; then
                  OCTAL_MODE="$(stat -f '%p' "${config_dir}/master.conf")"
                fi

                xshok_pretty_echo_and_log "Running update process"
                if ! mv -f "${work_dir}/master.conf.tmp" "${config_dir}/master.conf" ; then
                    xshok_pretty_echo_and_log "ERROR: failed moving ${work_dir}/master.conf.tmp to ${config_dir}/master.conf"
                     exit 1
                fi
                if ! chmod "$OCTAL_MODE" "${config_dir}/master.conf" ; then
                     xshok_pretty_echo_and_log "ERROR: unable to set permissions on ${config_dir}/master.conf"
                     exit 1
                fi
                xshok_pretty_echo_and_log "Completed"
            else
                 xshok_pretty_echo_and_log "ERROR: ${config_dir}/master.conf is not a file or is not writable"
                 exit 1
          fi
        fi
    fi

    if [ "$latest_version" ] ; then
        # shellcheck disable=SC2183,SC2086
        if [ "$(printf "%02d%02d%02d%02d" ${latest_version//./ })" -gt "$(printf "%02d%02d%02d%02d" ${script_version//./ })" ] ; then
            found_upgrade="yes"
        xshok_pretty_echo_and_log "ALERT:  Upgrading script from v${script_version} to v${latest_version}"
            if [ -w "${config_dir}/master.conf" ] && [ -f "${config_dir}/master.conf" ] ; then
                echo "Downloading https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/clamav-unofficial-sigs.sh"
                xshok_file_download "${work_dir}/clamav-unofficial-sigs.sh.tmp" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/clamav-unofficial-sigs.sh" "notimestamp"
              ret=$?
                if [ "$ret" -ne 0 ] ; then
                    xshok_pretty_echo_and_log "ERROR: Could not download https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/clamav-unofficial-sigs.sh"
                    exit 1
                fi
                # Detect to make sure the entire script is avilable, fail if the script is missing contents
                if [ "$(tail -n 1 "${work_dir}/clamav-unofficial-sigs.sh.tmp" | head -n 1 | cut -c 1-7)" != "exit \$?" ] ; then
                    echo "ERROR: Downloaded clamav-unofficial-sigs.sh is incomplete, please re-run"
                    exit 1
                fi
                # Copy over permissions from old version
                OCTAL_MODE="$(stat -c "%a" "${this_script_full_path}" 2> /dev/null)"
                if [ -z "$OCTAL_MODE" ]; then
                    OCTAL_MODE="$(stat -f '%p' "${this_script_full_path}")"
                fi
                xshok_pretty_echo_and_log "Inserting update process..."
              # Generate the update script
              cat > "${work_dir}/xshok_update_script.sh" << EOF
#!/usr/bin/env bash
echo "Running update process"
# Overwrite old file with new
if ! mv -f "${work_dir}/clamav-unofficial-sigs.sh.tmp" "${this_script_full_path}" ; then
  echo  "ERROR: failed moving ${work_dir}/clamav-unofficial-sigs.sh.tmp to ${this_script_full_path}"
  rm -f \$0
    exit 1
fi
if ! chmod "$OCTAL_MODE" "${this_script_full_path}" ; then
     echo "ERROR: unable to set permissions on ${this_script_full_path}"
     rm -f \$0
     exit 1
fi
    echo "Completed"
    # echo "---------------------"
    # echo "Optional, run as root: "
    # echo "clamav-unofficial-sigs.sh --install-all"
    echo "---------------------"
    echo "Run once as root: "
    echo "clamav-unofficial-sigs.sh --force"

    #remove the tmp script before exit
    rm -f \$0
EOF
          # Replaced with $0, so code will update and then call itself with the same parameters it had
            #exec "${0}" "$@"
            bash_bin="$(command -v bash 2> /dev/null)"
          exec "$bash_bin" "${work_dir}/xshok_update_script.sh"
            echo "Running once as root"
        else
             xshok_pretty_echo_and_log "ERROR: ${config_dir}/master.conf is not a file or is not writable"
             exit 1
        fi
    fi
fi

if [ "$found_upgrade" == "no" ] ; then
    xshok_pretty_echo_and_log "No updates available"
fi
}


# Decode a third-party signature either by signature name
function decode_third_party_signature_by_signature_name() {
  xshok_pretty_echo_and_log ""
  xshok_pretty_echo_and_log "Input a third-party signature name to decode (e.g: Sanesecurity.Junk.15248) or"
  xshok_pretty_echo_and_log "a hexadecimal encoded data string and press enter:"
  read -r input
    # Remove quotes and .UNOFFICIAL from the whitelist input string
  input="$(echo "${input}" | tr -d "'" | tr -d '"' | tr -d '`')"
    input=${input/\.UNOFFICIAL/}
  if echo "${input}" | $grep_bin "\\." > /dev/null ; then
    cd "$clam_dbs" || exit
    sig="$($grep_bin "${input}:" ./*.ndb)"
    if [ -n "$sig" ] ; then
      db_file="${sig%:*}"
      xshok_pretty_echo_and_log "${input} found in: ${db_file}"
      xshok_pretty_echo_and_log "${input} signature decodes to:"
      xshok_pretty_echo_and_log "$sig" | cut -d ":" -f 5 | perl -pe 's/([a-fA-F0-9]{2})|(\{[^}]*\}|\([^)]*\))/defined $2 ? $2 : chr(hex $1)/eg'
    else
      xshok_pretty_echo_and_log "Signature ${input} could not be found."
      xshok_pretty_echo_and_log "This script will only decode ClamAV 'UNOFFICIAL' third-Party,"
      xshok_pretty_echo_and_log "non-image based, signatures as found in the *.ndb databases."
    fi
  else
    xshok_pretty_echo_and_log "Here is the decoded hexadecimal input string:"
    echo "${input}" | perl -pe 's/([a-fA-F0-9]{2})|(\{[^}]*\}|\([^)]*\))/defined $2 ? $2 : chr(hex $1)/eg'
  fi
}

# Hexadecimal encode an entire input string
function hexadecimal_encode_entire_input_string() {
  xshok_pretty_echo_and_log ""
  xshok_pretty_echo_and_log "Input the data string that you want to hexadecimal encode and then press enter.  Do not include"
  xshok_pretty_echo_and_log "any quotes around the string unless you want them included in the hexadecimal encoded output:"
  read -r input
  xshok_pretty_echo_and_log "Here is the hexadecimal encoded input string:"
  echo "${input}" | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg'
}

# Hexadecimal encode a formatted input string
function hexadecimal_encode_formatted_input_string() {
  xshok_pretty_echo_and_log ""
  xshok_pretty_echo_and_log "Input a formated data string containing spacing fields '{}, (), *' that you want to hexadecimal"
  xshok_pretty_echo_and_log "encode, without encoding the spacing fields, and then press enter.  Do not include any quotes"
  xshok_pretty_echo_and_log "around the string unless you want them included in the hexadecimal encoded output:"
  read -r input
  xshok_pretty_echo_and_log "Here is the hexadecimal encoded input string:"
  echo "${input}" | perl -pe 's/(\{[^}]*\}|\([^)]*\)|\*)|(.)/defined $1 ? $1 : sprintf("%02lx", ord $2)/eg'
}

# GPG verify a specific Sanesecurity database file
function gpg_verify_specific_sanesecurity_database_file() { # databasefile
  xshok_pretty_echo_and_log ""
  if [ "$enable_gpg" == "no" ] ; then
    xshok_pretty_echo_and_log "GnuPG / signature verification disabled" "-"
  else
    if [ "${1}" ] ; then
      db_file="$(echo "${1}" | awk -F "/" '{print $NF}')"
      if [ -r "${work_dir_sanesecurity}/${db_file}" ] ; then
        xshok_pretty_echo_and_log "GPG signature testing database file: ${work_dir_sanesecurity}/${db_file}"
        if [ -r "${work_dir_sanesecurity}/${db_file}.sig" ] ; then
          if ! "$gpg_bin" -q --trust-model always --no-default-keyring --homedir "${work_dir_gpg}" --keyring "${work_dir_gpg}/ss-keyring.gpg" --verify "${work_dir_sanesecurity}/${db_file}.sig" "${work_dir_sanesecurity}/${db_file}" ; then
            if "$gpg_bin" -q --always-trust --no-default-keyring --homedir "${work_dir_gpg}" --keyring "${work_dir_gpg}/ss-keyring.gpg" --verify "${work_dir_sanesecurity}/${db_file}.sig" "${work_dir_sanesecurity}/${db_file}" ; then
              exit 0
            else
              exit 1
            fi
          else
            exit 0
          fi
        else
          xshok_pretty_echo_and_log "Signature ${db_file}.sig cannot be found."
        fi
      else
        xshok_pretty_echo_and_log "File ${db_file} cannot be found or is not a Sanesecurity database file."
        xshok_pretty_echo_and_log "Only the following Sanesecurity and OITC databases can be GPG signature tested:"
        ls --ignore "*.sig" --ignore "*.md5" --ignore "*.ign2" --ignore "*.fp"  "${work_dir_sanesecurity}"
      fi
    else
      xshok_pretty_echo_and_log "ERROR: Missing value for option"
      exit 1
    fi
    exit 1
  fi
}

# Output system and configuration information
function output_system_configuration_information() {
  xshok_pretty_echo_and_log ""
  xshok_pretty_echo_and_log "*** SCRIPT INFORMATION ***"
  xshok_pretty_echo_and_log "${this_script_name} ${script_version} (${script_version_date})"
    xshok_pretty_echo_and_log "Master.conf Version: ${config_version}"
    xshok_pretty_echo_and_log "Minimum required config: ${minimum_required_config_version}"
  xshok_pretty_echo_and_log "*** SYSTEM INFORMATION ***"
  $uname_bin -a
  xshok_pretty_echo_and_log "*** CLAMSCAN LOCATION & VERSION ***"
  xshok_pretty_echo_and_log "${clamscan_bin}"
  $clamscan_bin --version | head -1
  xshok_pretty_echo_and_log "*** RSYNC LOCATION & VERSION ***"
  xshok_pretty_echo_and_log "${rsync_bin}"
  $rsync_bin --version | head -1
  if [ -n "$curl_bin" ] ; then
        xshok_pretty_echo_and_log "*** CURL LOCATION & VERSION ***"
        xshok_pretty_echo_and_log "${curl_bin}"
        $curl_bin --version | head -1
  else
        xshok_pretty_echo_and_log "*** WGET LOCATION & VERSION ***"
        xshok_pretty_echo_and_log "${wget_bin}"
        $wget_bin --version | head -1
  fi
  if [ "$enable_gpg" == "yes" ] ; then
    xshok_pretty_echo_and_log "*** GPG LOCATION & VERSION ***"
    xshok_pretty_echo_and_log "${gpg_bin}"
    $gpg_bin --version | head -1
  fi
  xshok_pretty_echo_and_log "*** DIRECTORY INFORMATION ***"
  xshok_pretty_echo_and_log "Working Directory: ${work_dir}"
  xshok_pretty_echo_and_log "Clam Database Directory: ${clam_dbs}"
  if [ "$custom_config" != "no" ] ; then
    if [ -d "$custom_config" ] ; then
      # Assign the custom config dir and remove trailing / (removes / and //)
      xshok_pretty_echo_and_log "Custom Configuration Directory: ${custom_config}"
    else
      xshok_pretty_echo_and_log "Custom Configuration File: ${custom_config}"
    fi
  else
    xshok_pretty_echo_and_log "Configuration Directory: ${config_dir}"
  fi
    xshok_pretty_echo_and_log ""
}

# Make a signature database from an ascii file
function make_signature_database_from_ascii_file() {
  xshok_pretty_echo_and_log ""
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
  " | command "$sed_bin" 's/^          //g'
  echo -n "Do you wish to continue? "
  if xshok_prompt_confirm ; then

    echo -n "Enter the source file as /path/filename: "
    read -r source
    if [ -r "$source" ] ; then
      source_file="$(basename "$source")"

      xshok_pretty_echo_and_log "What signature prefix would you like to use?  For example: 'Phish.Domains'"
      xshok_pretty_echo_and_log "will create signatures that looks like: 'Phish.Domains.1:4:*:HexSigHere'"

      echo -n "Enter signature prefix: "
      read -r prefix
      path_file="$(echo "$source" | cut -d "." -f -1 | command "$sed_bin" 's/$/.ndb/')"
      db_file="$(basename "$path_file")"
      rm -f "$path_file"
      total="$(wc -l "$source" | cut -d " " -f 1)"
      line_num="1"

      while read -r line ; do
        line_prefix="$(echo "$line" | awk -F ":" '{print $1}')"
        if [ "$line_prefix" == "-" ] ; then
          echo "$line" | cut -d ":" -f 2- | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg' | command "$sed_bin" "s/^/$prefix\\.$line_num:4:\\*:/" >> "$path_file"
        elif [ "$line_prefix" == "=" ] ; then
          echo "$line" | cut -d ":" -f 2- | perl -pe 's/(\{[^}]*\}|\([^)]*\)|\*)|(.)/defined $1 ? $1 : sprintf("%02lx", ord $2)/eg' | command "$sed_bin" "s/^/$prefix\\.$line_num:4:\\*:/" >> "$path_file"
        else
          echo "$line" | perl -pe 's/(.)/sprintf("%02lx", ord $1)/eg' | command "$sed_bin" "s/^/$prefix\\.$line_num:4:\\*:/" >> "$path_file"
        fi
        xshok_pretty_echo_and_log "Hexadecimal encoding ${source_file} line: ${line_num} of ${total}"
        line_num="$((line_num + 1))"
      done < "$source"
    else
      xshok_pretty_echo_and_log "Source file not found, exiting..."
      exit
    fi


    xshok_pretty_echo_and_log "Signature database file created at: ${path_file}"
    if $clamscan_bin --quiet -d "$path_file" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then

      xshok_pretty_echo_and_log "Clamscan reports database integrity tested good."

      echo -n "Would you like to move '${db_file}' into '${clam_dbs}' and reload databases?"
      if xshok_prompt_confirm ; then
        if ! cmp -s "$path_file" "${clam_dbs}/${db_file}" ; then
          if $rsync_bin -pcqt "$path_file" "$clam_dbs" ; then
            perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
            perms chmod -f 0644 "$clam_dbs"/"$db_file"
            if [ "$selinux_fixes" == "yes" ] ; then
              restorecon "${clam_dbs}/${db_file}"
            fi
            $clamd_restart_opt

            xshok_pretty_echo_and_log "Signature database '${db_file}' was successfully implemented and ClamD databases reloading."
          else

            xshok_pretty_echo_and_log "Failed to add/update '${db_file}', ClamD database not reloading."
          fi
        else

          xshok_pretty_echo_and_log "Database '${db_file}' has not changed - skipping"
        fi
      else

        xshok_pretty_echo_and_log "No action taken."
      fi
    else

      xshok_pretty_echo_and_log "Clamscan reports that '${db_file}' signature database integrity tested bad."
    fi
  fi
}

# Remove the clamav-unofficial-sigs script
function remove_script() {
  xshok_pretty_echo_and_log ""
  if [ -n "$pkg_mgr" ] || [ -n "$pkg_rm" ] ; then
    xshok_pretty_echo_and_log "This script (clamav-unofficial-sigs) was installed on the system via '${pkg_mgr}'"
    xshok_pretty_echo_and_log "use '${pkg_rm}' to remove the script and all of its associated files and databases from the system."

  else
    cron_file_full_path="${cron_dir}/${cron_filename}"
    logrotate_file_full_path="${logrotate_dir}/${logrotate_filename}"
    man_file_full_path="${man_dir}/${man_filename}"

    xshok_pretty_echo_and_log "This will remove the workdir (${work_dir}), logrotate file (${logrotate_file_full_path}), cron file (${cron_file_full_path}), man file (${man_file_full_path})"
    xshok_pretty_echo_and_log "Are you sure you want to remove the clamav-unofficial-sigs script and all of its associated files, third-party databases, and work directory from the system?"
    if xshok_prompt_confirm ; then
      xshok_pretty_echo_and_log "This can not be undone are you sure ?"
      if xshok_prompt_confirm ; then
        if [ -r "${work_dir_work_configs}/purge.txt" ] ; then

          while read -r file ; do
            xshok_is_file "$file" && rm -f -- "$file"
            xshok_pretty_echo_and_log "     Removed file: ${file}"
          done < "${work_dir_work_configs}/purge.txt"
          if [ -r "$cron_file_full_path" ] ; then
            xshok_is_file "$cron_file_full_path" && rm -f "$cron_file_full_path"
            xshok_pretty_echo_and_log "     Removed file: ${cron_file_full_path}"
          fi
          if [ -r "$logrotate_file_full_path" ] ; then
            xshok_is_file "$logrotate_file_full_path" && rm -f "$logrotate_file_full_path"
            xshok_pretty_echo_and_log "     Removed file: ${logrotate_file_full_path}"
          fi
          if [ -r "$man_file_full_path" ] ; then
            xshok_is_file "$man_file_full_path" && rm -f "$man_file_full_path"
            xshok_pretty_echo_and_log "     Removed file: ${man_file_full_path}"
          fi

          # Rather keep the configs
          #rm -f -- "$default_config" && echo "     Removed file: $default_config"
          #rm -f -- "${0}" && echo "     Removed file: $0"
          xshok_is_subdir "$work_dir" && rm -rf -- "${work_dir:?}" && echo "     Removed script working directories: ${work_dir}"

          xshok_pretty_echo_and_log "  The clamav-unofficial-sigs script and all of its associated files, third-party"
          xshok_pretty_echo_and_log "  databases, and work directories have been successfully removed from the system."

        else
          xshok_pretty_echo_and_log "  Cannot locate 'purge.txt' file in ${work_dir_work_configs}."
          xshok_pretty_echo_and_log "  Files and signature database will need to be removed manually."
        fi
      else
        xshok_pretty_echo_and_log "Aborted"
      fi
    else
      xshok_pretty_echo_and_log "Aborted"
    fi
  fi
}

# Clamscan integrity test a specific database file
function clamscan_integrity_test_specific_database_file() { # databasefile
  xshok_pretty_echo_and_log ""
  if [ "${1}" ] ; then
    input="$(echo "${1}" | awk -F "/" '{print $NF}')"
    db_file="$(find "$work_dir" -name "$input")"
    if [ -r "$db_file" ] ; then
      xshok_pretty_echo_and_log "Clamscan integrity testing: ${db_file}"
      if $clamscan_bin --quiet -d "$db_file" "${work_dir_work_configs}/scan-test.txt" ; then
        xshok_pretty_echo_and_log "Clamscan reports that '${input}' database integrity tested GOOD"
        exit 0
      else
        xshok_pretty_echo_and_log "Clamscan reports that '${input}' database integrity tested BAD"
        exit 1
      fi
    else
      xshok_pretty_echo_and_log "File '${input}' cannot be found."
      xshok_pretty_echo_and_log "Here is a list of third-party databases that can be clamscan integrity tested:"

      xshok_pretty_echo_and_log "=== Sanesecurity ==="
      ls --ignore "*.sig" --ignore "*.md5" --ignore "*.ign2" --ignore "*.fp"  "$work_dir_sanesecurity"

      xshok_pretty_echo_and_log "=== SecuriteInfo ==="
      ls --ignore "*.sig" --ignore "*.md5" --ignore "*.ign2" --ignore "*.fp"  "$work_dir_securiteinfo"

      xshok_pretty_echo_and_log "=== MalwarePatrol ==="
      ls --ignore "*.sig" --ignore "*.md5" --ignore "*.ign2" --ignore "*.fp"  "$work_dir_malwarepatrol"

      xshok_pretty_echo_and_log "=== Linux Malware Detect ==="
      ls --ignore "*.sig" --ignore "*.md5" --ignore "*.ign2" --ignore "*.fp"  "$work_dir_linuxmalwaredetect"

      xshok_pretty_echo_and_log "=== interServer Detect ==="
      ls --ignore "*.sig" --ignore "*.md5" --ignore "*.ign2" --ignore "*.fp"  "$work_dir_interserver"

      xshok_pretty_echo_and_log "=== Malware Expert Detect ==="
      ls --ignore "*.sig" --ignore "*.md5" --ignore "*.ign2" --ignore "*.fp"  "$work_dir_malwareexpert"

      xshok_pretty_echo_and_log "=== Linux Malware Detect ==="
      ls --ignore "*.sig" --ignore "*.md5" --ignore "*.ign2" --ignore "*.fp"  "$work_dir_yararulesproject"

      xshok_pretty_echo_and_log "=== User Defined Databases ==="
      ls --ignore "*.sig" --ignore "*.md5" --ignore "*.ign2" --ignore "*.fp"  "$work_dir_add"

      xshok_pretty_echo_and_log "Check the file name and try again..."
    fi
  else
    xshok_pretty_echo_and_log "ERROR: Missing value for option"
    exit 1
  fi
}

# Output names of any third-party signatures that triggered during the HAM directory scan
function output_signatures_triggered_during_ham_directory_scan() {
  xshok_pretty_echo_and_log ""
  if [ -n "$ham_dir" ] ; then
    if [ -r "${work_dir_work_configs}/whitelist.hex" ] ; then
      xshok_pretty_echo_and_log "The following third-party signatures triggered hits during the HAM Directory scan:"

      $grep_bin -h -f "${work_dir_work_configs}/whitelist.hex" "$work_dir"/*/*.ndb | cut -d ":" -f 1
      $grep_bin -h -f "${work_dir_work_configs}/whitelist.hex" "$work_dir"/*/*.db | cut -d "=" -f 1
    else
      xshok_pretty_echo_and_log "No third-party signatures have triggered hits during the HAM Directory scan."
    fi
  else
    xshok_pretty_echo_and_log "Ham directory scanning is not currently enabled in the script's configuration file."
  fi
}

# Adds a signature whitelist entry in the newer ClamAV IGN2 format
function add_signature_whitelist_entry() { #signature
  xshok_pretty_echo_and_log "Signature Whitelist" "="
    if [ -n "$1" ] ; then
        input="$1"
    else
        xshok_pretty_echo_and_log "Input a third-party signature name that you wish to whitelist and press enter"
        read -r input
    fi
  if [ -n "$input" ] ; then
        xshok_pretty_echo_and_log "Processing: ${input}"
    cd "$clam_dbs" || exit
        # Remove quotes and .UNOFFICIAL from the string
        input="$(echo "${input}" | tr -d "'" | tr -d '"' | tr -d '`"')"
        input=${input/\.UNOFFICIAL/}

        yaratest="$(echo "$input" | cut -d "." -f 1)"
        shopt -s nocasematch
        if [ "$yaratest" == "YARA" ] ; then
            echo "YARA signature detected"
            sig_full="$input"
            sig_extension=""
            sig_name="$input"
        else
            sig_full="$($grep_bin -H -m 1 "$input" ./*.*db)"
            sig_extension=${sig_full%%\:*}
            sig_extension=${sig_extension##*\.}
            shopt -s nocasematch
            if [ "$sig_extension" == "hdb" ] || [ "$sig_extension" == "hsb" ] || [ "$sig_extension" == "hdu " ] || [ "$sig_extension" == "hsu" ] || [ "$sig_extension" == "mdb" ] || [ "$sig_extension" == "msb" ] || [ "$sig_extension" == "mdu" ] || [ "$sig_extension" == "msu" ] ; then
                # Hash-based Signature Database
                position="4"
            else
                position="2"
            fi
            sig_name="$(echo "$sig_full" | cut -d ":" -f $position | cut -d "=" -f 1)"
        fi

    if [ -n "$sig_name" ] ; then
      if ! $grep_bin -m 1 "$sig_name" my-whitelist.ign2 > /dev/null 2>&1 ; then
        cp -f -p my-whitelist.ign2 "$work_dir_work_configs" 2>/dev/null
        echo "$sig_name" >> "${work_dir_work_configs}/my-whitelist.ign2"
        shopt -s nocasematch
        if [ "$yaratest" != "YARA" ] ; then
            echo "$sig_full" >> "${work_dir_work_configs}/tracker.txt"
        fi

        if $clamscan_bin --quiet -d "${work_dir_work_configs}/my-whitelist.ign2" "${work_dir_work_configs}/scan-test.txt" ; then
          if $rsync_bin -pcqt "${work_dir_work_configs}/my-whitelist.ign2" "$clam_dbs" ; then
            perms chown -f "${clam_user}:${clam_group}" my-whitelist.ign2

            if [ ! -s "${work_dir_work_configs}/monitor-ign.txt" ] ; then
              # Create "monitor-ign.txt" file for clamscan database integrity testing.
              echo "This is the monitor ignore file..." > "${work_dir_work_configs}/monitor-ign.txt"
            fi

            perms chmod -f 0644 my-whitelist.ign2 "${work_dir_work_configs}/monitor-ign.txt"
            if [ "$selinux_fixes" == "yes" ] ; then
              restorecon "${clam_dbs}/local.ign"
            fi
            do_clamd_reload="4"
            clamscan_reload_dbs

            xshok_pretty_echo_and_log "Signature '${input}' has been added to my-whitelist.ign2 and all databases have been reloaded."
            if [ "$yaratest" != "YARA" ] ; then
                xshok_pretty_echo_and_log "The script will track any changes to the offending signature and will automatically remove it, "
                xshok_pretty_echo_and_log "if the signature is modified or removed from the third-party database."
            fi
          else

            xshok_pretty_echo_and_log "Failed to successfully update my-whitelist.ign2 file - SKIPPING."
          fi
        else

          xshok_pretty_echo_and_log "Clamscan reports my-whitelist.ign2 database integrity is bad - SKIPPING."
        fi
      else

        xshok_pretty_echo_and_log "Signature '${input}' already exists in my-whitelist.ign2 - no action taken."
      fi
    else

      xshok_pretty_echo_and_log "Signature '${input}' could not be found."

      xshok_pretty_echo_and_log "This script will only create a whitelise entry in my-whitelist.ign2 for ClamAV"
      xshok_pretty_echo_and_log "'UNOFFICIAL' third-Party signatures as found in the *.ndb *.hdb *.db databases."
    fi
  else
    xshok_pretty_echo_and_log "No input detected - no action taken."
  fi
}

# Clamscan reload database
function clamscan_reload_dbs() {
  # Reload all clamd databases if updates detected and $reload_dbs" is set to "yes"
  if [ "$reload_dbs" == "yes" ] ; then
    if [ "$do_clamd_reload" != "0" ] ; then
      if [ "$do_clamd_reload" == "1" ] ; then
        xshok_pretty_echo_and_log "Update(s) detected, reloading ClamAV databases" "="
      elif [ "$do_clamd_reload" == "2" ] ; then
        xshok_pretty_echo_and_log "Database removal(s) detected, reloading ClamAV databases" "="
      elif [ "$do_clamd_reload" == "3" ] ; then
        xshok_pretty_echo_and_log "File 'local.ign' has changed, reloading ClamAV databases" "="
      elif [ "$do_clamd_reload" == "4" ] ; then
        xshok_pretty_echo_and_log "File 'my-whitelist.ign2' has changed, reloading ClamAV databases" "="
      else
        xshok_pretty_echo_and_log "Update(s) detected, reloading ClamAV databases" "="
      fi

      if [[ "$($clamd_reload_opt 2>&1)" = *"ERROR"* ]] ; then
        xshok_pretty_echo_and_log "ERROR: Failed to reload, trying again"
        if [ -r "$clamd_pid" ] ; then
          mypid="$(cat "$clamd_pid")"

          if kill -USR2 "$mypid" ; then
            xshok_pretty_echo_and_log "ClamAV databases reloading" "="
          else
            xshok_pretty_echo_and_log "ERROR: Failed to reload, forcing clamd to restart"
            if [ -z "$clamd_restart_opt" ] ; then
              xshok_pretty_echo_and_log "WARNING: Check the script's configuration file, 'reload_dbs' enabled but no 'clamd_restart_opt'"
            else
              if $clamd_restart_opt > /dev/null ; then
                xshok_pretty_echo_and_log "ClamAV Restarted" "="
              else
                xshok_pretty_echo_and_log "ClamAV NOT Restarted" "-"
              fi
            fi
          fi
        else
          xshok_pretty_echo_and_log "ERROR: Failed to reload, forcing clamd to restart"
          if [ -z "$clamd_restart_opt" ] ; then
            xshok_pretty_echo_and_log "WARNING: Check the script's configuration file, 'reload_dbs' enabled but no 'clamd_restart_opt'"
          else
            if $clamd_restart_opt > /dev/null ; then
              xshok_pretty_echo_and_log "ClamAV Restarted" "="
            else
              xshok_pretty_echo_and_log "ClamAV NOT Restarted" "-"
            fi
          fi
        fi
      else
        xshok_pretty_echo_and_log "ClamAV databases reloading" "="
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
function check_clamav() {
  if [ -n "$clamd_socket" ] ; then
    if [ -S "$clamd_socket" ] ; then
      if [ "$(perl -e 'use IO::Socket::UNIX; print $IO::Socket::UNIX::VERSION,"\n"' 2>/dev/null)" ] ; then
        io_socket1="1"
        if [ "$(perl -MIO::Socket::UNIX -we '$s = IO::Socket::UNIX->new(shift); $s->print("PING"); print $s->getline; $s->close' "$clamd_socket" 2>/dev/null)" == "PONG" ] ; then
          io_socket2="1"
          xshok_pretty_echo_and_log "ClamD is running" "="
        fi
      else
        socat="$(command -v socat 2>/dev/null)"
        if [ -n "$socat" ] && [ -x "$socat" ] ; then
          socket_cat1="1"
          if [ "$( (echo "PING"; sleep 1;) | socat - "$clamd_socket" 2>/dev/null)" == "PONG" ] ; then
            socket_cat2="1"
            xshok_pretty_echo_and_log "ClamD is running" "="
          fi
        fi
      fi
      if [ -z "$io_socket1" ] && [ -z "$socket_cat1" ] ; then
        xshok_pretty_echo_and_log "WARNING: socat or perl module 'IO::Socket::UNIX' not found, cannot test if ClamD is running"
      else
        if [ -z "$io_socket2" ] && [ -z "$socket_cat2" ] ; then

          xshok_pretty_echo_and_log "ALERT: CLAMD IS NOT RUNNING!"
          if [ -n "$clamd_restart_opt" ] ; then
            xshok_pretty_echo_and_log "Attempting to start ClamD..." "-"
            if [ -n "$io_socket1" ] ; then
              $clamd_restart_opt > /dev/null && sleep 5
              if [ "$(perl -MIO::Socket::UNIX -we '$s = IO::Socket::UNIX->new(shift); $s->print("PING"); print $s->getline; $s->close' "$clamd_socket" 2>/dev/null)" = "PONG" ] ; then
                xshok_pretty_echo_and_log "ClamD was successfully started" "="
              else
                xshok_pretty_echo_and_log "ERROR: CLAMD FAILED TO START"
                exit 1
              fi
            else
              if [ -n "$socket_cat1" ] ; then
                $clamd_restart_opt > /dev/null && sleep 5
                if [ "$( (echo "PING"; sleep 1;) | socat - "$clamd_socket" 2>/dev/null)" == "PONG" ] ; then
                  xshok_pretty_echo_and_log "ClamD was successfully started" "="
                else
                  xshok_pretty_echo_and_log "ERROR: CLAMD FAILED TO START"
                  exit 1
                fi
              fi
            fi
          fi
        fi
      fi
    else
      xshok_pretty_echo_and_log "WARNING: ${clamd_socket} is not a usable socket"
    fi
  else
    xshok_pretty_echo_and_log "WARNING: clamd_socket is not defined in the configuration file"
  fi
}

# Check for a new version
function check_new_version() {
    found_upgrade="no"
  if [ -n "$curl_bin" ] ; then
        # shellcheck disable=SC2086
        latest_version="$($curl_bin --compressed $curl_proxy $curl_insecure $curl_output_level --connect-timeout "${downloader_connect_timeout}" --remote-time --location --retry "${downloader_tries}" --max-time "${downloader_max_time}" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/clamav-unofficial-sigs.sh" 2>&11 | $grep_bin "^script_version=" | head -n1 | cut -d '"' -f 2)"
        # shellcheck disable=SC2086
        latest_config_version="$($curl_bin --compressed $curl_proxy $curl_insecure $curl_output_level --connect-timeout "${downloader_connect_timeout}" --remote-time --location --retry "${downloader_tries}" --max-time "${downloader_max_time}" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/config/master.conf" 2>&11 | $grep_bin "^config_version=" | head -n1 | cut -d '"' -f 2)"
    else
        # shellcheck disable=SC2086
        latest_version="$($wget_bin $wget_compression $wget_proxy $wget_insecure $wget_output_level --connect-timeout="${downloader_connect_timeout}" --random-wait --tries="${downloader_tries}" --timeout="${downloader_max_time}" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/clamav-unofficial-sigs.sh" -O - 2>&12 | $grep_bin "^script_version=" | head -n1 | cut -d '"' -f 2)"
        # shellcheck disable=SC2086
        latest_config_version="$($wget_bin $wget_compression $wget_proxy $wget_insecure $wget_output_level --connect-timeout="${downloader_connect_timeout}" --random-wait --tries="${downloader_tries}" --timeout="${downloader_max_time}" "https://raw.githubusercontent.com/extremeshok/clamav-unofficial-sigs/${git_branch}/config/master.conf" -O - 2>&12 | $grep_bin "^config_version=" | head -n1 | cut -d '"' -f 2)"
    fi
  if [ "$latest_version" ] ; then
        # shellcheck disable=SC2183,SC2086
        if [ "$(printf "%02d%02d%02d%02d" ${latest_version//./ })" -gt "$(printf "%02d%02d%02d%02d" ${script_version//./ })" ] ; then
      xshok_pretty_echo_and_log "ALERT: New version : v${latest_version} @ https://github.com/extremeshok/clamav-unofficial-sigs"
            found_upgrade="yes"
    fi
  fi
  if [ "$latest_config_version" ] ; then
        # shellcheck disable=SC2183,SC2086
        if [ "$(printf "%02d%02d%02d%02d" ${latest_config_version//./ })" -gt "$(printf "%02d%02d%02d%02d" ${config_version//./ })" ] ; then
      xshok_pretty_echo_and_log "ALERT: New config version : v${latest_config_version} @ https://github.com/extremeshok/clamav-unofficial-sigs"
            found_upgrade="yes"
    fi
  fi

if [ "$found_upgrade" == "yes" ] && [ "$allow_upgrades" == "yes" ] ; then
    xshok_pretty_echo_and_log "Quickly upgrade, run the following command as root:"
    xshok_pretty_echo_and_log "${this_script_name} --upgrade"
fi

}

# Display help and usage
# Usage:
# help_and_usage "1" - enables the man output formatting
# help_and_usage - normal help output formatting
function help_and_usage() {

  if [ "${1}" ] ; then
    # option_format_start
    ofs="\\fB"
    # option_format_end
    ofe="\\fR"
    # option_format_blankline
    ofb=".TP"
    # option_format_tab_line
    oft=" "
  else
    # option_format_start
    ofs="${BOLD}"
    # option_format_end
    ofe="${NORM}\\t"
    # option_format_blankline
    ofb="\\n"
    # option_format_tab_line
    oft="\\n\\t"
  fi

  helpcontents="$(cat << EOF
${ofs} Usage: $(basename "$0") ${ofe} [OPTION] [PATH|FILE]
${ofb}
${ofs} -c, --config ${ofe} Use a specific configuration file or directory ${oft} eg: '-c /your/dir' or ' -c /your/file.name'  ${oft} Note: If a directory is specified the directory must contain atleast:  ${oft} master.conf, os.conf or user.conf ${oft} Default Directory: ${config_dir}
${ofb}
${ofs} -F, --force ${ofe} Force all databases to be downloaded, could cause ip to be blocked
${ofb}
${ofs} -h, --help ${ofe} Display this script's help and usage information
${ofb}
${ofs} -V, --version ${ofe} Output script version and date information
${ofb}
${ofs} -v, --verbose ${ofe} Be verbose, enabled when not run under cron
${ofb}
${ofs} -s, --silence ${ofe} Only output error messages, enabled when run under cron
${ofb}
${ofs} -d, --decode-sig ${ofe} Decode a third-party signature either by signature name ${oft} (eg: Sanesecurity.Junk.15248) or hexadecimal string. ${oft} This flag will 'NOT' decode image signatures
${ofb}
${ofs} -e, --encode-string ${ofe} Hexadecimal encode an entire input string that can ${oft} be used in any '*.ndb' signature database file
${ofb}
${ofs} -f, --encode-formatted ${ofe} Hexadecimal encode a formatted input string containing ${oft} signature spacing fields '{}, (), *', without encoding ${oft} the spacing fields, so that the encoded signature ${oft} can be used in any '*.ndb' signature database file
${ofb}
${ofs} -g, --gpg-verify ${ofe} GPG verify a specific Sanesecurity database file ${oft} eg: '-g filename.ext' (do not include file path)
${ofb}
${ofs} -i, --information ${ofe} Output system and configuration information for ${oft} viewing or possible debugging purposes
${ofb}
${ofs} -m, --make-database ${ofe} Make a signature database from an ascii file containing ${oft} data strings, with one data string per line.  Additional ${oft} information is provided when using this flag
${ofb}
${ofs} -t, --test-database ${ofe} Clamscan integrity test a specific database file ${oft} eg: '-t filename.ext' (do not include file path)
${ofb}
${ofs} -o, --output-triggered ${ofe} If HAM directory scanning is enabled in the script's ${oft} configuration file, then output names of any third-party ${oft} signatures that triggered during the HAM directory scan
${ofb}
${ofs} -w, --whitelist <signature-name> ${ofe} Adds a signature whitelist entry in the newer ClamAV IGN2 ${oft} format to 'my-whitelist.ign2' in order to temporarily resolve ${oft} a false-positive issue with a specific third-party signature. ${oft} Script added whitelist entries will automatically be removed ${oft} if the original signature is either modified or removed from ${oft} the third-party signature database
${ofb}
${ofs} --check-clamav ${ofe} If ClamD status check is enabled and the socket path is correctly ${oft} specifiedthen test to see if clamd is running or not
${ofb}
${ofs} --upgrade ${ofe} Upgrades this script and master.conf to the latest available version
${ofb}
${ofs} --install-all ${ofe} Install and generate the cron, logroate and man files, autodetects the values ${oft} based on your config files
${ofb}
${ofs} --install-cron ${ofe} Install and generate the cron file, autodetects the values ${oft} based on your config files
${ofb}
${ofs} --install-logrotate ${ofe} Install and generate the logrotate file, autodetects the ${oft} values based on your config files
${ofb}
${ofs} --install-man ${ofe} Install and generate the man file, autodetects the ${oft} values based on your config files
${ofb}
${ofs} --remove-script ${ofe} Remove the clamav-unofficial-sigs script and all of ${oft} its associated files and databases from the system
${ofb}
EOF
  )" # This is very important
  if [ "${1}" ] ; then
    echo "${helpcontents//-/\\-}"
  else
    echo -e "$helpcontents"
  fi
}
################################################################################
# MAIN PROGRAM
################################################################################

# Script Info
script_version="7.2.5"
script_version_date="2021-03-20"
minimum_required_config_version="96"
minimum_yara_clamav_version="0.100"

# Discover script: name, full_path and path
this_script_full_path="${BASH_SOURCE[0]}"
# follow the symlinks
while [ -h "$this_script_full_path" ]; do
  this_script_path="$( cd -P "$( dirname "$this_script_full_path" )" >/dev/null 2>&1 && pwd )"
  this_script_full_path="$(readlink "$this_script_full_path")"
    # if relative symlink, then resolve the path
  if [[ $this_script_full_path != /* ]] ; then
    this_script_full_path="$this_script_path/$this_script_full_path"
  fi
done
this_script_path="$( cd -P "$( dirname "$this_script_full_path" )" >/dev/null 2>&1 && pwd )"
this_script_name="$(basename "$this_script_full_path")"

if [ -z "$this_script_full_path" ] || [ -z "$this_script_path" ] || [ -z "$this_script_name" ] ; then
    echo "ERROR: could not determin script name and fullpath"
    exit 1
fi

#allow for other negatives besides no.
#disabled_values_array=("0 no No NO false False FALSE off Off OFF disable Disable DISABLE disabled Disabled DISABLED")
# if [[ " ${disabled_values_array[@]} " =~ " ${value} " ]]; then
#     # whatever you want to do when arr contains value
# fi
#
# if [[ ! " ${disabled_values_array[@]} " =~ " ${value} " ]]; then
#     # whatever you want to do when arr doesn't contain value
# fi

# Initialise
config_version="0"
do_clamd_reload="0"
comment_silence="no"
force_verbose="no"
logging_enabled="no"
force_updates="no"
force_wget="no"
enable_log="no"
custom_config="no"
we_have_a_config="0"


# Attempt to scan for a valid config dir
if [ -f "/etc/clamav-unofficial-sigs/master.conf" ] ; then
  config_dir="/etc/clamav-unofficial-sigs"
elif [ -f "/usr/local/etc/clamav-unofficial-sigs/master.conf" ] ; then
  config_dir="/usr/local/etc/clamav-unofficial-sigs/"
elif [ -f "/opt/zimbra/conf/clamav-unofficial-sigs/master.conf" ] ; then
  config_dir="/opt/zimbra/conf/clamav-unofficial-sigs/"
else
  xshok_pretty_echo_and_log "ERROR: config_dir (/etc/clamav-unofficial-sigs/master.conf) could not be found"
  exit 1
fi
# Default config files
if [ -r "${config_dir}/master.conf" ] ; then
    config_files+=( "${config_dir}/master.conf" )
else
    xshok_pretty_echo_and_log "ERROR: ${config_dir}/master.conf is not readable"
    exit 1
fi
if [ -r "${config_dir}/os.conf" ] ; then
    config_files+=( "${config_dir}/os.conf" )
else
    #find the a suitable os.*.conf file
    os_config_number=$(find "$config_dir" -type f -iname "os.*.conf" | wc -l)
    if [ "$os_config_number" == "0" ] ; then
        xshok_pretty_echo_and_log "WARNING: no os.conf or os.*.conf found"
    elif [ "$os_config_number" == "1" ] ; then
        config_file="$(find "$config_dir" -type f -iname "os.*.conf" | head -n1)"
        if [ -r "${config_file}" ]; then
            config_files+=( "${config_file}" )
        else
            xshok_pretty_echo_and_log "WARNING: ${config_file} is not readable"
        fi
    else
        xshok_pretty_echo_and_log "WARNING: Too many os.*.conf configs found"
    fi
fi
if [ -r "${config_dir}/user.conf" ] ; then
    config_files+=( "${config_dir}/user.conf" )
else
    xshok_pretty_echo_and_log "WARNING: ${config_dir}/user.conf is not readable"
fi

# Solaris command -v function returns garbage when the program is not found k
# only define the new command -v function if running under Solaris
if [ "$(uname -s)" == "SunOS" ] ; then
  function which() {
    # Use the switch -p to ignore ksh internal commands
    ksh whence -p "$@"
  }
fi

# sed_bin, this is required to be known upfront, due to how the configs are read.
if [ -z "$sed_bin" ] ; then
    # Detect support for sed or gsed
    if [ "$(uname -s)" == "Darwin" ] || [ "$(uname -s)" == "OpenBSD" ] || [ "$(uname -s)" == "NetBSD" ] || [ "$(uname -s)" == "FreeBSD" ] ; then
        sed_bin="$(command -v gsed 2> /dev/null)"
        if [ -z "$sed_bin" ]; then
            xshok_pretty_echo_and_log "ERROR: gsed (gnu sed) is missing"
            exit 1
        fi
    else
        sed_bin="$(command -v sed 2> /dev/null)"
        if [ -z "$sed_bin" ]; then
            xshok_pretty_echo_and_log "ERROR: sed is missing"
            exit 1
        fi
    fi
elif [[ "$sed_bin" =~ "/" ]] ; then
    if [ ! -x "$sed_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: sed (${sed_bin}) is not executable"
        exit 1

    fi
fi
# grep_bin, this is required to be known upfront, due to how the configs are read.
if [ -z "$grep_bin" ] ; then
    # Detect support for grep or gnugrep
    if [ -x /usr/gnu/bin/grep ]  ; then
        grep_bin="/usr/gnu/bin/grep"
    else
        grep_bin="$(command -v grep 2> /dev/null)"
        if [ -z "$grep_bin" ] ; then
            xshok_pretty_echo_and_log "ERROR: grep binary (grep_bin) not found"
            exit 1
        fi
    fi
elif [[ "$grep_bin" =~ "/" ]] ; then
    if [ ! -x "$grep_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: grep (${grep_bin}) is not executable"
        exit 1

    fi
fi

# Detect if terminal
if [ -t 1 ] ; then
  # Set fonts
  # Usage: echo "${BOLD}-a${NORM}"
  BOLD="$(tput bold)"
  #REV=$(tput smso)
  NORM="$(tput sgr0)"
  # Verbose
  force_verbose="yes"
else
  # Null fonts
  BOLD=""
  #REV=""
  NORM=""
  # Silence
  force_verbose="no"
fi

# Generic command line options
while true ; do
  case "${1}" in
    -c|--config) xshok_check_s2 "${2}"; custom_config="${2}"; shift 2; break ;;
    -F|--force) force_updates="yes"; shift 1; break ;;
    -v|--verbose) force_verbose="yes"; shift 1; break ;;
    -s|--silence) force_verbose="no"; shift 1; break ;;
    *) break ;;
  esac
done

# Set the verbosity
if [ "$force_verbose" == "yes" ] ; then
  # Verbose
  downloader_silence="no"
  rsync_silence="no"
  gpg_silence="no"
  comment_silence="no"
else
  # Silence
  downloader_silence="yes"
  rsync_silence="yes"
  gpg_silence="yes"
  comment_silence="yes"
fi

xshok_pretty_echo_and_log "" "#" "80"
xshok_pretty_echo_and_log " eXtremeSHOK.com ClamAV Unofficial Signature Updater"
xshok_pretty_echo_and_log " Version: v${script_version} (${script_version_date})"
xshok_pretty_echo_and_log " Required Configuration Version: v${minimum_required_config_version}"
xshok_pretty_echo_and_log " Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com"
xshok_pretty_echo_and_log "" "#" "80"

# Generic command line options
while true ; do
  case "${1}" in
    -h|--help) help_and_usage; exit ;;
    -V|--version) exit ;;
    *) break ;;
  esac
done

# CONFIG LOADING AND ERROR CHECKING ##############################################
if [ "$custom_config" != "no" ] ; then
  if [ -d "$custom_config" ] ; then
    # Assign the custom config dir and remove trailing / (removes / and //)
    shopt -s extglob; config_dir="${custom_config%%+(/)}"
        config_files=()
        if [ -r "${config_dir}/master.conf" ] ; then
            config_files+=( "${config_dir}/master.conf" )
        else
            xshok_pretty_echo_and_log "WARNING: ${config_dir}/master.conf not found"
        fi
        #find the a suitable os.conf or os.*.conf file
        config_file="$(find "$config_dir" -type f -iname "os.conf" -o -iname "os.*.conf" | tail -n1)"
        if [ -r "${config_file}" ] ; then
            config_files+=( "${config_file}" )
        else
            xshok_pretty_echo_and_log "WARNING: ${config_dir}/os.conf not found"
        fi
        if [ -r "${config_dir}/user.conf" ] ; then
            config_files+=( "${config_dir}/user.conf" )
        else
            xshok_pretty_echo_and_log "WARNING: ${config_dir}/user.conf not found"
        fi
  else
    config_files=( "$custom_config" )
  fi
fi

for config_file in "${config_files[@]}" ; do
  if [ -r "$config_file" ] ; then # Exists and readable
    we_have_a_config="1"
    # Config stripping
    xshok_pretty_echo_and_log "Loading config: ${config_file}"

    if [ "$(uname -s)" == "SunOS" ] ; then
      # Solaris FIXES only, i had issues with running with a single command..
      clean_config="$(command "$sed_bin" -e '/^#.*/d' "$config_file")" # Comment line
      #clean_config="$(echo "$clean_config" | $sed_bin -e 's/#[[:space:]].*//')" # Comment line (duplicated)
      clean_config=${clean_config//\#*/} # Comment line (duplicated)
      # shellcheck disable=SC2001
      clean_config="$(echo "$clean_config" | $sed_bin -e '/^[[:blank:]]*#/d;s/#.*//')" # Comments at end of line
      #clean_config="$(echo "$clean_config" | $sed_bin -e 's/^[[:blank:]]*//;s/[[:blank:]]*$//')" # trailing and leading whitespace
      clean_config="$(echo "$clean_config" | xargs)"
      # shellcheck disable=SC2001
      clean_config="$(echo "$clean_config" | $sed_bin -e '/^\s*$/d')" # Blank lines

    elif [ "$(uname -s)" == "Darwin" ] || [ "$(uname -s)" == "OpenBSD" ] || [ "$(uname -s)" == "NetBSD" ] || [ "$(uname -s)" == "FreeBSD" ] ; then
      # macOS / OSX / BSD fixes, had issues with running with a single command and with SunOS work around..
      # shellcheck disable=SC2001
      clean_config="$(command "$sed_bin" -e '/^#.*/d' "$config_file")" # Comment line
      # shellcheck disable=SC2001
      clean_config="$(echo "$clean_config" | $sed_bin -e 's/#[[:space:]].*//')" # Comment line (duplicated)
      # shellcheck disable=SC2001
      clean_config="$(echo "$clean_config" | $sed_bin -e '/^[[:blank:]]*#/d;s/#.*//')" # Comments at end of line
      #clean_config="$(echo "$clean_config" | $sed_bin -e 's/^[[:blank:]]*//;s/[[:blank:]]*$//')" # trailing and leading whitespace
      #clean_config="$(echo "$clean_config" | xargs)"
      # shellcheck disable=SC2001
      clean_config="$(echo "$clean_config" | $sed_bin -e '/^\s*$/d')" # Blank lines

    else
      # Delete lines beginning with #
      # Delete from " #" to end of the line
      # Delete from "# " to end of the line
      # Delete both trailing and leading whitespace
      # Delete all trailing whitespace
      # Delete all empty lines
      clean_config="$(command "$sed_bin" -e '/^#.*/d' -e 's/[[:space:]]#.*//' -e 's/#[[:space:]].*//' -e 's/^[[:blank:]]*//;s/[[:blank:]]*$//' -e '/^[[:space:]]*$/d' "$config_file")"
    fi

    #fix eval of |
    clean_config="${clean_config//|/\\|}"

    # Config error checking
    # Check "" are an even number
    config_check="${clean_config//[^\"]}"
    if [ "$(( ${#config_check} % 2 ))" -eq 1 ] ; then
      xshok_pretty_echo_and_log "ERROR: Your configuration has errors, every \" requires a closing \""
      exit 1
    fi

    # Check there is an = for every set of "" optional whitespace \s* between = and "
    config_check_vars="$(echo "$clean_config" | $grep_bin -c '=[[:space:]]*\"' )"

    if [ $(( ${#config_check} / 2 )) -ne "$config_check_vars" ] ; then
      xshok_pretty_echo_and_log "ERROR: Your configuration has errors, every = requires a pair of \"\""
      exit 1
    fi

    # backslash pipe
    #clean_config="${clean_config//|/\|}"

    # Config loading
    for i in "${clean_config[@]}" ; do
      eval "$(echo "${i}" | command "$sed_bin" -e 's/[[:space:]]*$//' 2> /dev/null)"
    done
  fi
done


# Assign the log_file_path earlier and remove trailing / (removes / and //)
shopt -s extglob; log_file_path="${log_file_path%%+(/)}"
# Only start logging once all the configs have been loaded
if [ "$logging_enabled" == "yes" ] ; then
  enable_log="yes"
fi

# Make sure we have a readable config file
if [ "$we_have_a_config" == "0" ] ; then
  xshok_pretty_echo_and_log "ERROR: Config file/s could NOT be read/loaded"
  xshok_pretty_echo_and_log "Note: Possible fix would be to checkl the config dir ${config_dir} exists and contains config files"
  exit 1
fi

# Prevent some issues with an incomplete or only a user.conf being loaded
if [ "$config_version" == "0" ] ; then
  xshok_pretty_echo_and_log "ERROR: Config file/s are missing important contents"
  xshok_pretty_echo_and_log "Note: Possible fix would be to point the script to the dir with the configs"
  exit 1
fi

# Config version validation
if [ "$config_version" -lt "$minimum_required_config_version" ] ; then
  xshok_pretty_echo_and_log "ERROR: Your config version ${config_version} is not compatible with the min required version ${minimum_required_config_version}"
  exit 1
fi

# Check to see if the script's "USER CONFIGURATION FILE" has been completed.
if [ "$user_configuration_complete" != "yes" ] ; then
  xshok_pretty_echo_and_log "WARNING: SCRIPT CONFIGURATION HAS NOT BEEN COMPLETED"
  xshok_pretty_echo_and_log "Please review the script configuration files"
  xshok_pretty_echo_and_log "and uncomment the following line in user.conf"
  xshok_pretty_echo_and_log "#user_configuration_complete=\"yes\""
  exit 1
fi

# Assign the directories and remove trailing / (removes / and //)
shopt -s extglob; work_dir="${work_dir%%+(/)}"

# Allow overriding of all the individual workdirs, this is mainly to aid package maintainers
if [ -z "$work_dir_sanesecurity" ] ; then
  work_dir_sanesecurity="$(echo "${work_dir}/${sanesecurity_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_sanesecurity="${work_dir_sanesecurity%%+(/)}"
fi
if [ -z "$work_dir_securiteinfo" ] ; then
  work_dir_securiteinfo="$(echo "${work_dir}/${securiteinfo_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_securiteinfo="${work_dir_securiteinfo%%+(/)}"
fi
if [ -z "$work_dir_linuxmalwaredetect" ] ; then
  work_dir_linuxmalwaredetect="$(echo "${work_dir}/${linuxmalwaredetect_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_malwarepatrol="${work_dir_malwarepatrol%%+(/)}"
fi
if [ -z "$work_dir_interserver" ] ; then
  work_dir_interserver="$(echo "${work_dir}/${interserver_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_interserver="${work_dir_interserver%%+(/)}"
fi
if [ -z "$work_dir_malwareexpert" ] ; then
  work_dir_malwareexpert="$(echo "${work_dir}/${malwareexpert_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_malwareexpert="${work_dir_malwareexpert%%+(/)}"
fi
if [ -z "$work_dir_malwarepatrol" ] ; then
  work_dir_malwarepatrol="$(echo "${work_dir}/${malwarepatrol_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_malwarepatrol="${work_dir_malwarepatrol%%+(/)}"
fi
if [ -z "$work_dir_urlhaust" ] ; then
  work_dir_urlhaus="$(echo "${work_dir}/${urlhaus_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_urlhaus="${work_dir_urlhaus%%+(/)}"
fi
if [ -z "$work_dir_yararulesproject" ] ; then
  work_dir_yararulesproject="$(echo "${work_dir}/${yararulesproject_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_yararulesproject="${work_dir_yararulesproject%%+(/)}"
fi
if [ -z "$work_dir_add" ] ; then
  work_dir_add="$(echo "${work_dir}/${add_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_add="${work_dir_add%%+(/)}"
fi
if [ -z "$work_dir_work_configs" ] ; then
  work_dir_work_configs="$(echo "${work_dir}/${work_dir_configs}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_work_configs="${work_dir_work_configs%%+(/)}"
fi
if [ -z "${work_dir_gpg}" ] ; then
  work_dir_gpg="$(echo "${work_dir}/${gpg_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_gpg="${work_dir_gpg%%+(/)}"
fi

if [ -z "$work_dir_pid" ] ; then
  work_dir_pid="$(echo "${work_dir}/${pid_dir}" | $sed_bin 's:/*$::')"
else
  shopt -s extglob; work_dir_pid="${work_dir_pid%%+(/)}"
fi

# Assign defaults if not defined
if [ -z "$cron_dir" ] ; then
  cron_dir="/etc/cron.d"
fi
shopt -s extglob; cron_dir="${cron_dir%%+(/)}"
if [ -z "$cron_filename" ] ; then
  cron_filename="clamav-unofficial-sigs"
fi
if [ -z "$logrotate_dir" ] ; then
  logrotate_dir="/etc/logrotate.d"
fi
shopt -s extglob; logrotate_dir="${logrotate_dir%%+(/)}"
if [ -z "$logrotate_filename" ] ; then
  logrotate_filename="clamav-unofficial-sigs"
fi
if [ -z "$man_dir" ] ; then
  man_dir="/usr/share/man/man8"
fi
shopt -s extglob; man_dir="${man_dir%%+(/)}"
if [ -z "$man_filename" ] ; then
  man_filename="clamav-unofficial-sigs.8"
fi
if [ -z "$man_log_file_full_path" ] ; then
  man_log_file_full_path="${log_file_path}/${log_file_name}"
fi
# dont assign , but remove trailing /
shopt -s extglob; clam_dbs="${clam_dbs%%+(/)}"

#####################################################################################################
# Assign and Check Binaries/Commands
# clamscan_bin
if [ -z "$clamscan_bin" ] && [ "${1}" != "--remove-script" ] ; then
    clamscan_bin="$(command -v clamscan 2> /dev/null)"
    if [ -z "$clamscan_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: clamscan binary (clamscan_bin) not found"
        exit 1
    fi
elif [[ "$clamscan_bin" =~ "/" ]] && [ "${1}" != "--remove-script" ] ; then
    if [ ! -x "$clamscan_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: clamscan_bin (${clamscan_bin})is not executable"
        exit 1

    fi
fi
# uname_bin
if [ -z "$uname_bin" ] ; then
    uname_bin="$(command -v uname 2> /dev/null)"
    if [ -z "$uname_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: uname binary (uname_bin) not found"
        exit 1
    fi
elif [[ "$uname_bin" =~ "/" ]] ; then
    if [ ! -x "$uname_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: uname_bin (${uname_bin}) is not executable"
        exit 1

    fi
fi
# rsync_bin
if [ -z "$rsync_bin" ] ; then
    rsync_bin="$(command -v rsync 2> /dev/null)"
    if [ -z "$rsync_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: rsync binary (rsync_bin) not found"
        exit 1
    fi
elif [[ "$rsync_bin" =~ "/" ]] ; then
    if [ ! -x "$rsync_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: rsync_bin (${rsync_bin}) is not executable"
        exit 1

    fi
fi
# tar_bin
if [ -z "$tar_bin" ] ; then
    tar_bin="$(command -v tar 2> /dev/null)"
    if [ -z "$tar_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: tar binary (tar_bin) not found"
        exit 1
    fi
elif [[ "$tar_bin" =~ "/" ]] ; then
    if [ ! -x "$tar_bin" ] ; then
        xshok_pretty_echo_and_log "ERROR: tar_bin (${tar_bin}) is not executable"
        exit 1
    fi
fi

# gpg_bin
if [ "$enable_gpg" == "yes" ] ; then
    if [ -z "$gpg_bin" ] ; then
        if [ -x "/opt/csw/bin/gpg" ] ; then
            gpg_bin="/opt/csw/bin/gpg"
        else
            gpg_bin="$(command -v gpg 2> /dev/null)"
            if [ -z "$gpg_bin" ] ; then
                enable_gpg="no"
            fi
        fi
    elif [[ "$gpg_bin" =~ "/" ]] ; then
        if [ ! -x "$gpg_bin" ] ; then
            enable_gpg="no"
        fi
    fi
fi
# curl_bin
if [ -z "$curl_bin" ] ; then
    curl_bin="$(command -v curl 2> /dev/null)"
elif [[ "$curl_bin" =~ "/" ]] ; then
    if [ ! -x "$curl_bin" ] ; then
        curl_bin=""
    fi
fi
# wget_bin
if [ -z "$curl_bin" ] || [ "$force_wget" == "yes" ] ; then
    if [ -z "$wget_bin" ] ; then
        if [ -x /usr/sfw/bin/wget ] ; then
            wget_bin="/usr/sfw/bin/wget"
        else
            wget_bin="$(command -v wget 2> /dev/null)"
            if [ -z "$wget_bin" ] ; then
                xshok_pretty_echo_and_log "ERROR: both wget (wget_bin) and curl (curl_bin) commands are missing, One of them is required"
                exit 1
            fi
        fi
    elif [[ "$wget_bin" =~ "/" ]] ; then
        if [ ! -x "$wget_bin" ] ; then
            xshok_pretty_echo_and_log "ERROR: wget_bin (${wget_bin}) is not executable"
            exit 1

        fi
    fi
    if [ -n "$wget_bin" ] ; then
        # wget compression support
        if $wget_bin --help 2> /dev/null | $grep_bin -q "compression=TYPE" 2> /dev/null ; then
            wget_compression="--compression=auto"
        else
            wget_compression=""
        fi
    fi
else
    wget_bin=""
    wget_compression=""
    force_wget="no"
fi


# dig_bin
if [ -z "$dig_bin" ] ; then
    dig_bin="$(command -v dig 2> /dev/null)"
elif [[ "$dig_bin" =~ "/" ]] ; then
    if [ ! -x "$dig_bin" ] ; then
        dig_bin=""
    fi
fi
# host_bin
if [ -z "$dig_bin" ] || [ "$force_host" == "yes" ] ; then
    if [ -z "$host_bin" ] ; then
        host_bin="$(command -v host 2> /dev/null)"
        if [ -z "$host_bin" ] ; then
            xshok_pretty_echo_and_log "ERROR: both host (host_bin) and dig (dig_bin) commands are missing, One of them is required"
            exit 1
        fi
    elif [[ "$host_bin" =~ "/" ]] ; then
        if [ ! -x "$host_bin" ] ; then
            xshok_pretty_echo_and_log "ERROR: host_bin (${host_bin}) is not executable"
            exit 1

        fi
    fi
else
    host_bin=""
    force_host="no"
fi



#####################################################################################################


# SANITY checks
# Check default Binaries & Commands are defined
if [ "$reload_dbs" == "yes" ] ; then
    if [ -z "$clamd_reload_opt" ] ; then
        xshok_pretty_echo_and_log "ERROR: Missing clamd_reload_opt"
        exit 1
    fi
fi
if [ "$enable_gpg" != "yes" ] ; then
  xshok_pretty_echo_and_log "NOTICE: GnuPG / signature verification disabled"
fi
# Check default directories are defined
if [ -z "$work_dir" ] ; then
  xshok_pretty_echo_and_log "ERROR: working directory (work_dir) not defined"
  exit 1
fi
if [ -z "$clam_dbs" ] ; then
  xshok_pretty_echo_and_log "ERROR: clam database directory (clam_dbs) not defined"
  exit 1
fi
# Check default directories are writable
if [ -e "$work_dir" ] ; then
  if [ ! -w "$work_dir" ] ; then
    xshok_pretty_echo_and_log "ERROR: working directory (work_dir) not writable ${work_dir}"
    exit 1
  fi
fi
if [ ! -w "$clam_dbs" ] ; then
  xshok_pretty_echo_and_log "ERROR: clam database directory (clam_dbs) not writable ${clam_dbs}"
  exit 1
fi

# Reset the update timers to force a full update.
if [ "$force_updates" == "yes" ] ; then
  xshok_pretty_echo_and_log "NOTICE: forcing updates"
  sanesecurity_update_hours="0"
  securiteinfo_update_hours="0"
  securiteinfo_premium_update_hours="0"
  linuxmalwaredetect_update_hours="0"
  interserver_update_hours="0"
  malwareexpert_update_hours="0"
  malwarepatrol_update_hours="0"
  yararulesproject_update_hours="0"
  additional_update_hours="0"
fi

# Enable pid file to prevent issues with multiple instances
# opted not to use flock as it appears to have issues with some systems
if [ "$enable_locking" == "yes" ] ; then
  xshok_mkdir_ownership "$work_dir_pid"
  pid_file_fullpath="$work_dir_pid/clamav-unofficial-sigs.pid"
  if [ -f "$pid_file_fullpath" ] ; then
    pid_file_pid="$(cat "$pid_file_fullpath")"
    if ps -p "$pid_file_pid" > /dev/null 2>&1 ; then
      xshok_pretty_echo_and_log "ERROR: Only one instance can run at the same time."
      exit 1
    else
      xshok_create_pid_file "$pid_file_fullpath"
    fi
    else
        xshok_create_pid_file "$pid_file_fullpath"
    fi
  # Run this wehen the script exits
  trap -- "rm -f $pid_file_fullpath" EXIT
fi

# Verify the clam_user and clam_group actually exists on the system
if ! xshok_user_group_exists "${clam_user}" "${clam_group}" ; then
  xshok_pretty_echo_and_log "ERROR: Either the user: ${clam_user} and/or group: ${clam_group} does not exist on the system."
  exit 1
fi

# If the local rsync client supports the "--no-motd" flag, then enable it.
if $rsync_bin --help | $grep_bin -q "no-motd" > /dev/null ; then
  no_motd="--no-motd"
fi

# If the local rsync client supports the "--contimeout" flag, then enable it.
if $rsync_bin --help | $grep_bin -q "contimeout" > /dev/null ; then
  connect_timeout="--contimeout=${rsync_connect_timeout}"
fi

if [ "$debug" == "yes" ] ; then
     downloader_debug="yes"
     clamscan_debug="yes"
     curl_debug="yes"
     wget_debug="yes"
     rsync_debug="yes"
fi
# Show clamscan errors
if [ "$clamscan_debug" == "yes" ] ; then
    exec 10>&2
else
    exec 10>/dev/null
fi
# Show curl errors
if [ "$curl_debug" == "yes" ] ; then
    exec 11>&2
else
    exec 11>/dev/null
fi
# Show wget errors
if [ "$wget_debug" == "yes" ] ; then
    exec 12>&2
else
    exec 12>/dev/null
fi
# Show rsync errors
if [ "$rsync_debug" == "yes" ] ; then
    exec 13>&2
else
    exec 13>/dev/null
fi

# Silence wget output and only report errors - useful if script is run via cron.
if [ "$downloader_silence" == "yes" ] && [ "$downloader_debug" != "yes" ]  ; then
  wget_output_level="--quiet"
  curl_output_level="--silent --show-error"
else
  wget_output_level="--no-verbose"
  curl_output_level=""
fi

# Silence rsync output and only report errors - useful if script is run via cron.
if [ "$rsync_silence" == "yes" ] && [ "$rsync_debug" != "yes" ] ; then
  rsync_output_level="--quiet"
else
  rsync_output_level="--progress"
fi

# Suppress ssl warnings
if [ "$downloader_ignore_ssl_errors" == "yes" ] ; then
  wget_insecure="--no-check-certificate"
  curl_insecure="--insecure"
else
  wget_insecure=""
  curl_insecure=""
fi

# Set the script to 755 permissions
if xshok_is_root ; then
  if [ "$setmode" == "yes" ] ; then
    if [ ! -x "${this_script_path}/${this_script_name}" ] ; then
      chmod 755 "${this_script_path}/${this_script_name}"
      xshok_pretty_echo_and_log "Fixing permission on ${this_script_path}/${this_script_name}" "="
    fi
  fi
else
  # Disable setmode
  setmode="no"
fi
################################################################################
# MAIN LOGIC
################################################################################

while true; do
  case "${1}" in
    -d|--decode-sig) decode_third_party_signature_by_signature_name; exit ;;
    -e|--encode-string) hexadecimal_encode_entire_input_string; exit ;;
    -f|--encode-formatted) hexadecimal_encode_formatted_input_string; exit ;;
    -g|--gpg-verify) xshok_check_s2 "${2}"; gpg_verify_specific_sanesecurity_database_file "${2}"; exit ;;
    -i|--information) output_system_configuration_information; exit ;;
    -m|--make-database) make_signature_database_from_ascii_file; exit ;;
    -t|--test-database) xshok_check_s2 "${2}"; clamscan_integrity_test_specific_database_file "${2}"; exit ;;
    -o|--output-triggered) output_signatures_triggered_during_ham_directory_scan; exit ;;
    -w|--whitelist) add_signature_whitelist_entry "${2}"; exit ;;
    --check-clamav) check_clamav; exit ;;
    --upgrade) xshok_upgrade; exit ;;
    --install-all) install_cron; install_logrotate; install_man; exit ;;
    --install-cron) install_cron; exit ;;
    --install-logrotate) install_logrotate; exit ;;
    --install-man) install_man; exit ;;
    --remove-script) remove_script; exit ;;
    *) break ;;
  esac
done

xshok_pretty_echo_and_log "Preparing Databases" "="

if [ "$default_dbs_rating" == "DISABLE" ] ; then
    if [ "$sanesecurity_dbs_rating" != "LOW" ] && [ "$sanesecurity_dbs_rating" != "MEDIUM" ] && [ "$sanesecurity_dbs_rating" != "HIGH" ]; then
        sanesecurity_enabled="no"
    fi
    if [ "$linuxmalwaredetect_dbs_rating" != "LOW" ] && [ "$linuxmalwaredetect_dbs_rating" != "MEDIUM" ] && [ "$linuxmalwaredetect_dbs_rating" != "HIGH" ]; then
        linuxmalwaredetect_enabled="no"
    fi
    if [ "$interserver_dbs_rating" != "LOW" ] && [ "$interserver_dbs_rating" != "MEDIUM" ] && [ "$interserver_dbs_rating" != "HIGH" ]; then
        interserver_enabled="no"
    fi
    if [ "$malwareexpert_dbs_rating" != "LOW" ] && [ "$malwareexpert_dbs_rating" != "MEDIUM" ] && [ "$malwareexpert_dbs_rating" != "HIGH" ]; then
        malwareexpert_enabled="no"
    fi
    if [ "$securiteinfo_dbs_rating" != "LOW" ] && [ "$securiteinfo_dbs_rating" != "MEDIUM" ] && [ "$securiteinfo_dbs_rating" != "HIGH" ]; then
        securiteinfo_enabled="no"
    fi
    if [ "$urlhaus_dbs_rating" != "LOW" ] && [ "$urlhaus_dbs_rating" != "MEDIUM" ] && [ "$urlhaus_dbs_rating" != "HIGH" ]; then
        urlhaus_enabled="no"
    fi
    if [ "$yararulesproject_dbs_rating" != "LOW" ] && [ "$yararulesproject_dbs_rating" != "MEDIUM" ] && [ "$yararulesproject_dbs_rating" != "HIGH" ]; then
        yararulesproject_enabled="no"
    fi
else
    if [ "$sanesecurity_dbs_rating" == "DISABLE" ] ; then
        sanesecurity_enabled="no"
    fi
    if [ "$linuxmalwaredetect_dbs_rating" == "DISABLE" ] ; then
        linuxmalwaredetect_enabled="no"
    fi
    if [ "$interserver_dbs_rating" == "DISABLE" ] ; then
        interserver_enabled="no"
    fi
    if [ "$malwareexpert_dbs_rating" == "DISABLE" ] ; then
        malwareexpert_enabled="no"
    fi
    if [ "$securiteinfo_dbs_rating" == "DISABLE" ] ; then
        securiteinfo_enabled="no"
    fi
    if [ "$urlhaus_dbs_rating" == "DISABLE" ] ; then
        urlhaus_enabled="no"
    fi
    if [ "$yararulesproject_dbs_rating" == "DISABLE" ] ; then
        yararulesproject_enabled="no"
    fi
fi

# Check yararule support is available
if [ "$enable_yararules" == "yes" ] ; then
  current_clamav_version="$($clamscan_bin -V | cut -d " " -f 2 | cut -d "/" -f 1 | awk -F "." '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }')"
  minimum_yara_clamav_version="$(echo "$minimum_yara_clamav_version" | awk -F "." '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }')"
  # Check current clamav version against the minimum required version for yara support
  if [ "$current_clamav_version" -lt "$minimum_yara_clamav_version" ] ; then # Older
    yararulesproject_enabled="no"
    enable_yararules="no"
    xshok_pretty_echo_and_log "Yararules Disabled due to clamav being older than the minimum required version"
  fi
else
  yararulesproject_enabled="no"
  enable_yararules="no"
fi

############################################################################################
# Generate the signature databases
############################################################################################
if [ "$sanesecurity_enabled" == "yes" ] ; then
  if [ -n "$sanesecurity_dbs" ] ; then
    if [ -n "$sanesecurity_dbs_rating" ] ; then
      temp_db="$(xshok_database "$sanesecurity_dbs_rating" "${sanesecurity_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$sanesecurity_dbs_rating" "${sanesecurity_dbs[@]}")"
      fi
    else
      temp_db="$(xshok_database "$default_dbs_rating" "${sanesecurity_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$default_dbs_rating" "${sanesecurity_dbs[@]}")"
      fi
    fi
    sanesecurity_dbs=( )
    if [ -n "$temp_db" ] ; then
        read -r -a sanesecurity_dbs <<< "$temp_db"
    fi
  fi
elif [ "$remove_disabled_databases" == "yes" ] ; then
    temp_remove_db="$(xshok_remove_database "DISABLED" "${sanesecurity_dbs[@]}")"
fi

sanesecurity_remove_dbs=( )
if [ -n "$temp_remove_db" ] && [ "$remove_disabled_databases" == "yes" ] ; then
    read -r -a sanesecurity_remove_dbs <<< "$temp_remove_db"
fi
############################################################################################
if [ "$securiteinfo_enabled" == "yes" ] ; then
  if [ -n "$securiteinfo_dbs" ] ; then
    if [ -n "$securiteinfo_dbs_rating" ] ; then
      temp_db="$(xshok_database "$securiteinfo_dbs_rating" "${securiteinfo_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$securiteinfo_dbs_rating" "${securiteinfo_dbs[@]}")"
      fi
    else
      temp_db="$(xshok_database "$default_dbs_rating" "${securiteinfo_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$default_dbs_rating" "${securiteinfo_dbs[@]}")"
      fi
    fi
        securiteinfo_dbs=( )
        if [ -n "$temp_db" ] ; then
            read -r -a securiteinfo_dbs <<< "$temp_db"
        fi
  fi
elif [ "$remove_disabled_databases" == "yes" ] ; then
    temp_remove_db="$(xshok_remove_database "DISABLED" "${securiteinfo_dbs[@]}")"
fi
securiteinfo_remove_dbs=( )
if [ -n "$temp_remove_db" ] && [ "$remove_disabled_databases" == "yes" ] ; then
    read -r -a securiteinfo_remove_dbs <<< "$temp_remove_db"
fi
if [ "$securiteinfo_enabled" == "yes" ] ; then
  if [ -n "$securiteinfo_premium_dbs" ] && [ "$securiteinfo_premium" == "yes" ] ; then
    if [ -n "$securiteinfo_dbs_rating" ] ; then
      temp_db="$(xshok_database "$securiteinfo_dbs_rating" "${securiteinfo_premium_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$securiteinfo_dbs_rating" "${securiteinfo_premium_dbs[@]}")"
      fi
    else
      temp_db="$(xshok_database "$default_dbs_rating" "${securiteinfo_premium_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$default_dbs_rating" "${securiteinfo_premium_dbs[@]}")"
      fi
    fi
    if [ -n "$temp_db" ] ; then
        read -r -a securiteinfo_dbs <<< "$temp_db"
    fi
  fi
elif [ "$remove_disabled_databases" == "yes" ] ; then
    temp_remove_db="$(xshok_remove_database "DISABLED" "${securiteinfo_premium_dbs[@]}")"
fi
if [ -n "$temp_remove_db" ] && [ "$remove_disabled_databases" == "yes" ] ; then
    read -r -a securiteinfo_remove_dbs <<< "$temp_remove_db"
fi
############################################################################################
if [ "$linuxmalwaredetect_enabled" == "yes" ] ; then
  if [ -n "$linuxmalwaredetect_dbs" ] ; then
    if [ -n "$linuxmalwaredetect_dbs_rating" ] ; then
      temp_db="$(xshok_database "$linuxmalwaredetect_dbs_rating" "${linuxmalwaredetect_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$linuxmalwaredetect_dbs_rating" "${linuxmalwaredetect_dbs[@]}")"
      fi
    else
      temp_db="$(xshok_database "$default_dbs_rating" "${linuxmalwaredetect_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$default_dbs_rating" "${linuxmalwaredetect_dbs[@]}")"
      fi
    fi
        linuxmalwaredetect_dbs=( )
        if [ -n "$temp_db" ] ; then
            read -r -a linuxmalwaredetect_dbs <<< "$temp_db"
        fi
  fi
elif [ "$remove_disabled_databases" == "yes" ] ; then
  temp_remove_db="$(xshok_remove_database "DISABLED" "${linuxmalwaredetect_dbs[@]}")"
fi
linuxmalwaredetect_remove_dbs=( )
if [ -n "$temp_remove_db" ] && [ "$remove_disabled_databases" == "yes" ] ; then
  read -r -a linuxmalwaredetect_remove_dbs <<< "$temp_remove_db"
fi
############################################################################################
if [ "$interserver_enabled" == "yes" ] ; then
  if [ -n "$interserver_dbs" ] ; then
    if [ -n "$interserver_dbs_rating" ] ; then
      temp_db="$(xshok_database "$interserver_dbs_rating" "${interserver_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$interserver_dbs_rating" "${interserver_dbs[@]}")"
      fi
    else
      temp_db="$(xshok_database "$default_dbs_rating" "${interserver_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$default_dbs_rating" "${interserver_dbs[@]}")"
      fi
    fi
        interserver_dbs=( )
        if [ -n "$temp_db" ] ; then
            read -r -a interserver_dbs <<< "$temp_db"
        fi
  fi
elif [ "$remove_disabled_databases" == "yes" ] ; then
  temp_remove_db="$(xshok_remove_database "DISABLED" "${interserver_dbs[@]}")"
fi
interserver_remove_dbs=( )
if [ -n "$temp_remove_db" ] && [ "$remove_disabled_databases" == "yes" ] ; then
  read -r -a interserver_remove_dbs <<< "$temp_remove_db"
fi
############################################################################################
if [ "$malwareexpert_enabled" == "yes" ] ; then
  if [ -n "$malwareexpert_dbs" ] ; then
    if [ -n "$malwareexpert_dbs_rating" ] ; then
      temp_db="$(xshok_database "$malwareexpert_dbs_rating" "${malwareexpert_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$malwareexpert_dbs_rating" "${malwareexpert_dbs[@]}")"
      fi
    else
      temp_db="$(xshok_database "$default_dbs_rating" "${malwareexpert_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$default_dbs_rating" "${malwareexpert_dbs[@]}")"
      fi
    fi
        malwareexpert_dbs=( )
        if [ -n "$temp_db" ] ; then
            read -r -a malwareexpert_dbs <<< "$temp_db"
        fi
  fi
elif [ "$remove_disabled_databases" == "yes" ] ; then
  temp_remove_db="$(xshok_remove_database "DISABLED" "${malwareexpert_dbs[@]}")"
fi
malwareexpert_remove_dbs=( )
if [ -n "$temp_remove_db" ] && [ "$remove_disabled_databases" == "yes" ] ; then
  read -r -a malwareexpert_remove_dbs <<< "$temp_remove_db"
fi
############################################################################################
if [ "$yararulesproject_enabled" == "yes" ] ; then
  if [ -n "$yararulesproject_dbs" ] ; then
    if [ -n "$yararulesproject_dbs_rating" ] ; then
      temp_db="$(xshok_database "$yararulesproject_dbs_rating" "${yararulesproject_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$yararulesproject_dbs_rating" "${yararulesproject_dbs[@]}")"
      fi
    else
      temp_db="$(xshok_database "$default_dbs_rating" "${yararulesproject_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$default_dbs_rating" "${yararulesproject_dbs[@]}")"
      fi
    fi
    yararulesproject_dbs=( )
        if [ -n "$temp_db" ] ; then
            read -r -a yararulesproject_dbs <<< "$temp_db"
        fi
  fi
elif [ "$remove_disabled_databases" == "yes" ] ; then
  temp_remove_db="$(xshok_remove_database "DISABLED" "${yararulesproject_dbs[@]}")"
fi
yararulesproject_remove_dbs=( )
if [ -n "$temp_remove_db" ] && [ "$remove_disabled_databases" == "yes" ] ; then
  read -r -a yararulesproject_remove_dbs <<< "$temp_remove_db"
fi
############################################################################################
if [ "$urlhaus_enabled" == "yes" ] ; then
  if [ -n "$urlhaus_dbs" ] ; then
    if [ -n "$urlhaus_dbs_rating" ] ; then
      temp_db="$(xshok_database "$urlhaus_dbs_rating" "${urlhaus_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$urlhaus_dbs_rating" "${urlhaus_dbs[@]}")"
      fi
    else
      temp_db="$(xshok_database "$default_dbs_rating" "${urlhaus_dbs[@]}")"
      if [ "$remove_disabled_databases" == "yes" ] ; then
          temp_remove_db="$(xshok_remove_database "$default_dbs_rating" "${urlhaus_dbs[@]}")"
      fi
    fi
    urlhaus_dbs=( )
        if [ -n "$temp_db" ] ; then
        #urlhaus_dbs=( $temp_db )
        read -r -a urlhaus_dbs <<< "$temp_db"
        fi
  fi
elif [ "$remove_disabled_databases" == "yes" ] ; then
  temp_remove_db="$(xshok_remove_database "DISABLED" "${urlhaus_dbs[@]}")"
fi
urlhaus_remove_dbs=( )
if [ -n "$temp_remove_db" ] && [ "$remove_disabled_databases" == "yes" ] ; then
  read -r -a urlhaus_remove_dbs <<< "$temp_remove_db"
fi
############################################################################################
if [ "$malwarepatrol_enabled" == "yes" ] ; then
    # Set the variables for MalwarePatrol
    if [ "$malwarepatrol_product_code" != "8" ] ; then
        # assumption, free product code is always 8 (non-free product code is never 8)
        malwarepatrol_free="no"
    fi
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
    if [ -z "$malwarepatrol_db" ] ; then
        malwarepatrol_db="malwarepatrol.db"
    fi
    malwarepatrol_url="${malwarepatrol_url}?receipt=${malwarepatrol_receipt_code}&product=${malwarepatrol_product_code}&list=${malwarepatrol_list}"
elif [ "$remove_disabled_databases" == "yes" ] ; then
    malwarepatrol_remove_dbs=( "malwarepatrol.db" )
fi
############################################################################################
# CLEANUP UNUSED DATABASES, eg when downgrading a database rating or disabling a database
if [ "$remove_disabled_databases" == "yes" ] ; then
    if [ -n "${sanesecurity_remove_dbs[0]}" ] ; then
      for db_file in "${sanesecurity_remove_dbs[@]}" ; do
        if [ -f "${work_dir_sanesecurity}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${work_dir_sanesecurity}/${db_file}"
            rm -f "${work_dir_sanesecurity}/${db_file}"
        fi
        if [ -f "${clam_dbs}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${clam_dbs}/${db_file}"
            rm -f "${clam_dbs}/${db_file}"
        fi
      done
    fi
    if [ -n "${securiteinfo_remove_dbs[0]}" ] ; then
      for db_file in "${securiteinfo_remove_dbs[@]}" ; do
        if [ -f "${work_dir_securiteinfo}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${work_dir_securiteinfo}/${db_file}"
            rm -f "${work_dir_securiteinfo}/${db_file}"
        fi
        if [ -f "${clam_dbs}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${clam_dbs}/${db_file}"
            rm -f "${clam_dbs}/${db_file}"
        fi
      done
    fi
    if [ -n "${linuxmalwaredetect_remove_dbs[0]}" ] ; then
      for db_file in "${linuxmalwaredetect_remove_dbs[@]}" ; do
        if [ -f "${work_dir_linuxmalwaredetect}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${work_dir_linuxmalwaredetect}/${db_file}"
            rm -f "${work_dir_linuxmalwaredetect}/${db_file}"
        fi
        if [ -f "${clam_dbs}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${clam_dbs}/${db_file}"
            rm -f "${clam_dbs}/${db_file}"
        fi
      done
    fi
    if [ -n "${interserver_remove_dbs[0]}" ] ; then
      for db_file in "${interserver_remove_dbs[@]}" ; do
        if [ -f "${work_dir_interserver}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${work_dir_interserver}/${db_file}"
            rm -f "${work_dir_interserver}/${db_file}"
        fi
        if [ -f "${clam_dbs}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${clam_dbs}/${db_file}"
            rm -f "${clam_dbs}/${db_file}"
        fi
      done
    fi
    if [ -n "${malwareexpert_remove_dbs[0]}" ] ; then
      for db_file in "${malwareexpert_remove_dbs[@]}" ; do
        if [ -f "${work_dir_malwareexpert}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${work_dir_malwareexpert}/${db_file}"
            rm -f "${work_dir_malwareexpert}/${db_file}"
        fi
        if [ -f "${clam_dbs}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${clam_dbs}/${db_file}"
            rm -f "${clam_dbs}/${db_file}"
        fi
      done
    fi
    if [ -n "${yararulesproject_remove_dbs[0]}" ] ; then
      for db_file in "${yararulesproject_remove_dbs[@]}" ; do
          if echo "$db_file" | $grep_bin -q "/" ; then
            yr_dir="/$(echo "$db_file" | cut -d "/" -f 1)"
            db_file="$(echo "$db_file" | cut -d "/" -f 2)"
          else
              yr_dir=""
          fi
        if [ -f "${work_dir_yararulesproject}/${yr_dir}${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${work_dir_yararulesproject}/${db_file}"
            rm -f "${work_dir_yararulesproject}/${db_file}"
        fi
        if [ -f "${clam_dbs}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${clam_dbs}/${db_file}"
            rm -f "${clam_dbs}/${db_file}"
        fi
      done
    fi
    if [ -n "${urlhaus_remove_dbs[0]}" ] ; then
      for db_file in "${urlhaus_remove_dbs[@]}" ; do
        if [ -f "${work_dir_urlhaus}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${work_dir_urlhaus}/${db_file}"
            rm -f "${work_dir_urlhaus}/${db_file}"
        fi
        if [ -f "${clam_dbs}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${clam_dbs}/${db_file}"
            rm -f "${clam_dbs}/${db_file}"
        fi
      done
    fi
    if [ -n "${malwarepatrol_remove_dbs[0]}" ] ; then
      for db_file in "${malwarepatrol_remove_dbs[@]}" ; do
        if [ -f "${work_dir_malwarepatrol}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${work_dir_malwarepatrol}/${db_file}"
            rm -f "${work_dir_malwarepatrol}/${db_file}"
        fi
        if [ -f "${clam_dbs}/${db_file}" ] ; then
            xshok_pretty_echo_and_log "Removing unused file: ${clam_dbs}/${db_file}"
            rm -f "${clam_dbs}/${db_file}"
        fi
      done
    fi
fi

############################################################################################

# If "ham_dir" variable is set, then create initial whitelist files (skipped if first-time script run).
test_dir="$work_dir/test"
if [ -n "$ham_dir" ] && [ -d "$work_dir" ] && [ ! -d "$test_dir" ] ; then
  if [ -d "$ham_dir" ] ; then
    xshok_mkdir_ownership "$test_dir"
    cp -f -p "$work_dir"/*/*.ndb "$test_dir"
    cp -f -p "$work_dir"/*/*.db "$test_dir"
    $clamscan_bin --infected --no-summary -d "$test_dir" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' >> "${work_dir_work_configs}/whitelist.txt"
    $grep_bin -h -f "${work_dir_work_configs}/whitelist.txt" "${test_dir}/*.ndb" | cut -d "*" -f 2 | sort | uniq > "${work_dir_work_configs}/whitelist.hex"
    $grep_bin -h -f "${work_dir_work_configs}/whitelist.txt" "${test_dir}/*.db" | cut -d "=" -f 2 | awk '{ printf("=%s\n", $1);}' | sort | uniq >> "${work_dir_work_configs}/whitelist.hex"
    cd "$test_dir" || exit
    for db_file in * ; do
      [[ -e ${db_file} ]] || break # Handle the case of no files
      $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "$db_file" > "$db_file-tmp"
      mv -f "$db_file-tmp" "$db_file"
      if $clamscan_bin --quiet -d "$db_file" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
        if $rsync_bin -pcqt "$db_file" "$clam_dbs" ; then
          perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
          if [ "$selinux_fixes" == "yes" ] ; then
            restorecon "${clam_dbs}/${db_file}"
          fi
          do_clamd_reload=1
        fi
      fi
    done
    if [ -r "${work_dir_work_configs}/whitelist.hex" ] ; then
      xshok_pretty_echo_and_log "Initial HAM directory scan whitelist file created in ${work_dir_work_configs}"
    else
      xshok_pretty_echo_and_log "No false-positives detected in initial HAM directory scan"
    fi
  else
    xshok_pretty_echo_and_log "WARNING: Cannot locate HAM directory: ${ham_dir}"
    xshok_pretty_echo_and_log "Skipping initial whitelist file creation. Fix 'ham_dir' path in config file"
  fi
fi

# Check to see if the working directories have been created. If not, create them.  Otherwise, ignore and proceed with script.
xshok_mkdir_ownership "$work_dir"
xshok_mkdir_ownership "$work_dir_gpg"
xshok_mkdir_ownership "$work_dir_add"
xshok_mkdir_ownership "$work_dir_pid"
xshok_mkdir_ownership "$work_dir_interserver"
xshok_mkdir_ownership "$work_dir_linuxmalwaredetect"
xshok_mkdir_ownership "$work_dir_malwareexpert"
xshok_mkdir_ownership "$work_dir_malwarepatrol"
xshok_mkdir_ownership "$work_dir_sanesecurity"
xshok_mkdir_ownership "$work_dir_securiteinfo"
xshok_mkdir_ownership "$work_dir_work_configs"
xshok_mkdir_ownership "$work_dir_yararulesproject"

# Set secured access permissions to the GPG directory
perms chmod -f 0700 "${work_dir_gpg}"

if [ "$enable_gpg" == "yes" ] ; then
  # If we haven't done so yet, download Sanesecurity public GPG key and import to custom keyring.
  if [ ! -s "${work_dir_gpg}/publickey.gpg" ] ; then
    xshok_file_download "${work_dir_gpg}/publickey.gpg" "$sanesecurity_gpg_url"
    ret="$?"
    if [ "$ret" -ne 0 ] ; then
      xshok_pretty_echo_and_log "ALERT: Could not download Sanesecurity public GPG key"
      exit 1
    else
      xshok_pretty_echo_and_log "Sanesecurity public GPG key successfully downloaded"
      rm -f -- "${work_dir_gpg}/ss-keyring.gp*"
      if ! $gpg_bin -q --no-options --no-default-keyring --homedir "${work_dir_gpg}" --keyring "${work_dir_gpg}/ss-keyring.gpg" --import "${work_dir_gpg}/publickey.gpg" 2>/dev/null ; then
        xshok_pretty_echo_and_log "ALERT: could not import Sanesecurity public GPG key to custom keyring"
        exit 1
      else
        chmod -f 0644 "${work_dir_gpg}/*.*"
        xshok_pretty_echo_and_log "Sanesecurity public GPG key successfully imported to custom keyring"
      fi
    fi
  fi
  # If custom keyring is missing, try to re-import Sanesecurity public GPG key.
  if [ ! -s "${work_dir_gpg}/ss-keyring.gpg" ] ; then
    rm -f -- "${work_dir_gpg}/ss-keyring.gp*"
    if ! $gpg_bin -q --no-options --no-default-keyring --homedir "${work_dir_gpg}" --keyring "${work_dir_gpg}/ss-keyring.gpg" --import "${work_dir_gpg}/publickey.gpg" 2>/dev/null ; then
      xshok_pretty_echo_and_log "ALERT: Custom keyring MISSING or CORRUPT!  Could not import Sanesecurity public GPG key to custom keyring"
      exit 1
    else
      chmod -f 0644 "${work_dir_gpg}/*.*"
      xshok_pretty_echo_and_log "Sanesecurity custom keyring MISSING!  GPG key successfully re-imported to custom keyring"
    fi
  fi
fi

# Database update check, time randomization section.  This script now
# provides support for both bash and non-bash enabled system shells.
if [ "$enable_random" == "yes" ] ; then
  if [ -n "$RANDOM" ] ; then
    sleep_time="$((RANDOM * $((max_sleep_time - min_sleep_time)) / 32767 + min_sleep_time))"
  else
    sleep_time="0"
    while [ "$sleep_time" -lt "$min_sleep_time" ] || [ "$sleep_time" -gt "$max_sleep_time" ] ; do
      sleep_time="$(head -n 1 /dev/urandom | cksum | awk '{print $2}')"
    done
  fi
  if [ ! -t 0 ] ; then
    xshok_pretty_echo_and_log "$(date) - Pausing database file updates for $sleep_time seconds..."
    sleep "$sleep_time"
    xshok_pretty_echo_and_log "$(date) - Pause complete, checking for new database files..."
  fi
fi

# Create "scan-test.txt" file for clamscan database integrity testing.
if [ ! -s "${work_dir_work_configs}/scan-test.txt" ] ; then
  echo "This is the clamscan test file..." > "${work_dir_work_configs}/scan-test.txt"
fi

if [ -z "$git_branch" ] ; then
    git_branch="master"
fi

# If rsync proxy is defined in the config file, then export it for use.
if [ -n "$rsync_proxy" ] ; then
  RSYNC_PROXY="$rsync_proxy"
  export RSYNC_PROXY
fi

# If rsync connect program is defined in the config file, then export it for use. (to use netcat for socks tunnel)
if [ -n "$rsync_connect_prog" ] ; then
  RSYNC_CONNECT_PROG="$rsync_connect_prog"
  export RSYNC_CONNECT_PROG
fi

# Create $current_dbsfiles containing lists of current and previously active 3rd-party databases
# so that databases and/or backup files that are no longer being used can be removed.
current_tmp="${work_dir_work_configs}/current-dbs.tmp"

current_dbs_file="${work_dir_work_configs}/current-dbs.txt"

if [ "$sanesecurity_enabled" == "yes" ] ; then
  # Create the Sanesecurity rsync "include" file (defines command -v files to download).
  sanesecurity_include_dbs="${work_dir_work_configs}/ss-include-dbs.txt"
  if [ -n "${sanesecurity_dbs[0]}" ] ; then
    rm -f -- "${sanesecurity_include_dbs}" "${work_dir_sanesecurity}/*.sha256"
    for db_file in "${sanesecurity_dbs[@]}" ; do
      echo "$db_file" >> "${sanesecurity_include_dbs}"
      echo "${db_file}.sig" >> "${sanesecurity_include_dbs}"
      echo "${work_dir_sanesecurity}/${db_file}" >> "${current_tmp}"
      echo "${work_dir_sanesecurity}/${db_file}.sig" >> "${current_tmp}"
      clamav_files
    done
  fi
fi
if [ "$securiteinfo_enabled" == "yes" ] ; then
  if [ -n "${securiteinfo_dbs[0]}" ] ; then
    for db in "${securiteinfo_dbs[@]}" ; do
      echo "${work_dir_securiteinfo}/${db}" >> "${current_tmp}"
      clamav_files
    done
  fi
fi
if [ "$linuxmalwaredetect_enabled" == "yes" ] ; then
  if [ -n "${linuxmalwaredetect_dbs[0]}" ] ; then
    for db in "${linuxmalwaredetect_dbs[@]}" ; do
      echo "${work_dir_linuxmalwaredetect}/${db}" >> "${current_tmp}"
      clamav_files
    done
  fi
fi
if [ "$interserver_enabled" == "yes" ] ; then
  if [ -n "${interserver_dbs[0]}" ] ; then
    for db in "${interserver_dbs[@]}" ; do
      echo "${work_dir_interserver}/${db}" >> "${current_tmp}"
      clamav_files
    done
  fi
fi
if [ "$malwareexpert_enabled" == "yes" ] ; then
  if [ -n "${malwareexpert_dbs[0]}" ] ; then
    for db in "${malwareexpert_dbs[@]}" ; do
      echo "${work_dir_malwareexpert}/${db}" >> "${current_tmp}"
      clamav_files
    done
  fi
fi
if [ "$malwarepatrol_enabled" == "yes" ] ; then
  if [ -n "$malwarepatrol_db" ] ; then
    echo "${work_dir_malwarepatrol}/${malwarepatrol_db}" >> "${current_tmp}"
    clamav_files
  fi
fi
if [ "$yararulesproject_enabled" == "yes" ] ; then
  if [ -n "${yararulesproject_dbs[0]}" ] ; then
    for db in "${yararulesproject_dbs[@]}" ; do
      if echo "$db" | $grep_bin -q "/" ; then
        db="$(echo "$db" | cut -d "/" -f 2)"
      fi
      echo "${work_dir_yararulesproject}/${db}" >> "${current_tmp}"
      clamav_files
    done
  fi
fi
if [ "$additional_enabled" == "yes" ] ; then
  if [ -n "$additional_dbs" ] ; then
    for db in "${additional_dbs[@]}" ; do
      echo "${work_dir_add}/${db}" >> "${current_tmp}"
      clamav_files
    done
  fi
fi
sort "${current_tmp}" > "$current_dbs_file" 2>/dev/null
rm -f "${current_tmp}"

# Remove 3rd-party databases and/or backup files that are no longer being used.
if [ "$remove_disabled_databases" == "yes" ] ; then
  previous_dbs="${work_dir_work_configs}/previous-dbs.txt"
  sort "$current_dbs_file" > "$previous_dbs" 2>/dev/null
  # Do not remove the current_dbs_file
  #rm -f "$current_dbs_file"

  db_changes="${work_dir_work_configs}/db-changes.txt"
  if [ ! -s "$previous_dbs" ] ; then
    cp -f -p "$current_dbs_file" "$previous_dbs" 2>/dev/null
  fi
  diff "$current_dbs_file" "$previous_dbs" 2>/dev/null | $grep_bin ">" | awk '{print $2}' > "$db_changes"
  if [ -r "$db_changes" ] ; then
    if $grep_bin -vq "bak" "$db_changes" 2>/dev/null ; then
      do_clamd_reload="2"
    fi
    while read -r file ; do
      rm -f -- "$file"
      xshok_pretty_echo_and_log "Unused/Disabled file removed: ${file}"
    done < "$db_changes"
  fi
fi

# Create "purge.txt" file for package maintainers to support package uninstall.
purge="${work_dir_work_configs}/purge.txt"
cp -f -p "$current_dbs_file" "$purge"
{
  echo "${work_dir_work_configs}/current-dbs.txt"
  echo "${work_dir_work_configs}/db-changes.txt"
  echo "${work_dir_work_configs}/last-mbl-update.txt"
  echo "${work_dir_work_configs}/last-si-update.txt"
  echo "${work_dir_work_configs}/local.ign"
  echo "${work_dir_work_configs}/monitor-ign.txt"
  echo "${work_dir_work_configs}/my-whitelist.ign2"
  echo "${work_dir_work_configs}/tracker.txt"
  echo "${work_dir_work_configs}/previous-dbs.txt"
  echo "${work_dir_work_configs}/scan-test.txt"
  echo "${work_dir_work_configs}/ss-include-dbs.txt"
  echo "${work_dir_work_configs}/whitelist.hex"
  echo "${work_dir_gpg}/publickey.gpg"
  echo "$work_dir_gpg/secring.gpg"
  echo "${work_dir_gpg}/ss-keyring.gpg*"
  echo "$work_dir_gpg/trustdb.gpg"
  echo "${log_file_path}/${log_file_name}*"
  echo "${work_dir_work_configs}/purge.txt"
} >> "$purge"

# Check and save current system time since epoch for time related database downloads.
# However, if unsuccessful, issue a warning that we cannot calculate times since epoch.
if [ -n "${securiteinfo_dbs[0]}" ] || [ -n "$malwarepatrol_db" ] ; then
  current_time="$(date "+%s" 2> /dev/null)"
  current_time="${current_time//[^0-9]/}"
  current_time="$((current_time + 0))"
  if [ "$current_time" -le 0 ] ; then
    current_time="$(perl -le print+time 2> /dev/null)"
  fi
  if [ "$current_time" -le 0 ] ; then
    xshok_pretty_echo_and_log "WARNING: No support for 'date +%s' or 'perl' was not found , SecuriteInfo and MalwarePatrol updates bypassed"
    securiteinfo_dbs=()
    malwarepatrol_db=()
  fi
fi
################################################################
# Check for Sanesecurity database & GPG signature file updates #
################################################################
if [ "$sanesecurity_enabled" == "yes" ] ; then
  if [ -n "${sanesecurity_dbs[0]}" ] ; then
    if [ ${#sanesecurity_dbs} -lt 1 ] ; then
      xshok_pretty_echo_and_log "Failed sanesecurity_dbs config is invalid or not defined - SKIPPING"
    else
      if [ -r "${work_dir_work_configs}/last-ss-update.txt" ] ; then
        last_sanesecurity_update="$(cat "${work_dir_work_configs}/last-ss-update.txt")"
      else
        last_sanesecurity_update="0"
      fi
      db_file=""
      update_interval="$((sanesecurity_update_hours * 3600))"
      time_interval="$((current_time - last_sanesecurity_update))"
      if [ "$time_interval" -ge $((update_interval - 600)) ] ; then
        echo "$current_time" > "${work_dir_work_configs}/last-ss-update.txt"
        xshok_pretty_echo_and_log "Sanesecurity Database & GPG Signature File Updates" "="
        xshok_pretty_echo_and_log "Checking for Sanesecurity updates..."
        if [ -n "$dig_bin" ] ; then
            # shellcheck disable=SC2086
            sanesecurity_mirror_ips="$($dig_bin $dig_proxy +ignore +short "$sanesecurity_url")"
        else
            # shellcheck disable=SC2086
            sanesecurity_mirror_ips="$($host_bin $host_proxy -t A "$sanesecurity_url" | $sed_bin -n '/has address/{s/.*address \([^ ]*\).*/\1/;p;}')"
        fi
        # Add fallback if no records are returned
        if [ ${#sanesecurity_mirror_ips} -lt 1 ] ; then
            if [ -n "$dig_bin" ] ; then
                # shellcheck disable=SC2086
                sanesecurity_mirror_ips="$($dig_bin $dig_proxy +ignore +short "$sanesecurity_url")"
            else
                # shellcheck disable=SC2086
                sanesecurity_mirror_ips="$($host_bin $host_proxy -t A "$sanesecurity_url" | $sed_bin -n '/has address/{s/.*address \([^ ]*\).*/\1/;p;}')"
            fi
        fi

        if [ ${#sanesecurity_mirror_ips} -ge 1 ] ; then
          for sanesecurity_mirror_ip in $sanesecurity_mirror_ips ; do
            if [ -n "$dig_bin" ] ; then
                # shellcheck disable=SC2086
                sanesecurity_mirror_name="$($dig_bin $dig_proxy +short -x "$sanesecurity_mirror_ip" | command "$sed_bin" 's/\.$//')"
            else
                # shellcheck disable=SC2086
                sanesecurity_mirror_name="$($host_bin $host_proxy -t A "$sanesecurity_mirror_ip" | $sed_bin -n '/name pointer/{s/.*pointer \([^ ]*\).*\.$/\1/;p;}')"
            fi
            # Add fallback if no records are returned
            if [ -z "$sanesecurity_mirror_name" ] ; then
                if [ -n "$dig_bin" ] ; then
                    # shellcheck disable=SC2086
                    sanesecurity_mirror_name="$($dig_bin $dig_proxy +short -x "$sanesecurity_mirror_ip" | command "$sed_bin" 's/\.$//')"
                else
                    # shellcheck disable=SC2086
                    sanesecurity_mirror_name="$($host_bin $host_proxy -t A "$sanesecurity_mirror_ip" | $sed_bin -n '/name pointer/{s/.*pointer \([^ ]*\).*\.$/\1/;p;}')"
                fi
            fi
            sanesecurity_mirror_site_info="$sanesecurity_mirror_name $sanesecurity_mirror_ip"
            xshok_pretty_echo_and_log "Sanesecurity mirror site used: ${sanesecurity_mirror_site_info}"
            # shellcheck disable=SC2086
            $rsync_bin $rsync_output_level $no_motd --files-from="${sanesecurity_include_dbs}" -ctuz $connect_timeout --timeout="$rsync_max_time" "rsync://${sanesecurity_mirror_ip}/sanesecurity" "$work_dir_sanesecurity" 2>&13
            ret="$?"
            if [ "$ret" -eq 0 ] || [ "$ret" -eq 23 ] ; then # The correct way, 23 is some files were not transfered, can be ignored and we can assume a success
              sanesecurity_rsync_success="1"
              for db_file in "${sanesecurity_dbs[@]}" ; do
                if ! cmp -s "${work_dir_sanesecurity}/${db_file}" "${clam_dbs}/${db_file}" ; then
                  xshok_pretty_echo_and_log "Testing updated Sanesecurity database file: ${db_file}"

                  if [ "$enable_gpg" == "yes" ] ; then
                    if ! $gpg_bin --trust-model always -q --no-default-keyring --homedir "${work_dir_gpg}" --keyring "${work_dir_gpg}/ss-keyring.gpg" --verify "${work_dir_sanesecurity}/${db_file}.sig" "${work_dir_sanesecurity}/${db_file}" 2>/dev/null ; then
                      $gpg_bin --always-trust -q --no-default-keyring --homedir "${work_dir_gpg}" --keyring "${work_dir_gpg}/ss-keyring.gpg" --verify "${work_dir_sanesecurity}/${db_file}.sig" "${work_dir_sanesecurity}/${db_file}" 2>/dev/null
                      ret="$?"
                    else
                      ret="0"
                    fi
                    if [ "$ret" -eq 0 ] ; then
                      test "$gpg_silence" = "no" && xshok_pretty_echo_and_log "Sanesecurity GPG Signature tested good on ${db_file} database"
                    else
                      xshok_pretty_echo_and_log "Sanesecurity GPG Signature test FAILED on ${db_file} database - SKIPPING"
                    fi
                  fi
                  if [ "$ret" -eq 0 ] ; then
                    db_ext="${db_file#*.}"
                    if [ -z "$ham_dir" ] || [ "$db_ext" != "ndb" ] ; then
                      if $clamscan_bin --quiet -d "${work_dir_sanesecurity}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                        xshok_pretty_echo_and_log "Clamscan reports Sanesecurity ${db_file} database integrity tested good"
                        true
                      else
                        xshok_pretty_echo_and_log "Clamscan reports Sanesecurity ${db_file} database integrity tested BAD"
                        if [ "$remove_bad_database" == "yes" ] ; then
                          if rm -f "${work_dir_sanesecurity}/${db_file}" ; then
                            xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_sanesecurity}/${db_file}"
                          fi
                        fi
                        false
                        fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${work_dir_sanesecurity}/${db_file}" "$clam_dbs" 2>&13 ; then
                        perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                        if [ "$selinux_fixes" == "yes" ] ; then
                          restorecon "${clam_dbs}/${db_file}"
                        fi

                        xshok_pretty_echo_and_log "Successfully updated Sanesecurity production database file: ${db_file}"
                        sanesecurity_update=1
                        do_clamd_reload=1
                      else
                        xshok_pretty_echo_and_log "Failed to successfully update Sanesecurity production database file: ${db_file} - SKIPPING"
                        false
                      fi
                    else
                      $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${work_dir_sanesecurity}/${db_file}" > "${test_dir}/${db_file}"
                      $clamscan_bin --infected --no-summary -d "${test_dir}/${db_file}" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "${work_dir_work_configs}/whitelist.txt"
                      $grep_bin -h -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" | cut -d "*" -f 2 | sort | uniq >> "${work_dir_work_configs}/whitelist.hex-tmp"
                      mv -f "${work_dir_work_configs}/whitelist.hex-tmp" "${work_dir_work_configs}/whitelist.hex"
                      $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" > "${test_dir}/${db_file}-tmp"
                      mv -f "${test_dir}/${db_file}-tmp" "${test_dir}/${db_file}"
                      if $clamscan_bin --quiet -d "${test_dir}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                        xshok_pretty_echo_and_log "Clamscan reports Sanesecurity ${db_file} database integrity tested good"
                        true
                      else
                        xshok_pretty_echo_and_log "Clamscan reports Sanesecurity ${db_file} database integrity tested BAD"
                        # DO NOT KILL THIS DB
                        false
                        fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${test_dir}/${db_file}" "$clam_dbs" 2>&13 ; then
                        perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                        if [ "$selinux_fixes" == "yes" ] ; then
                          restorecon "${clam_dbs}/${db_file}"
                        fi
                        xshok_pretty_echo_and_log "Successfully updated Sanesecurity production database file: ${db_file}"
                        sanesecurity_update=1
                        do_clamd_reload=1
                      else
                        xshok_pretty_echo_and_log "Failed to successfully update Sanesecurity production database file: ${db_file} - SKIPPING"
                      fi
                    fi
                  fi
                fi
              done
              if [ ! "$sanesecurity_update" == "1" ] ; then
                xshok_pretty_echo_and_log "No Sanesecurity database file updates" "-"
                break
              else
                break
              fi
            else
              xshok_pretty_echo_and_log "Connection to ${sanesecurity_mirror_site_info} failed - Trying next mirror site..."
            fi
          done
          if [ ! "$sanesecurity_rsync_success" == "1" ] ; then
            xshok_pretty_echo_and_log "Access to all Sanesecurity mirror sites failed - Check for connectivity issues"
            xshok_pretty_echo_and_log "or signature database name(s) misspelled in the script's configuration file."
          fi
        else
          xshok_pretty_echo_and_log "No Sanesecurity mirror sites found - Check for dns/connectivity issues"
        fi
      else
        xshok_pretty_echo_and_log "Sanesecurity Database File Updates" "="
        xshok_draw_time_remaining "$((update_interval - time_interval))" "$sanesecurity_update_hours" "Sanesecurity"
      fi
    fi
  fi
else
  if [ -n "${sanesecurity_dbs[0]}" ] ; then
    if [ "$remove_disabled_databases" == "yes" ] ; then
      xshok_pretty_echo_and_log "Removing disabled Sanesecurity Database files"
      for db_file in "${sanesecurity_dbs[@]}" ; do
        if echo "$db_file" | $grep_bin -q "|" ; then
          db_file="${db_file%|*}"
        fi
        if [ -r "${work_dir_sanesecurity}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${work_dir_sanesecurity}/${db_file}"
          rm -f "${work_dir_sanesecurity}/${db_file}"
          do_clamd_reload=1
        fi
        if [ -r "${clam_dbs}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${clam_dbs}/${db_file}"
          rm -f "${clam_dbs}/${db_file}"
          do_clamd_reload=1
        fi
      done
    fi
  fi
fi

##############################################################################################################################################
# Check for updated SecuriteInfo database files every set number of hours as defined in the "USER CONFIGURATION" section of this script      #
##############################################################################################################################################
if [ "$securiteinfo_enabled" == "yes" ] ; then
  if [ "$securiteinfo_authorisation_signature" != "YOUR-SIGNATURE-NUMBER" ] ; then
    if [ -n "${securiteinfo_dbs[0]}" ] ; then
      if [ ${#securiteinfo_dbs} -lt 1 ] ; then
        xshok_pretty_echo_and_log "Failed securiteinfo_dbs config is invalid or not defined - SKIPPING"
      else
        rm -f "${work_dir_securiteinfo}/*.gz"
        if [ -r "${work_dir_work_configs}/last-si-update.txt" ] ; then
          last_securiteinfo_update="$(cat "${work_dir_work_configs}/last-si-update.txt")"
        else
          last_securiteinfo_update="0"
        fi
        db_file=""
        loop=""
        if [ "$securiteinfo_premium" == "yes" ] ; then
            update_interval="$((securiteinfo_premium_update_hours * 3600))"
        else
            update_interval="$((securiteinfo_update_hours * 3600))"
        fi
        time_interval="$((current_time - last_securiteinfo_update))"
        if [ "$time_interval" -ge "$((update_interval - 600))" ] ; then
          echo "$current_time" > "${work_dir_work_configs}/last-si-update.txt"
          xshok_pretty_echo_and_log "SecuriteInfo Database File Updates" "="
          xshok_pretty_echo_and_log "Checking for SecuriteInfo updates..."
          securiteinfo_updates="0"
          for db_file in "${securiteinfo_dbs[@]}" ; do
            if [ "$loop" == "1" ] ; then
              xshok_pretty_echo_and_log "---"
            fi
            xshok_pretty_echo_and_log "Checking for updated SecuriteInfo database file: ${db_file}"
            securiteinfo_db_update="0"
            xshok_file_download "${work_dir_securiteinfo}/${db_file}" "${securiteinfo_url}/${securiteinfo_authorisation_signature}/${db_file}"
            ret="$?"
            if [ "$ret" -eq 0 ] ; then
              loop="1"
              if ! cmp -s "${work_dir_securiteinfo}/${db_file}" "${clam_dbs}/${db_file}" ; then
                db_ext="${db_file#*.}"

                xshok_pretty_echo_and_log "Testing updated SecuriteInfo database file: ${db_file}"
                if [ -z "$ham_dir" ] || [ "$db_ext" != "ndb" ] ; then
                  if $clamscan_bin --quiet -d "${work_dir_securiteinfo}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo ${db_file} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo ${db_file} database integrity tested BAD"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_securiteinfo}/${db_file}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_securiteinfo}/${db_file}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${work_dir_securiteinfo}/${db_file}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/${db_file}"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated SecuriteInfo production database file: ${db_file}"
                    securiteinfo_updates=1
                    securiteinfo_db_update=1
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update SecuriteInfo production database file: ${db_file} - SKIPPING"
                  fi
                else
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${work_dir_securiteinfo}/${db_file}" > "${test_dir}/${db_file}"
                  $clamscan_bin --infected --no-summary -d "${test_dir}/${db_file}" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "${work_dir_work_configs}/whitelist.txt"
                  $grep_bin -h -f "${work_dir_work_configs}/whitelist.txt" "${test_dir}/${db_file}" | cut -d "*" -f 2 | sort | uniq >> "${work_dir_work_configs}/whitelist.hex"
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" > "${test_dir}/${db_file}-tmp"
                  mv -f "${test_dir}/${db_file}-tmp" "${test_dir}/${db_file}"
                  if $clamscan_bin --quiet -d "${test_dir}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo ${db_file} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports SecuriteInfo ${db_file} database integrity tested BAD"
                    rm -f "${work_dir_securiteinfo}/${db_file}"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_securiteinfo}/${db_file}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_securiteinfo}/${db_file}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${test_dir}/${db_file}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/${db_file}"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated SecuriteInfo production database file: ${db_file}"
                    securiteinfo_updates=1
                    securiteinfo_db_update=1
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update SecuriteInfo production database file: ${db_file} - SKIPPING"
                  fi
                fi
              fi
            else
              xshok_pretty_echo_and_log "Failed connection to ${securiteinfo_url} - SKIPPED SecuriteInfo ${db_file} update"
            fi
            if [ "$securiteinfo_db_update" != "1" ] ; then
              xshok_pretty_echo_and_log "No updated SecuriteInfo ${db_file} database file" "-"
            fi
          done
          if [ "$securiteinfo_updates" != "1" ] ; then
            xshok_pretty_echo_and_log "No SecuriteInfo database file updates" "-"
          fi
        else
          xshok_pretty_echo_and_log "SecuriteInfo Database File Updates" "="
          if [ "$securiteinfo_premium" == "yes" ] ; then
              xshok_draw_time_remaining "$((update_interval - time_interval))" "$securiteinfo_premium_update_hours" "SecuriteInfo"
          else
              xshok_draw_time_remaining "$((update_interval - time_interval))" "$securiteinfo_update_hours" "SecuriteInfo"
          fi
        fi
      fi
    fi
  fi
else
  if [ -n "$securiteinfo_dbs" ] ; then
    if [ "$remove_disabled_databases" == "yes" ] ; then
      xshok_pretty_echo_and_log "Removing disabled SecuriteInfo Database files"
      for db_file in "${securiteinfo_dbs[@]}" ; do
        if echo "$db_file" | $grep_bin -q "|" ; then
          db_file="${db_file%|*}"
        fi
        if [ -r "${work_dir_securiteinfo}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${work_dir_securiteinfo}/${db_file}"
          rm -f "${work_dir_securiteinfo}/${db_file}"
          do_clamd_reload=1
        fi
        if [ -r "${clam_dbs}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${clam_dbs}/${db_file}"
          rm -f "${clam_dbs}/${db_file}"
          do_clamd_reload=1
        fi
      done
    fi
  fi
fi

##############################################################################################################################################
# Check for updated LinuxMalwareDetect database files every set number of hours as defined in the "USER CONFIGURATION" section of this script
##############################################################################################################################################
if [ "$linuxmalwaredetect_enabled" == "yes" ] ; then
  if [ -n "${linuxmalwaredetect_dbs[0]}" ] ; then
    if [ ${#linuxmalwaredetect_dbs} -lt 1 ] ; then
      xshok_pretty_echo_and_log "Failed linuxmalwaredetect_dbs config is invalid or not defined - SKIPPING"
    else
      rm -f "${work_dir_linuxmalwaredetect}/*.gz"
      if [ -r "${work_dir_work_configs}/last-linuxmalwaredetect-update.txt" ] ; then
        last_linuxmalwaredetect_update="$(cat "${work_dir_work_configs}/last-linuxmalwaredetect-update.txt")"
      else
        last_linuxmalwaredetect_update="0"
      fi
      db_file=""
      loop=""
      update_interval="$((linuxmalwaredetect_update_hours * 3600))"
      time_interval="$((current_time - last_linuxmalwaredetect_update))"
      if [ "$time_interval" -ge "$((update_interval - 600))" ] ; then
        echo "$current_time" > "${work_dir_work_configs}/last-linuxmalwaredetect-update.txt"

        xshok_pretty_echo_and_log "LinuxMalwareDetect Database File Updates" "="
        xshok_pretty_echo_and_log "Checking for LinuxMalwareDetect updates..."

        # Check for a new version
        found_upgrade="no"
        if [ -n "$curl_bin" ] ; then
          # shellcheck disable=SC2086
          latest_linuxmalwaredetect_version="$($curl_bin --compressed $curl_proxy $curl_insecure $curl_output_level --connect-timeout "${downloader_connect_timeout}" --remote-time --location --retry "${downloader_tries}" --max-time "${downloader_max_time}" "$linuxmalwaredetect_version_url" 2>&11 | head -n1 | xargs)"
        else
          # shellcheck disable=SC2086
          latest_linuxmalwaredetect_version="$($wget_bin $wget_compression $wget_proxy $wget_insecure $wget_output_level --connect-timeout="${downloader_connect_timeout}" --random-wait --tries="${downloader_tries}" --timeout="${downloader_max_time}" "$linuxmalwaredetect_version_url" -O - 2>&12 | $grep_bin "^script_version=" | head -n1 | xargs)"
        fi

        if [ "$latest_linuxmalwaredetect_version" ] ; then
          # shellcheck disable=SC2183,SC2086
          if [ -f "${work_dir_linuxmalwaredetect}/current_linuxmalwaredetect_version" ] ; then
            current_linuxmalwaredetect_version="$(head -n1 "${work_dir_linuxmalwaredetect}/current_linuxmalwaredetect_version" | xargs)"
          else
            current_linuxmalwaredetect_version="-1"
          fi
          if [ "$latest_linuxmalwaredetect_version" != "$current_linuxmalwaredetect_version" ] ; then
            xshok_pretty_echo_and_log "LinuxMalwareDetect Database File Updates" "="
            found_upgrade="yes"
          fi
        fi

        if [ "$found_upgrade" == "yes" ] ; then
          mkdir -p "${work_dir_linuxmalwaredetect}/tmp/"
          xshok_file_download "${work_dir_linuxmalwaredetect}/tmp/sigpack.tgz" "${linuxmalwaredetect_sigpack_url}"
          ret="$?"
          if [ "$ret" -eq 0 ] ; then
            mkdir -p "${work_dir_linuxmalwaredetect}/tmp/"
            $tar_bin --strip-components=1 -xzf "${work_dir_linuxmalwaredetect}/tmp/sigpack.tgz" --directory "${work_dir_linuxmalwaredetect}/tmp/"
            #ls -l "${work_dir_linuxmalwaredetect}/tmp/"
            if [ "$enable_yararules" == "yes" ] ; then
                find "${work_dir_linuxmalwaredetect}/tmp/" -type f -iname "rfxn.*" -exec mv -f '{}' "${work_dir_linuxmalwaredetect}/" \;
            else
                find "${work_dir_linuxmalwaredetect}/tmp/" -type f -iname "rfxn.*" ! \( -iname "*.yara" -o -iname "*.yar" \) -exec mv -f '{}' "${work_dir_linuxmalwaredetect}/" \;
            fi
            # cleanup
            rm -rf -- "${work_dir_linuxmalwaredetect:?}/tmp"
            #ls -l "${work_dir_linuxmalwaredetect}/"

            for db_file in "${linuxmalwaredetect_dbs[@]}" ; do
              if [ "$loop" == "1" ] ; then
                xshok_pretty_echo_and_log "---"
              fi
              loop="1"
              if ! cmp -s "${work_dir_linuxmalwaredetect}/${db_file}" "${clam_dbs}/${db_file}" ; then
                db_ext="${db_file#*.}"

                xshok_pretty_echo_and_log "Testing updated LinuxMalwareDetect database file: ${db_file}"
                if [ -z "$ham_dir" ] || [ "$db_ext" != "ndb" ] ; then
                  if $clamscan_bin --quiet -d "${work_dir_linuxmalwaredetect}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports LinuxMalwareDetect ${db_file} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports LinuxMalwareDetect ${db_file} database integrity tested BAD"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_linuxmalwaredetect}/${db_file}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_linuxmalwaredetect}/${db_file}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${work_dir_linuxmalwaredetect}/${db_file}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/local.ign"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated LinuxMalwareDetect production database file: ${db_file}"
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update LinuxMalwareDetect production database file: ${db_file} - SKIPPING"
                  fi
                else
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${work_dir_linuxmalwaredetect}/${db_file}" > "${test_dir}/${db_file}"
                  $clamscan_bin --infected --no-summary -d "${test_dir}/${db_file}" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "${work_dir_work_configs}/whitelist.txt"
                  $grep_bin -h -f "${work_dir_work_configs}/whitelist.txt" "${test_dir}/${db_file}" | cut -d "*" -f 2 | sort | uniq >> "${work_dir_work_configs}/whitelist.hex"
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" > "${test_dir}/${db_file}-tmp"
                  mv -f "${test_dir}/${db_file}-tmp" "${test_dir}/${db_file}"
                  if $clamscan_bin --quiet -d "${test_dir}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports LinuxMalwareDetect ${db_file} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports LinuxMalwareDetect ${db_file} database integrity tested BAD"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_linuxmalwaredetect}/${db_file}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_linuxmalwaredetect}/${db_file}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${test_dir}/${db_file}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/${db_file}"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated LinuxMalwareDetect production database file: ${db_file}"
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update LinuxMalwareDetect production database file: ${db_file} - SKIPPING"
                  fi
                fi
              fi

            done
            #save the current version
            echo "$latest_linuxmalwaredetect_version" > "${work_dir_linuxmalwaredetect}/current_linuxmalwaredetect_version"

          else
            xshok_pretty_echo_and_log "WARNING: Failed connection to ${linuxmalwaredetect_sigpack_url} - SKIPPED LinuxMalwareDetect update"
          fi
        else
          xshok_pretty_echo_and_log "No LinuxMalwareDetect database file updates" "-"
        fi
      else
        xshok_pretty_echo_and_log "LinuxMalwareDetect Database File Updates" "="
        xshok_draw_time_remaining "$((update_interval - time_interval))" "$linuxmalwaredetect_update_hours" "linuxmalwaredetect"
      fi
    fi
  fi
else
  if [ -n "${linuxmalwaredetect_dbs[0]}" ] ; then
    if [ "$remove_disabled_databases" == "yes" ] ; then
      xshok_pretty_echo_and_log "Removing disabled LinuxMalwareDetect Database files"

      if [ -f "${work_dir_linuxmalwaredetect}/current_linuxmalwaredetect_version" ] ; then
        rm -f "${work_dir_linuxmalwaredetect}/current_linuxmalwaredetect_version"
      fi
      for db_file in "${linuxmalwaredetect_dbs[@]}" ; do
        if echo "$db_file" | $grep_bin -q "|" ; then
          db_file="${db_file%|*}"
        fi
        if [ -r "${work_dir_linuxmalwaredetect}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${work_dir_linuxmalwaredetect}/${db_file}"
          rm -f "${work_dir_linuxmalwaredetect}/${db_file}"
          do_clamd_reload=1
        fi
        if [ -r "${clam_dbs}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${clam_dbs}/${db_file}"
          rm -f "${clam_dbs}/${db_file}"
          do_clamd_reload=1
        fi
      done
    fi
  fi
fi
##############################################################################################################################################
# Check for updated interServer database files every set number of hours as defined in the "USER CONFIGURATION" section of this script      #
##############################################################################################################################################
if [ "$interserver_enabled" == "yes" ] ; then
     if [ -n "${interserver_dbs[0]}" ] ; then
      if [ ${#interserver_dbs} -lt 1 ] ; then
        xshok_pretty_echo_and_log "Failed interserver_dbs config is invalid or not defined - SKIPPING"
      else
        rm -f "${work_dir_interserver}/*.gz"
        if [ -r "${work_dir_work_configs}/last-is-update.txt" ] ; then
          last_interserver_update="$(cat "${work_dir_work_configs}/last-is-update.txt")"
        else
          last_interserver_update="0"
        fi
        db_file=""
        loop=""
        if [ "$interserver_premium" == "yes" ] ; then
            update_interval="$((interserver_premium_update_hours * 3600))"
        else
            update_interval="$((interserver_update_hours * 3600))"
        fi
        time_interval="$((current_time - last_interserver_update))"
        if [ "$time_interval" -ge "$((update_interval - 600))" ] ; then
          echo "$current_time" > "${work_dir_work_configs}/last-is-update.txt"
          xshok_pretty_echo_and_log "interserver Database File Updates" "="
          xshok_pretty_echo_and_log "Checking for interserver updates..."
          interserver_updates="0"
          for db_file in "${interserver_dbs[@]}" ; do
            if [ "$loop" == "1" ] ; then
              xshok_pretty_echo_and_log "---"
            fi
            xshok_pretty_echo_and_log "Checking for updated interServer database file: ${db_file}"
            interserver_db_update="0"
            xshok_file_download "${work_dir_interserver}/${db_file}" "${interserver_url}/${db_file}"
            ret="$?"
            if [ "$ret" -eq 0 ] ; then
              loop="1"
              if ! cmp -s "${work_dir_interserver}/${db_file}" "${clam_dbs}/${db_file}" ; then
                db_ext="${db_file#*.}"

                xshok_pretty_echo_and_log "Testing updated interServer database file: ${db_file}"
                if [ -z "$ham_dir" ] || [ "$db_ext" != "ndb" ] ; then
                  if $clamscan_bin --quiet -d "${work_dir_interserver}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports interServer ${db_file} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports interServer ${db_file} database integrity tested BAD"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_interserver}/${db_file}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_interserver}/${db_file}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${work_dir_interserver}/${db_file}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/${db_file}"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated interServer production database file: ${db_file}"
                    interserver_updates=1
                    interserver_db_update=1
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update interServer production database file: ${db_file} - SKIPPING"
                  fi
                else
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${work_dir_interserver}/${db_file}" > "${test_dir}/${db_file}"
                  $clamscan_bin --infected --no-summary -d "${test_dir}/${db_file}" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "${work_dir_work_configs}/whitelist.txt"
                  $grep_bin -h -f "${work_dir_work_configs}/whitelist.txt" "${test_dir}/${db_file}" | cut -d "*" -f 2 | sort | uniq >> "${work_dir_work_configs}/whitelist.hex"
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" > "${test_dir}/${db_file}-tmp"
                  mv -f "${test_dir}/${db_file}-tmp" "${test_dir}/${db_file}"
                  if $clamscan_bin --quiet -d "${test_dir}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports interServer ${db_file} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports interServer ${db_file} database integrity tested BAD"
                    rm -f "${work_dir_interserver}/${db_file}"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_interserver}/${db_file}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_interserver}/${db_file}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${test_dir}/${db_file}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/${db_file}"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated interServer production database file: ${db_file}"
                    interserver_updates=1
                    interserver_db_update=1
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update interServer production database file: ${db_file} - SKIPPING"
                  fi
                fi
              fi
            else
              xshok_pretty_echo_and_log "Failed connection to ${interserver_url} - SKIPPED interServer ${db_file} update"
            fi
            if [ "$interserver_db_update" != "1" ] ; then
              xshok_pretty_echo_and_log "No updated interServer ${db_file} database file" "-"
            fi
          done
          if [ "$interserver_updates" != "1" ] ; then
            xshok_pretty_echo_and_log "No interServer database file updates" "-"
          fi
        else
          xshok_pretty_echo_and_log "interServer Database File Updates" "="
          if [ "$interserver_premium" == "yes" ] ; then
              xshok_draw_time_remaining "$((update_interval - time_interval))" "$interserver_premium_update_hours" "interserver"
          else
              xshok_draw_time_remaining "$((update_interval - time_interval))" "$interserver_update_hours" "interserver"
          fi
        fi
      fi
    fi
else
  if [ -n "$interserver_dbs" ] ; then
    if [ "$remove_disabled_databases" == "yes" ] ; then
      xshok_pretty_echo_and_log "Removing disabled interServer Database files"
      for db_file in "${interserver_dbs[@]}" ; do
        if echo "$db_file" | $grep_bin -q "|" ; then
          db_file="${db_file%|*}"
        fi
        if [ -r "${work_dir_interserver}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${work_dir_interserver}/${db_file}"
          rm -f "${work_dir_interserver}/${db_file}"
          do_clamd_reload=1
        fi
        if [ -r "${clam_dbs}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${clam_dbs}/${db_file}"
          rm -f "${clam_dbs}/${db_file}"
          do_clamd_reload=1
        fi
      done
    fi
  fi
fi

##############################################################################################################################################
# Check for updated Malware Expert database files every set number of hours as defined in the "USER CONFIGURATION" section of this script      #
##############################################################################################################################################
if [ "$malwareexpert_enabled" == "yes" ] ; then
  if [ "$malwareexpert_serial_key" != "YOUR-SERIAL-KEY" ] && [ -n "$malwareexpert_serial_key" ]; then
    if [ -n "${malwareexpert_dbs[0]}" ] ; then
      if [ ${#malwareexpert_dbs} -lt 1 ] ; then
        xshok_pretty_echo_and_log "Failed malwareexpert_dbs config is invalid or not defined - SKIPPING"
      else
        rm -f "${work_dir_malwareexpert}/*.gz"
        if [ -r "${work_dir_work_configs}/last-me-update.txt" ] ; then
          last_malwareexpert_update="$(cat "${work_dir_work_configs}/last-me-update.txt")"
        else
          last_malwareexpert_update="0"
        fi
        db_file=""
        loop=""
        if [ "$malwareexpert_premium" == "yes" ] ; then
            update_interval="$((malwareexpert_premium_update_hours * 3600))"
        else
            update_interval="$((malwareexpert_update_hours * 3600))"
        fi
        time_interval="$((current_time - last_malwareexpert_update))"
        if [ "$time_interval" -ge "$((update_interval - 600))" ] ; then
          echo "$current_time" > "${work_dir_work_configs}/last-me-update.txt"
          xshok_pretty_echo_and_log "malwareexpert Database File Updates" "="
          xshok_pretty_echo_and_log "Checking for malwareexpert updates..."
          malwareexpert_updates="0"
          for db_file in "${malwareexpert_dbs[@]}" ; do
            if [ "$loop" == "1" ] ; then
              xshok_pretty_echo_and_log "---"
            fi
            xshok_pretty_echo_and_log "Checking for updated Malware Expert database file: ${db_file}"
            malwareexpert_db_update="0"
            xshok_file_download "${work_dir_malwareexpert}/${db_file}" "${malwareexpert_url}/${malwareexpert_serial_key}/${db_file}"
            ret="$?"
            if [ "$ret" -eq 0 ] ; then
              loop="1"
              if ! cmp -s "${work_dir_malwareexpert}/${db_file}" "${clam_dbs}/${db_file}" ; then
                db_ext="${db_file#*.}"

                xshok_pretty_echo_and_log "Testing updated Malware Expert database file: ${db_file}"
                if [ -z "$ham_dir" ] || [ "$db_ext" != "ndb" ] ; then
                  if $clamscan_bin --quiet -d "${work_dir_malwareexpert}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports Malware Expert ${db_file} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports Malware Expert ${db_file} database integrity tested BAD"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_malwareexpert}/${db_file}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_malwareexpert}/${db_file}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${work_dir_malwareexpert}/${db_file}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/${db_file}"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated Malware Expert production database file: ${db_file}"
                    malwareexpert_updates=1
                    malwareexpert_db_update=1
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update Malware Expert production database file: ${db_file} - SKIPPING"
                  fi
                else
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${work_dir_malwareexpert}/${db_file}" > "${test_dir}/${db_file}"
                  $clamscan_bin --infected --no-summary -d "${test_dir}/${db_file}" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "${work_dir_work_configs}/whitelist.txt"
                  $grep_bin -h -f "${work_dir_work_configs}/whitelist.txt" "${test_dir}/${db_file}" | cut -d "*" -f 2 | sort | uniq >> "${work_dir_work_configs}/whitelist.hex"
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" > "${test_dir}/${db_file}-tmp"
                  mv -f "${test_dir}/${db_file}-tmp" "${test_dir}/${db_file}"
                  if $clamscan_bin --quiet -d "${test_dir}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports Malware Expert ${db_file} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports Malware Expert ${db_file} database integrity tested BAD"
                    rm -f "${work_dir_malwareexpert}/${db_file}"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_malwareexpert}/${db_file}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_malwareexpert}/${db_file}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${test_dir}/${db_file}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/${db_file}"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated Malware Expert production database file: ${db_file}"
                    malwareexpert_updates=1
                    malwareexpert_db_update=1
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update Malware Expert production database file: ${db_file} - SKIPPING"
                  fi
                fi
              fi
            else
              xshok_pretty_echo_and_log "Failed connection to ${malwareexpert_url} - SKIPPED Malware Expert ${db_file} update"
            fi
            if [ "$malwareexpert_db_update" != "1" ] ; then
              xshok_pretty_echo_and_log "No updated Malware Expert ${db_file} database file" "-"
            fi
          done
          if [ "$malwareexpert_updates" != "1" ] ; then
            xshok_pretty_echo_and_log "No Malware Expert database file updates" "-"
          fi
        else
          xshok_pretty_echo_and_log "Malware Expert Database File Updates" "="
          if [ "$malwareexpert_premium" == "yes" ] ; then
              xshok_draw_time_remaining "$((update_interval - time_interval))" "$malwareexpert_premium_update_hours" "malwareexpert"
          else
              xshok_draw_time_remaining "$((update_interval - time_interval))" "$malwareexpert_update_hours" "malwareexpert"
          fi
        fi
      fi
    fi
  fi
else
  if [ -n "$malwareexpert_dbs" ] ; then
    if [ "$remove_disabled_databases" == "yes" ] ; then
      xshok_pretty_echo_and_log "Removing disabled Malware Expert Database files"
      for db_file in "${malwareexpert_dbs[@]}" ; do
        if echo "$db_file" | $grep_bin -q "|" ; then
          db_file="${db_file%|*}"
        fi
        if [ -r "${work_dir_malwareexpert}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${work_dir_malwareexpert}/${db_file}"
          rm -f "${work_dir_malwareexpert}/${db_file}"
          do_clamd_reload=1
        fi
        if [ -r "${clam_dbs}/${db_file}" ] ; then
          xshok_pretty_echo_and_log "Removing ${clam_dbs}/${db_file}"
          rm -f "${clam_dbs}/${db_file}"
          do_clamd_reload=1
        fi
      done
    fi
  fi
fi

#########################################################################################################################################
# Download MalwarePatrol database file every set number of hours as defined in the "USER CONFIGURATION" section of this script.          #
##########################################################################################################################################
if [ "$malwarepatrol_enabled" == "yes" ] ; then
  if [ "$malwarepatrol_receipt_code" != "YOUR-RECEIPT-NUMBER" ] ; then
    if [ -n "${malwarepatrol_db}" ] ; then
        rm -f "${work_dir_malwarepatrol}/*.gz"
        if [ -r "${work_dir_work_configs}/last-mbl-update.txt" ] ; then
          last_malwarepatrol_update="$(cat "${work_dir_work_configs}/last-mbl-update.txt")"
        else
          last_malwarepatrol_update="0"
        fi
        loop=""
        update_interval="$((malwarepatrol_update_hours * 3600))"
        time_interval="$((current_time - last_malwarepatrol_update))"
        if [ "$time_interval" -ge "$((update_interval - 600))" ] ; then
          echo "$current_time" > "${work_dir_work_configs}/last-mbl-update.txt"
          xshok_pretty_echo_and_log "MalwarePatrol Database File Updates" "="
          xshok_pretty_echo_and_log "Checking for MalwarePatrol updates..."
          malwarepatrol_updates="0"

          # Cleanup any not required database files
          if [ "$malwarepatrol_db" != "malwarepatrol.db" ] && [ -f "${clam_dbs}/malwarepatrol.db" ] ; then
            rm -f "${clam_dbs}/malwarepatrol.db";
          fi
          if [ "$malwarepatrol_db" != "malwarepatrol.ndb" ] && [ -f "${clam_dbs}/malwarepatrol.ndb" ] ; then
            rm -f "${clam_dbs}/malwarepatrol.ndb";
          fi

            if [ "$loop" == "1" ] ; then
              xshok_pretty_echo_and_log "---"
            fi
            xshok_pretty_echo_and_log "Checking for updated MalwarePatrol database file: ${malwarepatrol_db}"
            malwarepatrol_db_update="0"

            xshok_file_download "${work_dir_malwarepatrol}/${malwarepatrol_db}" "${malwarepatrol_url}"

            ret="$?"
            if [ "$ret" -eq 0 ] ; then
              loop="1"
              if ! cmp -s "${work_dir_malwarepatrol}/${malwarepatrol_db}" "${clam_dbs}/${malwarepatrol_db}" ; then
                db_ext="${malwarepatrol_db#*.}"

                xshok_pretty_echo_and_log "Testing updated MalwarePatrol database file: ${malwarepatrol_db}"
                if [ -z "$ham_dir" ] || [ "$db_ext" != "ndb" ] ; then
                  if $clamscan_bin --quiet -d "${work_dir_malwarepatrol}/${malwarepatrol_db}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol ${malwarepatrol_db} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol ${malwarepatrol_db} database integrity tested BAD"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_malwarepatrol}/${malwarepatrol_db}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_malwarepatrol}/${malwarepatrol_db}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${malwarepatrol_db}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${work_dir_malwarepatrol}/${malwarepatrol_db}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${malwarepatrol_db}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/${malwarepatrol_db}"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated MalwarePatrol production database file: ${malwarepatrol_db}"
                    malwarepatrol_updates=1
                    malwarepatrol_db_update=1
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update MalwarePatrol production database file: ${malwarepatrol_db} - SKIPPING"
                  fi
                else
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${work_dir_malwarepatrol}/${malwarepatrol_db}" > "${test_dir}/${malwarepatrol_db}"
                  $clamscan_bin --infected --no-summary -d "${test_dir}/${malwarepatrol_db}" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "${work_dir_work_configs}/whitelist.txt"
                  $grep_bin -h -f "${work_dir_work_configs}/whitelist.txt" "${test_dir}/${malwarepatrol_db}" | cut -d "*" -f 2 | sort | uniq >> "${work_dir_work_configs}/whitelist.hex"
                  $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${malwarepatrol_db}" > "${test_dir}/${malwarepatrol_db}-tmp"
                  mv -f "${test_dir}/${malwarepatrol_db}-tmp" "${test_dir}/${malwarepatrol_db}"
                  if $clamscan_bin --quiet -d "${test_dir}/${malwarepatrol_db}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                    xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol ${malwarepatrol_db} database integrity tested good"
                    true
                  else
                    xshok_pretty_echo_and_log "Clamscan reports MalwarePatrol ${malwarepatrol_db} database integrity tested BAD"
                    rm -f "${work_dir_malwarepatrol}/${malwarepatrol_db}"
                    if [ "$remove_bad_database" == "yes" ] ; then
                      if rm -f "${work_dir_malwarepatrol}/${malwarepatrol_db}" ; then
                        xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_malwarepatrol}/${malwarepatrol_db}"
                      fi
                    fi
                    false
                    fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${malwarepatrol_db}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${test_dir}/${malwarepatrol_db}" "$clam_dbs" 2>&13 ; then
                    perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${malwarepatrol_db}"
                    if [ "$selinux_fixes" == "yes" ] ; then
                      restorecon "${clam_dbs}/${malwarepatrol_db}"
                    fi
                    xshok_pretty_echo_and_log "Successfully updated MalwarePatrol production database file: ${malwarepatrol_db}"
                    malwarepatrol_updates=1
                    malwarepatrol_db_update=1
                    do_clamd_reload=1
                  else
                    xshok_pretty_echo_and_log "Failed to successfully update MalwarePatrol production database file: ${malwarepatrol_db} - SKIPPING"
                  fi
                fi
              fi
            else
              xshok_pretty_echo_and_log "Failed connection to ${malwarepatrol_url} - SKIPPED MalwarePatrol ${malwarepatrol_db} update"
            fi
            if [ "$malwarepatrol_db_update" != "1" ] ; then
              xshok_pretty_echo_and_log "No updated MalwarePatrol ${malwarepatrol_db} database file" "-"
            fi
          if [ "$malwarepatrol_updates" != "1" ] ; then
            xshok_pretty_echo_and_log "No MalwarePatrol database file updates" "-"
          fi
        else
          xshok_pretty_echo_and_log "MalwarePatrol Database File Updates" "="
          xshok_draw_time_remaining "$((update_interval - time_interval))" "$malwarepatrol_update_hours" "malwarepatrol"
        fi
      fi
    fi
else
  if [ -n "$malwarepatrol_dbs" ] ; then
    if [ "$remove_disabled_databases" == "yes" ] ; then
      xshok_pretty_echo_and_log "Removing disabled MalwarePatrol Database files"
        if [ -r "${work_dir_malwarepatrol}/${malwarepatrol_db}" ] ; then
          xshok_pretty_echo_and_log "Removing ${work_dir_malwarepatrol}/${malwarepatrol_db}"
          rm -f "${work_dir_malwarepatrol}/${malwarepatrol_db}"
          do_clamd_reload=1
        fi
        if [ -r "${clam_dbs}/${malwarepatrol_db}" ] ; then
          xshok_pretty_echo_and_log "Removing ${clam_dbs}/${malwarepatrol_db}"
          rm -f "${clam_dbs}/${malwarepatrol_db}"
          do_clamd_reload=1
        fi
    fi
  fi
fi

##############################################################################################################################################
# Check for updated urlhaus database files every set number of hours as defined in the "USER CONFIGURATION" section of this script
##############################################################################################################################################
if [ "$urlhaus_enabled" == "yes" ] ; then
  if [ -n "${urlhaus_dbs[0]}" ] ; then
    if [ ${#urlhaus_dbs} -lt 1 ] ; then
      xshok_pretty_echo_and_log "Failed urlhaus_dbs config is invalid or not defined - SKIPPING"
    else
      rm -f "${work_dir_urlhaus}/*.gz"
      if [ -r "${work_dir_work_configs}/last-urlhaus-update.txt" ] ; then
        last_urlhaus_update="$(cat "${work_dir_work_configs}/last-urlhaus-update.txt")"
      else
        last_urlhaus_update="0"
      fi
      db_file=""
      loop=""
      update_interval="$((urlhaus_update_hours * 3600))"
      time_interval="$((current_time - last_urlhaus_update))"
      if [ "$time_interval" -ge "$((update_interval - 600))" ] ; then
        echo "$current_time" > "${work_dir_work_configs}/last-urlhaus-update.txt"

        xshok_pretty_echo_and_log "URLhaus Database File Updates" "="
        xshok_pretty_echo_and_log "Checking for urlhaus updates..."
        urlhaus_updates="0"
        for db_file in "${urlhaus_dbs[@]}" ; do
          if echo "$db_file" | $grep_bin -q "/" ; then
            yr_dir="/$(echo "$db_file" | cut -d "/" -f 1)"
            db_file="$(echo "$db_file" | cut -d "/" -f 2)"
          else yr_dir=""
          fi
          if [ "$loop" == "1" ] ; then
            xshok_pretty_echo_and_log "---"
          fi
          xshok_pretty_echo_and_log "Checking for updated urlhaus database file: ${db_file}"
          urlhaus_db_update="0"
          if xshok_file_download "${work_dir_urlhaus}/${db_file}" "${urlhaus_url}/${db_file}" ; then
            loop="1"
            if ! cmp -s "${work_dir_urlhaus}/${db_file}" "${clam_dbs}/${db_file}" ; then
              db_ext="${db_file#*.}"
              xshok_pretty_echo_and_log "Testing updated urlhaus database file: ${db_file}"
              if [ -z "$ham_dir" ] || [ "$db_ext" != "ndb" ] ; then
                if $clamscan_bin --quiet -d "${work_dir_urlhaus}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                  xshok_pretty_echo_and_log "Clamscan reports urlhaus ${db_file} database integrity tested good"
                  true
                else
                  xshok_pretty_echo_and_log "Clamscan reports urlhaus ${db_file} database integrity tested BAD"
                  if [ "$remove_bad_database" == "yes" ] ; then
                    if rm -f "${work_dir_urlhaus}/${db_file}" ; then
                      xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_urlhaus}/${db_file}"
                    fi
                  fi
                  false
                  fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${work_dir_urlhaus}/${db_file}" "$clam_dbs" 2>&13 ; then
                  perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                  if [ "$selinux_fixes" == "yes" ] ; then
                    restorecon "${clam_dbs}/${db_file}"
                  fi
                  xshok_pretty_echo_and_log "Successfully updated urlhaus production database file: ${db_file}"
                  urlhaus_updates=1
                  urlhaus_db_update=1
                  do_clamd_reload=1
                else
                  xshok_pretty_echo_and_log "Failed to successfully update urlhaus production database file: ${db_file} - SKIPPING"
                fi
              else
                $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${work_dir_urlhaus}/${db_file}" > "${test_dir}/${db_file}"
                $clamscan_bin --infected --no-summary -d "${test_dir}/${db_file}" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "${work_dir_work_configs}/whitelist.txt"
                $grep_bin -h -f "${work_dir_work_configs}/whitelist.txt" "${test_dir}/${db_file}" | cut -d "*" -f 2 | sort | uniq >> "${work_dir_work_configs}/whitelist.hex"
                $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" > "${test_dir}/${db_file}-tmp"
                mv -f "${test_dir}/${db_file}-tmp" "${test_dir}/${db_file}"
                if $clamscan_bin --quiet -d "${test_dir}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                  xshok_pretty_echo_and_log "Clamscan reports urlhaus ${db_file} database integrity tested good"
                  true
                else
                  xshok_pretty_echo_and_log "Clamscan reports urlhaus ${db_file} database integrity tested BAD"
                  if [ "$remove_bad_database" == "yes" ] ; then
                    if rm -f "${work_dir_urlhaus}/${db_file}" ; then
                      xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_urlhaus}/${db_file}"
                    fi
                  fi
                  false
                  fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${test_dir}/${db_file}" "$clam_dbs" 2>&13 ; then
                  perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                  if [ "$selinux_fixes" == "yes" ] ; then
                    restorecon "${clam_dbs}/${db_file}"
                  fi
                  xshok_pretty_echo_and_log "Successfully updated urlhaus production database file: ${db_file}"
                  urlhaus_updates=1
                  urlhaus_db_update=1
                  do_clamd_reload=1
                else
                  xshok_pretty_echo_and_log "Failed to successfully update urlhaus production database file: ${db_file} - SKIPPING"
                fi
              fi

            fi
          else
            xshok_pretty_echo_and_log "WARNING: Failed connection to $urlhaus_url - SKIPPED urlhaus ${db_file} update"
          fi
          if [ "$urlhaus_db_update" != "1" ] ; then
            xshok_pretty_echo_and_log "No updated urlhaus ${db_file} database file"
          fi
        done
        if [ "$urlhaus_updates" != "1" ] ; then
          xshok_pretty_echo_and_log "No urlhaus database file updates" "-"
        fi
      else

        xshok_pretty_echo_and_log "URLhaus Database File Updates" "="
        xshok_draw_time_remaining "$((update_interval - time_interval))" "$urlhaus_update_hours" "urlhaus"
      fi
    fi
  fi
else
  if [ -n "${urlhaus_dbs[0]}" ] ; then
    if [ "$remove_disabled_databases" == "yes" ] ; then
      xshok_pretty_echo_and_log "Removing disabled urlhaus Database files"
      for db_file in "${urlhaus_dbs[@]}" ; do
        if echo "$db_file" | $grep_bin -q "/" ; then
          db_file="$(echo "$db_file" | cut -d "/" -f 2)"
        fi
        if echo "$db_file" | $grep_bin -q "|" ; then
          db_file="${db_file%|*}"
        fi
        if [ -r "${work_dir_urlhaus}/${db_file}" ] ; then
          rm -f "${work_dir_urlhaus}/${db_file}"
          do_clamd_reload="1"
        fi
        if [ -r "${clam_dbs}/${db_file}" ] ; then
          rm -f "${clam_dbs}/${db_file}"
          do_clamd_reload=1
        fi
      done
    fi
  fi
fi

##############################################################################################################################################
# Check for updated yararulesproject database files every set number of hours as defined in the "USER CONFIGURATION" section of this script
##############################################################################################################################################
if [ "$yararulesproject_enabled" == "yes" ] ; then
  if [ -n "${yararulesproject_dbs[0]}" ] ; then
    if [ ${#yararulesproject_dbs} -lt 1 ] ; then
      xshok_pretty_echo_and_log "Failed yararulesproject_dbs config is invalid or not defined - SKIPPING"
    else
      rm -f "${work_dir_yararulesproject}/*.gz"
      if [ -r "${work_dir_work_configs}/last-yararulesproject-update.txt" ] ; then
        last_yararulesproject_update="$(cat "${work_dir_work_configs}/last-yararulesproject-update.txt")"
      else
        last_yararulesproject_update="0"
      fi
      db_file=""
      loop=""
      update_interval="$((yararulesproject_update_hours * 3600))"
      time_interval="$((current_time - last_yararulesproject_update))"
      if [ "$time_interval" -ge "$((update_interval - 600))" ] ; then
        echo "$current_time" > "${work_dir_work_configs}/last-yararulesproject-update.txt"

        xshok_pretty_echo_and_log "Yara-Rules Database File Updates" "="
        xshok_pretty_echo_and_log "Checking for yararulesproject updates..."
        yararulesproject_updates="0"
        for db_file in "${yararulesproject_dbs[@]}" ; do
          if echo "$db_file" | $grep_bin -q "/" ; then
            yr_dir="/$(echo "$db_file" | cut -d "/" -f 1)"
            db_file="$(echo "$db_file" | cut -d "/" -f 2)"
          else yr_dir=""
          fi
          if [ "$loop" == "1" ] ; then
            xshok_pretty_echo_and_log "---"
          fi
          xshok_pretty_echo_and_log "Checking for updated yararulesproject database file: ${db_file}"
          yararulesproject_db_update="0"
          if xshok_file_download "${work_dir_yararulesproject}/${db_file}" "$yararulesproject_url/$yr_dir/${db_file}" ; then
            loop="1"
            if ! cmp -s "${work_dir_yararulesproject}/${db_file}" "${clam_dbs}/${db_file}" ; then
              db_ext="${db_file#*.}"
              xshok_pretty_echo_and_log "Testing updated yararulesproject database file: ${db_file}"
              if [ -z "$ham_dir" ] || [ "$db_ext" != "ndb" ] ; then
                if $clamscan_bin --quiet -d "${work_dir_yararulesproject}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                  xshok_pretty_echo_and_log "Clamscan reports yararulesproject ${db_file} database integrity tested good"
                  true
                else
                  xshok_pretty_echo_and_log "Clamscan reports yararulesproject ${db_file} database integrity tested BAD"
                  if [ "$remove_bad_database" == "yes" ] ; then
                    if rm -f "${work_dir_yararulesproject}/${db_file}" ; then
                      xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_yararulesproject}/${db_file}"
                    fi
                  fi
                  false
                  fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${work_dir_yararulesproject}/${db_file}" "$clam_dbs" 2>&13 ; then
                  perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                  if [ "$selinux_fixes" == "yes" ] ; then
                    restorecon "${clam_dbs}/${db_file}"
                  fi
                  xshok_pretty_echo_and_log "Successfully updated yararulesproject production database file: ${db_file}"
                  yararulesproject_updates=1
                  yararulesproject_db_update=1
                  do_clamd_reload=1
                else
                  xshok_pretty_echo_and_log "Failed to successfully update yararulesproject production database file: ${db_file} - SKIPPING"
                fi
              else
                $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${work_dir_yararulesproject}/${db_file}" > "${test_dir}/${db_file}"
                $clamscan_bin --infected --no-summary -d "${test_dir}/${db_file}" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "${work_dir_work_configs}/whitelist.txt"
                $grep_bin -h -f "${work_dir_work_configs}/whitelist.txt" "${test_dir}/${db_file}" | cut -d "*" -f 2 | sort | uniq >> "${work_dir_work_configs}/whitelist.hex"
                $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" > "${test_dir}/${db_file}-tmp"
                mv -f "${test_dir}/${db_file}-tmp" "${test_dir}/${db_file}"
                if $clamscan_bin --quiet -d "${test_dir}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                  xshok_pretty_echo_and_log "Clamscan reports yararulesproject ${db_file} database integrity tested good"
                  true
                else
                  xshok_pretty_echo_and_log "Clamscan reports yararulesproject ${db_file} database integrity tested BAD"
                  if [ "$remove_bad_database" == "yes" ] ; then
                    if rm -f "${work_dir_yararulesproject}/${db_file}" ; then
                      xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_yararulesproject}/${db_file}"
                    fi
                  fi
                  false
                  fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${test_dir}/${db_file}" "$clam_dbs" 2>&13 ; then
                  perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                  if [ "$selinux_fixes" == "yes" ] ; then
                    restorecon "${clam_dbs}/${db_file}"
                  fi
                  xshok_pretty_echo_and_log "Successfully updated yararulesproject production database file: ${db_file}"
                  yararulesproject_updates=1
                  yararulesproject_db_update=1
                  do_clamd_reload=1
                else
                  xshok_pretty_echo_and_log "Failed to successfully update yararulesproject production database file: ${db_file} - SKIPPING"
                fi
              fi

            fi
          else
            xshok_pretty_echo_and_log "WARNING: Failed connection to $yararulesproject_url - SKIPPED yararulesproject ${db_file} update"
          fi
          if [ "$yararulesproject_db_update" != "1" ] ; then
            xshok_pretty_echo_and_log "No updated yararulesproject ${db_file} database file"
          fi
        done
        if [ "$yararulesproject_updates" != "1" ] ; then
          xshok_pretty_echo_and_log "No yararulesproject database file updates" "-"
        fi
      else

        xshok_pretty_echo_and_log "Yara-Rules Database File Updates" "="
        xshok_draw_time_remaining "$((update_interval - time_interval))" "$yararulesproject_update_hours" "yararulesproject"
      fi
    fi
  fi
else
  if [ -n "${yararulesproject_dbs[0]}" ] ; then
    if [ "$remove_disabled_databases" == "yes" ] ; then
      xshok_pretty_echo_and_log "Removing disabled yararulesproject Database files"
      for db_file in "${yararulesproject_dbs[@]}" ; do
        if echo "$db_file" | $grep_bin -q "/" ; then
          db_file="$(echo "$db_file" | cut -d "/" -f 2)"
        fi
        if echo "$db_file" | $grep_bin -q "|" ; then
          db_file="${db_file%|*}"
        fi
        if [ -r "${work_dir_yararulesproject}/${db_file}" ] ; then
          rm -f "${work_dir_yararulesproject}/${db_file}"
          do_clamd_reload="1"
        fi
        if [ -r "${clam_dbs}/${db_file}" ] ; then
          rm -f "${clam_dbs}/${db_file}"
          do_clamd_reload=1
        fi
      done
    fi
  fi
fi

##############################################################################################################################################
# Check for updated additional database files every set number of hours as defined in the "USER CONFIGURATION" section of this script
##############################################################################################################################################
if [ "$additional_enabled" == "yes" ] ; then
  if [ -n "$additional_dbs" ] ; then
    if [ ${#additional_dbs} -lt 1 ] ; then
      xshok_pretty_echo_and_log "Failed additional_dbs config is invalid or not defined - SKIPPING"
    else
      rm -f "${work_dir_add}/*.gz"
      if [ -r "${work_dir_work_configs}/last-additional-update.txt" ] ; then
        last_additional_update="$(cat "${work_dir_work_configs}/last-additional-update.txt")"
      else
        last_additional_update="0"
      fi
      db_file=""
      loop=""
      update_interval="$((additional_update_hours * 3600))"
      time_interval="$((current_time - last_additional_update))"
      if [ "$time_interval" -ge "$((update_interval - 600))" ] ; then
        echo "$current_time" > "${work_dir_work_configs}/last-additional-update.txt"

        xshok_pretty_echo_and_log "Additional Database File Updates" "="
        xshok_pretty_echo_and_log "Checking for additional updates..."
        additional_updates="0"
        for db_url in "${additional_dbs[@]}" ; do
          # Left for future dir manipulation
          # if echo "$db_file" | $grep_bin -q "/" ; then
          #   add_dir="/$(echo "$db_file" | cut -d "/" -f 1)"
          #   db_file="$(echo "$db_file" | cut -d "/" -f 2)"
          # else
          #   add_dir=""
          # fi

          #cleanup any leading and trailing whitespace.
          db_url="$(echo -e "$db_url" | $sed_bin -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

          db_file="$(basename "$db_url")"

          if [ "$loop" == "1" ] ; then
            xshok_pretty_echo_and_log "---"
          fi
          xshok_pretty_echo_and_log "Checking for updated additional database file: ${db_file}"

          additional_db_update="0"

          if [ "${db_url%:*}" == "rsync" ] ; then
            # shellcheck disable=SC2086
            $rsync_bin $rsync_output_level $no_motd -ctuz $connect_timeout --timeout="$rsync_max_time" --exclude=*.txt --exclude=*.sha256 --exclude=*.sig --exclude=*.gz "$db_url" "$work_dir_add" 2>&13
            ret="$?"
          else
            xshok_file_download "${work_dir_add}/${db_file}" "$db_url"
            ret="$?"
          fi

          # This needs enhancement for rsync, as it will only work with single files...
          # Maybe better to process each file inside work_dir_add in its own for loop.
          if [ "$ret" -eq 0 ] ; then
            loop="1"
            if ! cmp -s "${work_dir_add}/${db_file}" "${clam_dbs}/${db_file}" ; then
              db_ext="${db_file#*.}"
              xshok_pretty_echo_and_log "Testing updated additional database file: ${db_file}"
              if [ -z "$ham_dir" ] || [ "$db_ext" != "ndb" ] ; then
                if $clamscan_bin --quiet -d "${work_dir_add}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                  xshok_pretty_echo_and_log "Clamscan reports additional ${db_file} database integrity tested good"
                  true
                else
                  xshok_pretty_echo_and_log "Clamscan reports additional ${db_file} database integrity tested BAD"
                  if [ "$remove_bad_database" == "yes" ] ; then
                    if rm -f "${work_dir_add}/${db_file}" ; then
                      xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_add}/${db_file}"
                    fi
                  fi
                  false
                  fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${work_dir_add}/${db_file}" "$clam_dbs" 2>&13 ; then
                  perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                  if [ "$selinux_fixes" == "yes" ] ; then
                    restorecon "${clam_dbs}/${db_file}"
                  fi
                  xshok_pretty_echo_and_log "Successfully updated additional production database file: ${db_file}"
                  additional_updates=1
                  additional_db_update=1
                  do_clamd_reload=1
                else
                  xshok_pretty_echo_and_log "Failed to successfully update additional production database file: ${db_file} - SKIPPING"
                fi
              else
                $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${work_dir_add}/${db_file}" > "${test_dir}/${db_file}"
                $clamscan_bin --infected --no-summary -d "${test_dir}/${db_file}" "$ham_dir"/* | command "$sed_bin" 's/\.UNOFFICIAL FOUND//' | awk '{print $NF}' > "${work_dir_work_configs}/whitelist.txt"
                if [[ "${work_dir_add}/${db_file}" == *.db ]] ; then
                  $grep_bin -h -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" | cut -d "=" -f 2 | awk '{ printf("=%s\n", $1);}' |sort | uniq >> "${work_dir_work_configs}/whitelist.hex-tmp"
                  mv -f "${work_dir_work_configs}/whitelist.hex-tmp" "${work_dir_work_configs}/whitelist.hex"
                else
                  $grep_bin -h -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" | cut -d "=" -f 2 | sort | uniq >> "${work_dir_work_configs}/whitelist.hex-tmp"
                  mv -f "${work_dir_work_configs}/whitelist.hex-tmp" "${work_dir_work_configs}/whitelist.hex"
                fi
                $grep_bin -h -v -f "${work_dir_work_configs}/whitelist.hex" "${test_dir}/${db_file}" > "${test_dir}/${db_file}-tmp"
                mv -f "${test_dir}/${db_file}-tmp" "${test_dir}/${db_file}"
                if $clamscan_bin --quiet -d "${test_dir}/${db_file}" "${work_dir_work_configs}/scan-test.txt" 2>&10 ; then
                  xshok_pretty_echo_and_log "Clamscan reports additional ${db_file} database integrity tested good"
                  true
                else
                  xshok_pretty_echo_and_log "Clamscan reports additional ${db_file} database integrity tested BAD"
                  if [ "$remove_bad_database" == "yes" ] ; then
                    if rm -f "${work_dir_add}/${db_file}" ; then
                      xshok_pretty_echo_and_log "Removed invalid database: ${work_dir_add}/${db_file}"
                    fi
                  fi
                  false
                  fi && (test "$keep_db_backup" = "yes" && cp -f -p  "${clam_dbs}/${db_file}" "${clam_dbs}/${db}_file-bak" 2>/dev/null ; true) && if $rsync_bin -pcqt "${test_dir}/${db_file}" "$clam_dbs" 2>&13 ; then
                  perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/${db_file}"
                  if [ "$selinux_fixes" == "yes" ] ; then
                    restorecon "${clam_dbs}/${db_file}"
                  fi
                  xshok_pretty_echo_and_log "Successfully updated additional production database file: ${db_file}"
                  additional_updates=1
                  additional_db_update=1
                  do_clamd_reload=1
                else
                  xshok_pretty_echo_and_log "Failed to successfully update additional production database file: ${db_file} - SKIPPING"
                fi
              fi
            fi
          else
            xshok_pretty_echo_and_log "WARNING: Failed connection to ${db_url} - SKIPPED additional ${db_file} update"
          fi
          if [ "$additional_db_update" != "1" ] ; then
            xshok_pretty_echo_and_log "No updated additional ${db_file} database file"
          fi
        done
        if [ "$additional_updates" != "1" ] ; then
          xshok_pretty_echo_and_log "No additional database file updates" "-"
        fi
      else
        xshok_pretty_echo_and_log "Additional Database File Updates" "="
        xshok_draw_time_remaining "$((update_interval - time_interval))" "$additional_update_hours" "additionaldatabaseupdate"
      fi
    fi
  fi
else
  if [ -n "$additional_dbs" ] ; then
    if [ "$remove_disabled_databases" == "yes" ] ; then
      xshok_pretty_echo_and_log "Removing disabled additional Database files"
      for db_file in "${additional_dbs[@]}" ; do
        if echo "$db_file" | $grep_bin -q "/" ; then
          db_file="$(echo "$db_file" | cut -d "/" -f 2)"
        fi
        if [ -r "${work_dir_add}/${db_file}" ] ; then
          rm -f "${work_dir_add}/${db_file}"
          do_clamd_reload=1
        fi
        if [ -r "${clam_dbs}/${db_file}" ] ; then
          rm -f "${clam_dbs}/${db_file}"
          do_clamd_reload=1
        fi
      done
    fi
  fi
fi

###################################################
# Generate whitelists
###################################################
# Check to see if the local.ign file exists, and if it does, check to see if any of the script
# added bypass entries can be removed due to offending signature modifications or removals.
if [ -r "${clam_dbs}/local.ign" ] && [ -s "${work_dir_work_configs}/monitor-ign.txt" ] ; then
  ign_updated=0
  cd "$clam_dbs" || exit
  cp -f -p local.ign "${work_dir_work_configs}/local.ign"
  cp -f -p "${work_dir_work_configs}/monitor-ign.txt" "${work_dir_work_configs}/monitor-ign-old.txt"

  xshok_pretty_echo_and_log "" "=" "80"
  while read -r entry ; do
    sig_file="$(echo "$entry" | tr -d "\\r" | awk -F ":" '{print $1}')"
    sig_hex="$(echo "$entry" | tr -d "\\r" | awk -F ":" '{print $NF}')"
    sig_name_old="$(echo "$entry" | tr -d "\\r" | awk -F ":" '{print $3}')"
    sig_ign_old="$($grep_bin ":$sig_name_old" "${work_dir_work_configs}/local.ign")"
    sig_old="$(echo "$entry" | tr -d "\\r" | cut -d ":" -f 3-)"
    sig_new="$($grep_bin -hwF ":$sig_hex" "$sig_file" | tr -d "\\r" 2>/dev/null)"
    sig_mon_new="$($grep_bin -HwF -n ":$sig_hex" "$sig_file" | tr -d "\\r")"
    if [ -n "$sig_new" ] ; then
      if [ "$sig_old" != "$sig_new" ] || [ "$entry" != "$sig_mon_new" ] ; then
        sig_name_new="$(echo "$sig_new" | tr -d "\\r" | awk -F ":" '{print $1}')"
        sig_ign_new="$(echo "$sig_mon_new" | cut -d ":" -f 1-3)"
        perl -i -ne "print unless /$sig_ign_old/" "${work_dir_work_configs}/monitor-ign.txt"
        echo "$sig_mon_new" >> "${work_dir_work_configs}/monitor-ign.txt"
        perl -p -i -e "s/$sig_ign_old/$sig_ign_new/" "${work_dir_work_configs}/local.ign"
        xshok_pretty_echo_and_log "${sig_name_old} hexadecimal signature is unchanged, however signature name and/or line placement"
        xshok_pretty_echo_and_log "in ${sig_file} has changed to ${sig_name_new} - updated local.ign to reflect this change."
        ign_updated=1
      fi
    else
      perl -i -ne "print unless /$sig_ign_old/" "${work_dir_work_configs}/monitor-ign.txt" "${work_dir_work_configs}/local.ign"

      xshok_pretty_echo_and_log "${sig_name_old} signature has been removed from ${sig_file}, entry removed from local.ign."
      ign_updated=1
    fi
  done < "${work_dir_work_configs}/monitor-ign-old.txt"
  if [ "$ign_updated" == "1" ] ; then
    if $clamscan_bin --quiet -d "${work_dir_work_configs}/local.ign" "${work_dir_work_configs}/scan-test.txt" ; then
      if $rsync_bin -pcqt "${work_dir_work_configs}/local.ign" "$clam_dbs" ; then
        perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/local.ign"
        perms chmod -f 0644 "${clam_dbs}/local.ign" "${work_dir_work_configs}/monitor-ign.txt"
        if [ "$selinux_fixes" == "yes" ] ; then
          restorecon "${clam_dbs}/local.ign"
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
if [ -r "${clam_dbs}/my-whitelist.ign2" ] && [ -s "${work_dir_work_configs}/tracker.txt" ] ; then
  ign2_updated=0
  cd "$clam_dbs" || exit
  cp -f -p my-whitelist.ign2 "${work_dir_work_configs}/my-whitelist.ign2"

  xshok_pretty_echo_and_log "" "=" "80"
  touch "${work_dir_work_configs}/tracker-tmp.txt"
  while read -r entry ; do

      yaratest="$(echo "$entry" | cut -d "." -f 1)"
      shopt -s nocasematch
      if [ "$yaratest" != "YARA" ] ; then
        sig_file="$(echo "$entry" | cut -d ":" -f 1)"
        sig_full="$(echo "$entry" | cut -d ":" -f 2-)"
        sig_name="$(echo "$entry" | cut -d ":" -f 2)"
        if ! $grep_bin -F "$sig_full" "$sig_file" > /dev/null 2>&1 ; then
          perl -i -ne "print unless /$sig_name$/" "${work_dir_work_configs}/my-whitelist.ign2"
          perl -i -ne "print unless /:$sig_name:/" "${work_dir_work_configs}/tracker-tmp.txt"
          xshok_pretty_echo_and_log "${sig_name} signature no longer exists in ${sig_file}, whitelist entry removed from my-whitelist.ign2"
          ign2_updated="1"
        fi
    fi
  done < "${work_dir_work_configs}/tracker.txt"
  if [ -f "${work_dir_work_configs}/tracker-tmp.txt" ] ; then
    mv -f "${work_dir_work_configs}/tracker-tmp.txt" "${work_dir_work_configs}/tracker.txt"
  fi


  xshok_pretty_echo_and_log "" "=" "80"
  if [ "$ign2_updated" == "1" ] ; then
    if $clamscan_bin --quiet -d "${work_dir_work_configs}/my-whitelist.ign2" "${work_dir_work_configs}/scan-test.txt" ; then
      if $rsync_bin -pcqt "${work_dir_work_configs}/my-whitelist.ign2" "$clam_dbs" ; then
        perms chown -f "${clam_user}:${clam_group}" "${clam_dbs}/my-whitelist.ign2"
        perms chmod -f 0644 "${clam_dbs}/my-whitelist.ign2" "${work_dir_work_configs}/tracker.txt"
        if [ "$selinux_fixes" == "yes" ] ; then
          restorecon "${clam_dbs}/my-whitelist.ign2"
          restorecon "${work_dir_work_configs}/tracker.txt"
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
  if [ -r "${work_dir_work_configs}/whitelist.hex" ] ; then
    $grep_bin -h -f "${work_dir_work_configs}/whitelist.hex" "$work_dir"/*/*.ndb | cut -d "*" -f 2 | tr -d "\\r" | sort | uniq > "${work_dir_work_configs}/whitelist.tmp"
    $grep_bin -h -f "${work_dir_work_configs}/whitelist.hex" "$work_dir"/*/*.db | cut -d "=" -f 2 | awk '{ printf("=%s\n", $1);}' | sort | uniq >> "${work_dir_work_configs}/whitelist.tmp"
    mv -f "${work_dir_work_configs}/whitelist.tmp" "${work_dir_work_configs}/whitelist.hex"
    rm -f "${work_dir_work_configs}/whitelist.txt"
    rm -f "${test_dir}/*.*"
    xshok_pretty_echo_and_log "WARNING: Signature(s) triggered on HAM directory scan - signature(s) removed"
  else
    xshok_pretty_echo_and_log "No signatures triggered on HAM directory scan" "="
  fi
fi
# Set appropriate directory and file permissions to all production signature files
# and set file access mode to 0644 on all working directory files.

if [ "$setmode" == "yes" ] ; then
  xshok_pretty_echo_and_log "Setting permissions and ownership" "="
  perms chown -f -R "${clam_user}:${clam_group}" "$work_dir"
  if ! find "$work_dir" -type f -exec chmod -f 0644 "{}" "+" 2>/dev/null ; then
    if ! find "$work_dir" -type f -print0 | xargs -0 chmod -f 0644 2>/dev/null ; then
      find "$work_dir" -type f -exec chmod -f 0644 "{}" ";"
    fi
  fi

  # If enabled, set file access mode for all production signature database files to 0644.
  perms chown -f -R "${clam_user}:${clam_group}" "$clam_dbs"
  if ! find "$clam_dbs" -type f -exec chmod -f 0644 "{}" "+" 2>/dev/null ; then
    if ! find "$clam_dbs" -type f -print0 | xargs -0 chmod -f 0644 2>/dev/null ; then
      find "$clam_dbs" -type f -exec chmod -f 0644 "{}" ";"
    fi
  fi
fi

# Reload all clamd databases
clamscan_reload_dbs

xshok_pretty_echo_and_log "Issue tracker : https://github.com/extremeshok/clamav-unofficial-sigs/issues" "-"

if [ "$allow_update_checks" != "no" ] ; then

    if [ -r "${work_dir_work_configs}/last-version-check.txt" ] ; then
      last_version_check="$(cat "${work_dir_work_configs}/last-version-check.txt")"
    else
      last_version_check="0"
    fi
    db_file=""
    update_check_interval="$((update_check_hours * 3600))"
    time_interval="$((current_time - last_version_check))"
    if [ "$time_interval" -ge $((update_check_interval - 600)) ] ; then
      echo "$current_time" > "${work_dir_work_configs}/last-version-check.txt"
        if xshok_is_root ; then
            perms chown -f "${clam_user}:${clam_group}" "${work_dir_work_configs}/last-version-check.txt"
        fi
        check_new_version
    fi

fi

xshok_cleanup

# Set the permission of the log file, to fix any permission errors, this is done to fix cron errors after running the script as root.
if xshok_is_root ; then
    if [ "$enable_log" == "yes" ] ; then
        # check if the file is owned by root (the current user)
        if [ -O "${log_file_path}/${log_file_name}" ] ; then
            # checks the file is writable and a file (not a symlink/link)
            if [ -w "${log_file_path}/${log_file_name}" ] && [ -f "${log_file_path}/${log_file_name}" ] ; then
                perms chown -f "${clam_user}:${clam_group}" "${log_file_path}/${log_file_name}"
            fi
        fi
    fi
fi

# And lastly we exit, Note: the exit is always on the 2nd last line
exit $?
