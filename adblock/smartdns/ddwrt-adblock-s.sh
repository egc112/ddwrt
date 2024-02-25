#!/bin/sh
#DEBUG=; set -x # comment/uncomment to disable/enable debug mode

# name: ddwrt-adblock-s.sh
# version: 0.2, 25-feb-2024, by egc, based on eibgrads ddwrt-blacklist-domains-adblock
# purpose: blacklist specific domains in smartdns using a list of domains
# script type: shell script
# installation:
# 1. enable jffs2 (administration->jffs2) **or** use usb with jffs directory
# 2. enable syslogd (services->services->system log)
# 3. copy ddwrt-adblock-s.sh from https://github.com/egc112/ddwrt/tree/main/adblock/smartdns to /jffs
#    either with: curl -o /jffs/ddwrt-adblock-s.sh https://raw.githubusercontent.com/egc112/ddwrt/main/adblock/smartdns/ddwrt-adblock-s.sh
#    or by clicking the download icon in the upper right corner of the script
# 4. make executable: chmod +x /jffs/ddwrt-adblock-s.sh
# 5. add to Administration  > Commands: 
#      /jffs/ddwrt-adblock-s.sh & 
#      if placed on USB then "Save USB" ; if jffs2 is used then : "Save Startup"
#      Depending on the speed of your router or use of VPN, you might need to precede the command with: sleep 30
# 6. add the following to the "additional smartdns options" field on the
#    services page:
#      conf-file /tmp/*.adblock
# 7. modify options e.g. URL list, MYWHITELIST and MYBLACKLIST:
#     vi /jffs/ddwrt-adblock-s.sh 
#     or edit with WinSCP
# 8. (optional) enable cron (administration->management) and add the
#     following job (runs daily at 4 a.m.):
#     0 4 * * * root /jffs/ddwrt-adblock-s.sh
# 9. reboot
#10. (optional) Prevent LAN clients to use their own DNS by ticking/enabling Forced DNS Redirection and
#    Forced DNS Redirection DoT on Basic Setup page
#11. Debug by removing the # on the second line of this script, view with: grep -i adblock /var/log/messages
(
# ------------------------------ BEGIN OPTIONS ------------------------------- #

# websites known to maintain a list of blacklisted domains
# note: exercise caution when using commented urls; these sites often
#       contain *very* large lists of blacklisted domains, which may exceed
#       the memory capacity of the router and/or smartdns, and *may* have a
#       detrimental affect on dns performance

URL_LIST='
https://raw.githubusercontent.com/hagezi/dns-blocklists/main/domains/light.txt
#https://small.oisd.nl/domainswild2
'

# exceptions: domains (and their sub-domains) NOT to be blacklisted
# note: matching only occurs on whole parts of the domain name, moving right
#       to left; for example, adding somedomain.com to the whitelist would
#       also match xyz.somedomain.com, but NOT match xyzsomedomain.com nor
#       xyz.somedomain.com.us; wildcards (*) are NOT supported and will be
#       removed
MYWHITELIST='
localhost
googleadservices.com
services.googleapis.com
dd-wrt.com
'

# websites/domains you manually want to blacklist
MYBLACKLIST='
face_book.com
twitter.com
tik_tok.com
'

# maximum time (in secs) alloted to any curl/wget operation
MAX_WAIT=60

# ------------------------------- END OPTIONS -------------------------------- #

# ---------------------- DO NOT CHANGE BELOW THIS LINE ----------------------- #
# sleep to let the router Startup
sleep $MAX_WAIT

# domains to be blacklisted
BLACKLIST='/tmp/blacklisted_domains.sblck'; > $BLACKLIST
# workfile
RAW_BLACKLIST="/tmp/tmp.$$.raw_blacklist"

# smartdns conf file
SMARTDNS_CONF="/tmp/smartdns.adblock"

add_myblacklist(){
for domain in $MYBLACKLIST; do
	echo "$domain" >> $BLACKLIST
done
}

rogue_check() {
	# Get line number and match of any rogue elements
	#LC_ALL=C sed -nE '\~(^(local|server|address)=/)[[:alnum:]*][[:alnum:]*_.-]+(/$)|^#|^\s*$~d;{p;=;}' $1 | 

	LC_ALL=C sed -nE '/[.].*[a-zA-Z0-9][a-zA-Z0-9-]+([.][a-zA-Z]{2,15})?$/d;{p;=;}' $1 |
	while read line1; do
		read line2
		echo "adblock: Rogue element: line ${line2}: ${line1} identified in new blocklist"
		# remove offending entry
		echo "adblock: Removing offending line: ${line2}: ${line1}"
		sed -i /"${line1}"/d $1
	done
}

smartdns_check(){
	stopservice smartdns
	smartdns -c /tmp/smartdns.conf 2>&1
	[[ ${?} -eq 0 ]] && echo "adblock: SmartDNS check OK " || { echo "adblock: ERROR: SmartDNS check ERROR, cannot run $(basename $0)"; \ 
		killall smartdns; > $SMARTDNS_CONF; restart smartdns; release_lock; exit 1; }
}

smartdns_conffile(){
	echo "domain-set -name adblock -file $BLACKLIST" > $SMARTDNS_CONF
	echo "address /domain-set:adblock/#" >> $SMARTDNS_CONF
}

# required for serialization when reentry is possible
LOCK="/tmp/$(basename $0).lock"
acquire_lock() { while ! mkdir $LOCK >/dev/null 2>&1; do sleep 10; done; }
release_lock() { rmdir $LOCK >/dev/null 2>&1; }

# default to curl, failover to wget (not guaranteed to support tls)
which curl &>/dev/null && \
    GET_URL="curl -sLk --connect-timeout $MAX_WAIT --max-time $MAX_WAIT" || \
    GET_URL="wget -T $MAX_WAIT -qO -"

# wait for wan availability
until ping -qc1 -W3 8.8.8.8 &>/dev/null; do sleep 10; done

# one instance at a time
acquire_lock

# catch premature exit and cleanup
trap 'release_lock; exit 1' SIGHUP SIGINT SIGTERM

for url in $URL_LIST; do
    # skip comments and blank lines
    echo $url | grep -Eq '^[[:space:]]*(#|$)' && continue
    # retrieve url as raw blacklist
    $GET_URL $url > $RAW_BLACKLIST || { echo "adblock: ERROR: $url"; continue; }
	# Clean
	#sed 's/\s*#.*$//; s/^[ \t]*//; s/[ \t]*$//; /^\s*$/d; s/\(^address\|^server|^local\)//; \' $RAW_BLACKLIST >> $BLACKLIST
	sed 's/\s*#.*$//; s/^[ \t]*//; s/[ \t]*$//; /^\s*$/d; s/\(^address=\|^server=\|^local=\)//; s/^www.//; s/\///g; \' $RAW_BLACKLIST >> $BLACKLIST
done

# cleanup
rm -f $RAW_BLACKLIST

# add personal blacklisted domains
add_myblacklist

# sort and remove duplicates
sort $BLACKLIST | uniq -u >/dev/null 2>&1

# check for rogue elements and malformed domain names
rogue_check $BLACKLIST

# remove domains and sub-domains that match whitelist
if [ "$(echo $MYWHITELIST)" ]; then
    sed -ri "/$(echo $MYWHITELIST | \
		sed -r 's/\*//g;s/( |$)/\\\/$|/g;s/\|$//;s/\./\\./g')/d" \
            $BLACKLIST
	#alternate add domains with :/# e.g.: local=/zzzregsizzz.com.ru/# 
	#for wl in "$(echo $MYWHITELIST)"; do
	#	sed -i "1i local=\/${wl}\/#" $BLACKLIST
	#	# echo "local=/${wl}/#" >> $BLACKLIST
	#done
fi

# wait for smartdns availability
until pidof smartdns &>/dev/null; do sleep 10; done

# make smartdns conf file
smartdns_conffile

# check if smartdns will run
smartdns_check $BLACKLIST

# force smartdns to recognize updated blacklist
stopservice smartdns && sleep 1 && startservice smartdns

# report the results
echo "adblock: Running $(basename $0) with total blacklisted domains: $(wc -l < $BLACKLIST)"

# any concurrent instance(s) may now run
release_lock

exit 0

) 2>&1 | logger $([ ${DEBUG+x} ] && echo '-p user.debug') \
    -t $(echo $(basename $0) | grep -Eo '^.{0,23}')[$$] &
