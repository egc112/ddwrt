### Simple Adblock for SmartDNS in DDWRT 

This scripts uses domainlists for blocking domains in SmartDNS  
The script has already some default sources for blocklists incorporated which should work for normal operation but  
if you want more than see these popular sources of domain lists:  
- `https://github.com/hagezi/dns-blocklists/tree/main/domains`  
	You can get the URL of the list by clicking on the `RAW` button in the upper right corner,  
	remove `https://` and add the URL to the URL list in the script.  
- `https://oisd.nl/setup `  
  Use the `domainswild2` lists  
  Select small/big/nsfw or a combination, right click to get the URL and remove `https://`  

You can add your own domains you want to [whitelist](https://en.wikipedia.org/wiki/Whitelist) and  
add your own domains you want to [blacklist](https://en.wikipedia.org/wiki/Blacklisting)
  
name: ddwrt-adblock-s.sh
version: 0.1, 18-feb-2024, by egc, based on eibgrads ddwrt-blacklist-domains-adblock
purpose: blacklist specific domains in smartdns using a list of domains
script type: shell script
installation:
1. Enable jffs2 (administration->jffs2) **or** use usb with jffs directory
2. Enable syslogd (services->services->system log)
3. Copy ddwrt-adblock-s.sh from https://github.com/egc112/ddwrt/tree/main/adblock/smartdns to /jffs either with:  
   `curl -o /jffs/ddwrt-adblock-s.sh https://raw.githubusercontent.com/egc112/ddwrt/main/adblock/smartdns/ddwrt-adblock-s.sh`  
   or by clicking the download icon in the upper right corner of the script  
4. Make executable: `chmod +x /jffs/ddwrt-adblock-s.sh`
5. Add to Administration > Commands: `/jffs/ddwrt-adblock-s.sh &`  
     If placed on USB then "Save USB" ; if jffs2 is used then : "Save Startup"  
     Depending on the speed of your router or use of VPN, you might need to precede the command with: sleep 30  
6. Add the following to the "additional smartdns options" field on the services page:  
     ```
     domain-set -name adblock -file /tmp/blacklisted_domains.sblck  
     #block IPv4 and IPv6:# ; block IPv4:#4; block IPv6:#6  
     address /domain-set:adblock/#
     ```  
7. Modify options e.g. URL list, MYWHITELIST and MYBLACKLIST:  
    `vi /jffs/ddwrt-adblock-s.sh`  
    or edit with WinSCP  
8. (optional) enable cron (administration->management) and add the  
    following job (runs daily at 4 a.m.):  
    `0 4 * * * root /jffs/ddwrt-adblock-s.sh`
9. Reboot  
10. (Optional) Prevent LAN clients to use their own DNS by ticking/enabling Forced DNS Redirection and  
   Forced DNS Redirection DoT on Basic Setup page
11. Debug by removing the # on the second line of this script, view with: grep -i adblock /var/log/messages  
  
  
References  
https://pymumu.github.io/smartdns/en/config/ad-block/
