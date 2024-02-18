Wireless Access Point 
======================

A secondary router connected wired LAN\<\>LAN on the same subnet as the primary
router.

Setup:

-   On Basic Setup page:

    -   WAN disabled

    -   DHCP server Disabled (=off and NOT set as Forwarder!)

    -   Local IP address in subnet of primary router but outside DHCP scope,
        make sure the used IP address is unique on your network you cannot have
        duplicates.  
        You can run udhcpc to give the WAP a static lease but because you can it
        doesn't mean you should ;)

    -   Gateway **and** Local DNS pointing to primary router  
        Example:  
        If your primary router is 192.168.1.1 then set the Local IP address of
        the WAP to 192.168.1.**2** (make sure that is not used).  
        The Gateway and Local DNS are set to point to the primary router e.g.:
        192.168.1.**1**

-   Keep DNSMasq enabled (both on Basic Setup page and Services page)

-   On Setup \> Advanced Routing, keep Operating mode in the default Gateway
    (the wiki says Router mode but do not do that, either it does not matter
    (this case) or break things)

-   On Security \> Firewall keep the **SPI Firewall enabled,** although you do
    not want a firewall it will be automatically disabled as there is no WAN so
    no need to change this setting from default.

-   Connect LAN \<\> LAN (**do not use the WAN port** unless you really need
    that extra port, for most routers traffic still must use the CPU so
    performance is lacklustre and there are some routers where the WAN port is
    not added to br0 so the WAN port could be non-functional on some routers).

Note: For Broadcom routers for best throughput enable CTF on Basic Setup Page

If you have unbridged interfaces on the WAP (Virtual Access Point (VAP), bridg,
vpn server or vpn cliente etc.), you have to add the following rule to the
firewall in order to get internet access.

In the web-interface of the router (the WAP): Administration \> Commands save
Firewall:

Always necessary (alternatively set static route on main router and NAT
traffic from VAP/Bridge out via WAN):
```
iptables -t nat -I POSTROUTING -o br0 -j SNAT --to \$(nvram get lan_ipaddr)
```

If you want to only have the VAP/bridge to have internet access and not access
to the rest of the network

Replace with the appropriate interface of your VAP, e.g. wl0.1, wlan0.1 etc:
```
GUEST_IF="wlan1.1"
#Net Isolation does not work on a WAP so keep it disabled, add for isolating VAP from main network:  
iptables -I FORWARD -i \$GUEST_IF -d \$(nvram get lan_ipaddr)/\$(nvram get lan_netmask) -m state --state NEW -j REJECT
```

For isolating the WAP itself from the VAP/bridge:  
```
iptables -I INPUT -i \$GUEST_IF -m state --state NEW -j REJECT
iptables -I INPUT -i \$GUEST_IF -p udp --dport 67 -j ACCEPT
iptables -I INPUT -i \$GUEST_IF -p udp --dport 53 -j ACCEPT
iptables -I INPUT -i \$GUEST_IF -p tcp --dport 53 -j ACCEPT
```

To make it simple and isolate the VAP/bridge from all know private subnets which isolate it not only from the main network but also from other bridges:  
```
iptables -I FORWARD -i \$GUEST_IF -d 192.168.0.0/16 -m state --state NEW -j REJECT
iptables -I FORWARD -i \$GUEST_IF -d 10.0.0.0/8 -m state --state NEW -j REJECT
iptables -I FORWARD -i \$GUEST_IF -d 172.16.0.0/12 -m state --state NEW -j REJECT
```

If you have a lot of VAP's bridges you can make a loop e.g.:  
```
for GUEST_IF in br1 br2 br3 do
    iptables -I FORWARD -i \$GUEST_IF -d \$(nvram get lan_ipaddr)/\$(nvram get lan_netmask) -m state --state NEW -j REJECT
done
```

#Isolate the VAP/bridges from each other
```
iptables -I FORWARD -i br1 -o br2 -m state --state NEW -j REJECT
iptables -I FORWARD -i br2 -o br1 -m state --state NEW -j REJECT
```

Sometimes you see duplicate rules depending on how often the firewall restarts
if that is a problem precede the rules with *-D* instead of *-I*.

note:  
When the Wan is disabled VLAN 1 and VLAN2 are just bridged but on the switch level (swconfig) the VLANs are still separated

References:  

\@mrjcd’s guide:
<https://forum.dd-wrt.com/phpBB2/viewtopic.php?p=1047143#1047143>

<https://wiki.dd-wrt.com/wiki/index.php/Guest_Network#VAP_with_no_WAN>

ALternative DNSMAsq method:
<https://wiki.dd-wrt.com/wiki/index.php/Guest_Network#New_DNSMasq_Method>

\@eibgrad's isolation: <https://pastebin.com/r4u62P0B>
