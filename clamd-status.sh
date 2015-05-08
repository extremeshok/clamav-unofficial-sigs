#!/bin/sh

# Script freely provided by Bill Landry (unofficialsigs@gmail.com); however,
# use at your own peril!  Comments, suggestions, and recommendations for
# improving this script are always welcome.  Feel free to report any
# issues, as well.

# This script will monitor and report the status of ClamD.  It can also
# be configured to attempt to restart the ClamD daemon if it is found to
# be non-responsive.  All variables below should be set correctly if set
# to restart a failed, crashed, or non-responsive daemon.  Before trying
# to restart the ClamD daemon, the script will first delete any orphaned
# pid, lock, or socket files that may have been left due to a crash.

######################################################################################
# START OF USER CONFIGURATION SECTION - SET PROGRAM PATHS AND OTHER VARIABLE OPTIONS #
######################################################################################

# Edit quoted variables below to meet your own particular
# needs/requirements, but do not remove the "quote" marks.

# Set and export program paths.
PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"
export PATH

# Set path to clamd.pid file (see clamd.conf for path location).
clamd_pid="/var/run/clamav/clamd.pid"

# If running clamd in "LocalSocket" mode (*NOT* in TCP/IP mode), and
# either "SOcket Cat" (socat) or the "IO::Socket::UNIX" perl module
# are installed on the system, and you want to report whether clamd
# is running or not, uncomment the "clamd_socket" variable below (you
# will be warned if neither socat nor IO::Socket::UNIX are found, but
# the script will still run).  You will also need to set the correct
# path to your clamd socket file (if unsure of the path, check the
# "LocalSocket" setting in your clamd.conf file for socket location).
clamd_socket="/var/run/clamav/clamd.sock"

# If you would like to attemtp to restart ClamD if detected not running,
# uncomment the next 2 lines.  Confirm the path to the "clamd_lock" file
# (usually can be found in the clamd init script) and also enter the clamd
# start command for your particular distro for the "start_clamd" variable
# (the sample start command shown below should work for most linux distros).
# NOTE: these 2 variables are dependant on the "clamd_socket" variable
# shown above - if not enabled, then the following 2 variables will be
# ignored, whether enabled or not.
clamd_lock="/var/lock/subsys/clamd"
start_clamd="service clamd start"

# To only report issues, set the following variable to "yes".
only_report_issues="yes"

# Log update information to '$log_file_path/$log_file_name'.
enable_logging="no"
log_file_path="/var/log"
log_file_name="clamd-status.log"

# Set the following variable to "yes" once you have completed the
# "USER CONFIGURATION SECTION" of this script.
user_configuration_complete="no"

#######################################################################################
# END OF USER CONFIGURATION SECTION - YOU SHOULD NOT NEED TO EDIT ANYTHING BELOW HERE #
#######################################################################################

# Use functions to make code more readable.
comment () {
   test "$only_report_issues" = "no" && echo "$1"
}

log () {
   test "$enable_logging" = "yes" && echo "`date "+%b %e %T"` $1" >> $log_file_path/$log_file_name
}

# Check to see if the script's "USER CONFIGURATION SECTION" has been completed.
if [ "$user_configuration_complete" != "yes" ]
   then
      echo ""
      echo "               *** SCRIPT CONFIGURATION HAS NOT BEEN COMPLETED ***"
      echo "   Please review and configure the 'USER CONFIGURATION SECTION' of the script."
      echo "    Once the user configuration section has been completed, rerun the script."
      echo ""
      log "ALERT - SCRIPT HALTED, user configuration not completed"
   exit 1
fi

if [ -t 0 ] ; then
   only_report_issues="no"
   log "INFO - Script was run manually"
fi

# If ClamD status check is enabled ("clamd_socket" variable is uncommented
# and the socket path is correctly specified in "User Edit" section above),
# then test to see if clamd is running or not.
if [ -n "$clamd_socket" ] ; then
   if [ "`perl -e 'use IO::Socket::UNIX; print $IO::Socket::UNIX::VERSION,"\n"' 2> /dev/null`" ]
      then
         io_socket1=1
         if [ "`perl -MIO::Socket::UNIX -we '$s = IO::Socket::UNIX->new(shift); $s->print("PING"); \
            print $s->getline; $s->close' "$clamd_socket" 2> /dev/null`" = "PONG" ] ; then
            io_socket2=1
            comment "===================="
            comment "= ClamD is running ="
            comment "===================="
            log "INFO - ClamD is running"
         fi
      else
         socat="`which socat 2> /dev/null`"
         if [ -n "$socat" -a -x "$socat" ] ; then
            socket_cat1=1
            if [ "`(echo "PING"; sleep 1;) | socat - "$clamd_socket" 2> /dev/null`" = "PONG" ] ; then
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
         log "WARNING - neither socat nor IO::Socket::UNIX perl module found, cannot test whether ClamD is running"
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
                     rm -f $clamd_pid $clamd_lock $clamd_socket 2> /dev/null
                     $start_clamd > /dev/null && sleep 5
                     if [ "`perl -MIO::Socket::UNIX -we '$s = IO::Socket::UNIX->new(shift); \
                        $s->print("PING"); print $s->getline; $s->close' "$clamd_socket" \
                        2> /dev/null`" = "PONG" ]
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
                        rm -f $clamd_pid $clamd_lock $clamd_socket 2> /dev/null
                        $start_clamd > /dev/null && sleep 5
                        if [ "`(echo "PING"; sleep 1;) | socat - "$clamd_socket" 2> /dev/null`" = "PONG" ]
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

exit $?
