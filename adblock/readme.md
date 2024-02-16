### Simple Adblock for DDWRT 

Use domainlists for DNSMasq > 2.86 with format `local=/blockeddomain/`  
Popular source of domain lists:  
- https://github.com/hagezi/dns-blocklists/tree/main/dnsmasq
	You can get the URL of the list by clicking on the `RAW` button in the upper right corner, remove `https://`  
	and add the URL to the URL list in the script.
- https://oisd.nl/setup/dnsmasq
  	Use the dnsmasq*2* file, right click to get the URL and remove `https://`

You can add your own domains you want to [whitelist](https://en.wikipedia.org/wiki/Whitelist) and  
add your own domains you want to [blacklist](https://en.wikipedia.org/wiki/Blacklisting)

name: ddwrt-adblock.sh  
version: 0.9, 15-feb-2024, by egc, based on eibgrads ddwrt-blacklist-domains-adblock  
purpose: blacklist specific domains in dnsmasq (dns) for DNSMasq > version 2.86 using local=/my.blockeddomain/  
script type: startup (autostart)  
 installation:  
   1. enable jffs2 (administration->jffs2) **or** use usb with jffs directory  
   2. enable syslogd (services->services->system log)  
   3. copy ddwrt-adblock.sh from [egc](https://github.com/egc112/ddwrt/tree/main/adblock) to /jffs  
   4. make executable: chmod +x /jffs/ddwrt-adblock.sh  
   5. add to Administration  > Commands:   
       `/jffs/ddwrt-adblock.sh &`  
      if placed on USB then "Save USB" ; if jffs2 is used then : "Save Startup"  
      Depending on the speed of your router or use of VPN, you might need to precede the command with: sleep 20    
   6. add the following to the "additional dnsmasq options" field on the  
      services page:  
       `conf-dir=/tmp/blocklists`  
       `/tmp/blocklists` is the directory where the blocklists are placed and can be checked  
   7. modify options e.g. URL list, MYWHITELIST and MYBLACKLIST:  
        vi /jffs/ddwrt-adblock.sh   
	or edit with WinSCP  
   8. (optional) enable cron (administration->management) and add the  
        following job (runs daily at 4 a.m.):  
        0 4 * * * root /jffs/ddwrt-adblock.sh  
   9. reboot  
   10. Prevent LAN clients to use their own DNS by ticking/enabling `Forced DNS Redirection` and  
       `Forced DNS Redirection DoT` on Basic Setup page  
   11. Debug by removing the # on the second line of the script, view with: `grep -i adblock /var/log/messages`
  
  
References  
https://forum.dd-wrt.com/phpBB2/viewtopic.php?t=335928  
https://forum.openwrt.org/t/adblock-lean-set-up-adblock-using-dnsmasq-blocklist/157076/537  
https://forum.dd-wrt.com/phpBB2/viewtopic.php?p=1255771&sid=cfa6a506dccdc75b37c77eab937eb626  
https://pastebin.com/aySi7RhY  
