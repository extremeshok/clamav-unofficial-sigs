#!/bin/bash
###################
# This is property of eXtremeSHOK.com
# You are free to use, modify and distribute, however you may not remove this notice.
# Copyright (c) Adrian Jon Kriel :: admin@extremeshok.com
# License: BSD (Berkeley Software Distribution)
##################
# A small utility to check/verify Yara-Rules from https://github.com/Yara-Rules/rules
#################
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/local/musl/bin:$HOME/bin

wget https://raw.githubusercontent.com/Yara-Rules/rules/master/index.yar -O /tmp/index.yar
sed 's|include "./||g' /tmp/index.yar | sed 's|"||g' | sed -r ':a; s%(.*)/\*.*\*/%\1%; ta; /\/\*/ !b; N; ba' | sed '/^$/d' > /tmp/rules.yara

echo "" > /tmp/empty-file

while IFS= read -r line ; do
  if [ -n "$line" ] ; then
    # shellcheck disable=SC2086
    sub_dir="${line/\/*}"
    mkdir -p "/tmp/yara/${sub_dir}"

    wget --quiet "https://raw.githubusercontent.com/Yara-Rules/rules/master/${line}" -O "/tmp/yara/${line}"

    output="$(clamscan --quiet --no-summary --database="/tmp/yara/${line}" /tmp/empty-file 2>&1)"
    ret="$?"

    if [ -n "$output" ] || [ "$ret" != "0" ] ; then
      echo "ERROR --- ${line} ---"
    else
      echo "--- ${line} ---"
      #echo "$ret"
      #echo "$output"
    fi
  fi
done < "/tmp/rules.yara"


# clamscan --database=antidebug_antivm.yar 2> scan.log
#
# egrep "yyerror()|yara" scan.log
# check the errorlevel at this stage.

# here is some testing code which identifies all rules in .yar file, checks for which ones are duplicated in rfxn.yara, then shows the name of the rules that are not duplicated.:
# shellcheck disable=SC2062
grep -ah "^rule " /var/lib/clamav/*.yar|cut -d: -f1 >/tmp/rules; while read -r RULE; do grep -qF "$RULE" /var/lib/clamav/rfxn.yara||echo "$RULE"; done</tmp/rules

# And this does the same check but outputs the names of the .yar files where the non-duplicated rules are found:
# shellcheck disable=SC2062
grep -ah "^rule " /var/lib/clamav/*.yar|cut -d: -f1 >/tmp/rules; while read -r RULE; do grep -qF "$RULE" /var/lib/clamav/rfxn.yara||echo "$RULE"; done</tmp/rules|grep -Ff- /var/lib/clamav/*.yar
