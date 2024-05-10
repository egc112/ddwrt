HOW-TO iperf3 throughput testing
================================

The best way to really test the performance of the router is to use two
computers wired to the router.

TCP testing is real-life performance testing of what you'll see when browsing,
streaming, downloading, etc. UDP testing will test the overall possible
performance of the router for "Unmanaged" packets.

UDP testing is only good to 1gbps speeds, above that, it will consume too much
cpu & ram,  
see: [TCP Vs.
UDP](https://www.howtogeek.com/190014/htg-explains-what-is-the-difference-between-tcp-and-udp/)

You can download the iperf3 package from: <https://iperf.fr/iperf-download.php>

Just download the zip file and extract it to a directory of choice (e.g. iperf).

To run simply open a command window in that directory.

Running iperf on the router as a server or a client is possible, but realize you
will be consuming extra cpu & ram resources to run IPERF and you won't get
accurate speed results!.  
  
This is the setup you want to do for WAN-LAN performance testing:  
![afbeelding](https://github.com/egc112/ddwrt/assets/63402314/5faf69fe-1991-4812-a610-7cc36d5907de)


1.  If the router is connected to another upstream router you can simply use one
    of the connected clients of that router as server, no need to change
    anything in this case and proceed with step 3.

2.  But if not set the static IP address of PC A(Server) by setting the IP
    address of PC A to 192.168.2.30, subnet to 255.255.255.0 and Default gateway
    as 192.168.2.20 \<--The router WAN IP. PC A will plug into the WAN PORT.  
    Set a static IP address for WAN port on the Router e.g. WAN IP 192.168.2.20,
    subnet 255.255.255.0, and gateway is PC A - 192.168.2.30  
    For DDWRT, go to the main setup tab and at the top of the screen is WAN
    connection type, choose static IP. Make the WAN IP 192.168.2.20, subnet
    255.255.255.0, and gateway is PC A - 192.168.2.30

3.  For PC B (client) make sure DHCP is enabled on the router and it will assign
    an IP to your PC B/client.

4.  Before testing reboot the router and let it settle down for 10 minutes.  
    Note: if SFE or other offloading (CTF, FA) is enabled, test with and without
    this enabled.  
    If irqbalance is available on your router always test with irqbalance
    enabled.  
    Now it's time to run iperf on both PC A and PC B so open up command prompts
    on each device.

5.  PC A is the server so run the command: *iperf3 -s*

6.  PC B is the client so run the command:  
    *iperf3 -c \<ip-address-of-server\> -b 1000M -P 4 -t 20*  
    e.g.: *iperf3 -c 192.168.2.30 -b 1000M -P 4 -t 20*  
    This will run a test at "gig" speed (-b 1000M) and 4 parallel streams (-P
    4), the test will run for 20 seconds (-t 20). This should saturate the
    connection and accurately measure the TCP throughput WAN to LAN.  
    Discard the first run as the router (e.g. irqbalance) has to settle in.  
    Make three test runs and calculate the mean.

7.  If you want to run the test in UDP mode add: *-u* to the end of the above
    initial code.

8.  To reverse the client and server testing path use *-R* after the initial
    code in step 6.

Wireless performance testing can be done with a PC/Laptop connected wired to the
router and a laptop/PC connected wirelessly.

For help and viewing all commands do: *iperf3 -h* and view the help docs:
<https://iperf.fr/iperf-doc.php>
