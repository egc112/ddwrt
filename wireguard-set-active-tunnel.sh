#!/bin/sh
#DEBUG=; set -x # comment/uncomment to disable/enable debug mode

#	name: wireguard-set-active-tunnel.sh
#	version: 0.1 beta, 24-jan-2024, jpjpjp based on work by egc
#	purpose: Set active WireGuard tunnel based on cmd line param
#			 This script is meant to be non-interactive so it can be run via
#			 a phone shortcut.  Specify the number of the tunnel you would like
#			 to be the single active tunnel, examples:
#			 1 - represents the first tunnel configured in the Setup/Tunnels
#			     in the web interface
#			 2 - represents the second, etc
#            The script will set all tunnels except the one specified to the
#			 disabled state and set the specified tunnel to the enabled state
#			 before restarting WireGuard.
#
#            There is limited error checking so make sure
#			 that you understand which tunnel numbers you have in your current
#            configuration.
#
#			 You can find the output of the script in 
#			 /var/log/wireguard-set-active-tunnel.log
#	script type: standalone
#	installation:
#	 1. enable jffs2 (administration->jffs2) or use USB stick for storage with /jffs
#	 2. change to directory in which you want the script to download e.g.: cd /jffs 
#	 3. download script from github with:
#		curl -LJO https://raw.githubusercontent.com/egc112/ddwrt/main/wireguard-set-active-tunnel.sh
#		or
#		wget --no-check-certificate --content-disposition https://raw.githubusercontent.com/egc112/ddwrt/main/wireguard-set-active-tunnel.sh
#	 3. make this script executable with chmod +x /jffs/wireguard-set-active-tunnel.sh
#	 4. run from command line with/jfss/wireguard-set-active-tunnel.sh
#	 If you do not have persistent storage you can reinstall the script automatically on reboot by adding 
#	 the following to Administration > Commands and Save as Startup:
#		sleep 10
#		cd /tmp
#		curl -LJO https://raw.githubusercontent.com/egc112/ddwrt/main/wireguard-set-active-tunnel.sh
#		chmod +x wireguard-set-active-tunnel.sh
#	usage:
#	 ./wireguard-set-active-tunnel X
#	limitations:
#	 - requires dd-wrt build 52241 or later

##
[ ${DEBUG+x} ] && set -x

usage() {
    local num_tuns="$1"
    echo ""
    echo "Usage:"
    echo "  wireguard-set-active-tunnel.sh X"
    echo "  X is a single parameter with the number of the tunnel you want to enable"
    echo "  All other tunnels will be disabled"
	echo "  0 will disable all tunnels (no VPN)"
    echo "  Accepted values are 0-$num_tuns"
    exit 1
}

check_params() {
    local num_tuns="$1"
    # Check if one argument was passed to main program
    if [ "$#" -ne 2 ] || [ -z "$2" ]; then
        echo "Error: Exactly one argument is required."
        usage "$num_tuns"
    fi

	# A tunnel identifier of zero (disable VPN) is a valid param
	if [[ "$2" -eq 0 ]]; then
        return
    fi

    # Else check if the tunnel param is within the range of available tunnels
    regex="^[1-${num_tuns}]$"
    if ! echo "$2" | grep -qE "$regex"; then
        echo "Error: Your router has $num_tuns tunnels"
        echo "Your input parameter must be a number between 1 and $num_tuns."
        usage "$num_tuns"
    fi
}

set_active_tunnel() {
    local to_activate="$1"
    local num_tuns="$2"

	echo -e "\nModifying VPN Config starting: $(date)"
	if [[ "$to_activate" -eq 0 ]]; then
    	echo "Disabling all VPN tunnels..."
    else
    	echo "Enabling tunnel $to_activate, and disabling all others..."
	fi

    for iter in $(seq 1 $num_tuns); do
        if [ "$iter" -eq "$to_activate" ]; then
            echo "nvram set "oet${iter}_en=1""
            nvram set "oet${iter}_en=1"
        else
            echo "nvram set "oet${iter}_en=0""
            nvram set "oet${iter}_en=0"
        fi
    done
}

restart_firewall() {
    echo "Saving and restarting firewall..."
    nvram commit
	restart firewall
}

# This script was written to be run from a shortcut
# Log all output to /var/log
{
    nrtun="$(nvram get oet_tunnels)"
    if [[ "$nrtun" -eq 0 ]]; then
        echo "Sorry, no WireGuard VPN tunnels detected."
        exit 1
    fi
    check_params "$nrtun" "$1" || usage $nrtun
    set_active_tunnel "$1" "$nrtun"
    restart_firewall
} 2>&1 | tee -a /var/log/wireguard-set-active-tunnel.log
