#!/bin/sh
#DEBUG=; set -x # comment/uncomment to disable/enable debug mode

#	name: wireguard-companion.sh
#	version: 0.92 beta, 14-dec-2023, by egc
#	purpose: Toggle WireGuard tunnels on/off, show status and log
#	script type: standalone
#	installation:
#	 1. enable jffs2 (administration->jffs2) or use USB stick for storage with /jffs
#	 2. change to directory in which you want the script to download e.g.: cd /jffs 
#	 3. download script from github with:
#		curl -LJO https://raw.githubusercontent.com/egc112/ddwrt/main/wireguard-companion.sh
#		or
#		wget --no-check-certificate --content-disposition https://raw.githubusercontent.com/egc112/ddwrt/main/wireguard-companion.sh
#	 3. make this script executable with chmod +x /jffs/wireguard-companion.sh
#	 4. run from command line with /jfss/wireguard-companion.sh, most SSH clients will let you run a command on connection
#	 If you do not have persistent storage you can reinstall the script automatically on reboot by adding 
#	 the following to Administration > Commands and Save as Startup:
#		sleep 10
#		cd /tmp
#		curl -LJO https://raw.githubusercontent.com/egc112/ddwrt/main/wireguard-companion.sh
#		chmod +x wireguard-companion.sh
#	usage:
#	 toggle tunnels to enable/disable the tunnel and restart wireguard
#	limitations:
#	 - requires dd-wrt build 52241 or later

[ ${DEBUG+x} ] && set -x
# Color  Variables
##
green='\e[92m'
blue='\e[96m'
red='\e[91m'
yellow='\e[93m'
clear='\e[0m'
##
# Color Functions
##
ColorGreen(){
	echo -ne "$green$1$clear"
}
ColorBlue(){
	echo -ne $blue$1$clear
}
ColorYellow(){
	echo -ne $yellow$1$clear
}
ColorRed(){
	echo -ne $red$1$clear
}
##
nrtun="$(nvram get oet_tunnels)"

WrongCommand () {
	#do nothing
	menu
}

toggle_confirm(){
	[[ $2 -eq 0 ]] && state="${red}disable${clear}" || state="${green}enable${clear}"
	echo -e -n "  Do you want to ${state} tunnel ${yellow}$1${clear}: y/N ? : "
	read -n 1 y_or_n
	if [[ "$y_or_n" = "Y" || "$y_or_n" = "y" ]]; then
		#echo -e " Toggle tunnel $1"
		nvram set oet${1}_en=$2
		return 0
	else
		echo -e "Abort"
		menu
	fi
}

any_key(){
	read -n 1 -s -r -p "  Press any key to continue"
	return 0
}

toggle_tunnel(){
	tstate=$(nvram get oet${1}_en)
	if [[ $tstate -eq 0 ]]; then
		toggle_confirm $1 1
		echo -e "\n  Tunnel $1 will be ${green}enabled${clear} after Restart"
		echo -e "  ${yellow}To execute, Restart WireGuard or router!${clear}"
		any_key
		return 0
	elif [[ $tstate -eq 1 ]]; then
		toggle_confirm $1 0
		echo -e "\n  Tunnel $1 will be ${red}disabled${clear} after Restart"
		echo -e "  ${yellow}To execute, Restart WireGuard or router!${clear}"
		any_key
		return 0
	else
		echo -e $red"  Tunnel $1 does not exist"$clear Please choose an existing tunnel 
		return 1
	fi
	return 0
}

show_tunnels(){
	for oet in $(nvram show 2>/dev/null | sed -n  '/oet._en=./p' | sed 's/_en//g' | sort) ; do 
		oetid=${oet%??}
		[[ ! -z ${oetid}_label ]] && oetname="$(nvram get ${oetid}_label)"
		oetval=${oet: -1}
		[[ $oetval -eq 1 ]] && state=$(ColorGreen 'enabled ') || state=$(ColorRed 'disabled')
		if [[ $oetval -eq 1 ]]; then
			fstate="$(nvram get ${oetid}_failstate)"
			case $fstate in
			  0 ) [[ $(nvram get ${oetid}_failgrp) -eq 1 ]] && fstaten="$(ColorYellow standby)" || fstaten="$(ColorGreen running)" ;;
			  1 ) fstaten="${red}failed ${clear}" ;;
			  2 ) fstaten="${yellow}running${clear}" ;;
			  * ) fstaten="       " ;;
			esac
		else
			fstaten="       "
		fi
		echo -e "  tunnel $(ColorYellow $oetid) $state $fstaten $(ColorBlue $oetname)" 
	done
	#echo -e ""
}

submenu_showstatus(){
	show_tunnels
	echo -ne "\n  $(ColorYellow 'Please enter tunnel you want to see, 0=Exit': ) "
	[[ "$nrtun" -lt 10 ]] && read -n 1 sn || read sn # use this with more than 10 tunnels
	if  [[ $sn -eq 0 ]]; then
		echo -e "  Returning to main menu"
		return 0
	elif [[ $sn -gt 0 && $sn -le $nrtun ]] ; then
		echo -e "\n  ${blue}Status of${clear} ${yellow}oet${sn}${clear}:"
		stat="$(/usr/bin/wireguard-state.sh $sn 0 2>/dev/null)"
		[[ -z "$stat" ]] && stat="  No connection present for oet${sn}"
		echo -e "$stat"
		any_key
		return 0
	else
		echo -e $red"\n  Wrong option, choose valid tunnel!"$clear; submenu_showstatus
	fi
}

submenu_toggle(){
	show_tunnels
	echo -ne "\n  ${yellow}Please enter tunnel to toggle (1 - $nrtun, 0=Exit):${clear} "
	[[ "$nrtun" -lt 10 ]] && read -n 1 tn || read tn # use this with more than 10 tunnels
	if  [[ $tn -eq 0 ]]; then
		echo -e "\n  Returning to main menu"
		return 0
	elif [[ $tn -gt 0 && $tn -le $nrtun ]] ; then
		echo -e "\n  You chose tunnel number $tn"
		toggle_tunnel $tn
		if [[ "$1" -eq 1 ]]; then
			echo -e -n "\n  Disable all other tunnels y/N?: "
			read -n 1 y_or_n
			if [[ "$y_or_n" = "Y" || "$y_or_n" = "y" ]]; then
				for x in $(seq 1 $nrtun); do
					[[ $x -eq $tn ]] && continue
					nvram set oet${x}_en=0
					echo -e "  ${yellow}To execute, Restart WireGuard or router!${clear}"
					any_key
				done
			fi
		fi
		return 0
	else
		echo -e $red"\n  Wrong option, choose valid tunnel!"$clear; submenu_toggle
	fi
}

menu(){
	clear
	echo -e "\n        number state fail_state label"
	show_tunnels
	echo -e -n "
  WireGuard toggle script to enable/disable tunnels
  $(ColorGreen '1)') Showtunnels/Refresh
  $(ColorGreen '2)') Toggle tunnel
  $(ColorGreen '3)') Enable tunnel, Disable all others
  $(ColorGreen '4)') Show Status
  $(ColorGreen '5)') Show WireGuard Log
  $(ColorGreen '7)') Save, Restart WireGuard
  $(ColorGreen '8)') Save, Restart WireGuard and whole Firewall
  $(ColorGreen '9)') Save, Reboot Router
  $(ColorGreen '0)') Exit
  $(ColorBlue 'Choose an option:') "
	read -n 1 a
	case $a in
		"1"|"" )
			menu
			;;
		2 )
			echo -e "  You chose Toggle tunnel\n"
			submenu_toggle 0
			menu
			;;
		3 )
			echo -e "  You chose Enable tunnel, Disable all others\n"
			submenu_toggle 1
			menu
			;;
		4 )
			echo -e "  You chose item 4, Show Status\n"
			submenu_showstatus
			menu
			;;
		5 )
			#echo -e "  You chose main item 5, Show WireGuard Log\n"
			grep -i -E 'oet|wireguard|eop' /var/log/messages
			any_key
			menu
			;;
		7 )
			echo -e -n "\n  Save changes and restart WireGuard y/N?: "
			read -n 1 y_or_n
			if [[ "$y_or_n" = "Y" || "$y_or_n" = "y" ]]; then
				echo -e "\n  Saving and Restarting"
				nvram commit
				/usr/bin/wireguard-restart.sh
			else
				echo -e "  ABORT"
			fi
			any_key
			menu
			;;
		8 )
			echo -e -n "\n  Save changes restart WireGuard and Firewall y/N?: "
			read -n 1 y_or_n
			if [[ "$y_or_n" = "Y" || "$y_or_n" = "y" ]]; then
				echo -e "\n  Saving and Restarting Firewall"
				nvram commit
				restart firewall
			else
				echo -e "  ABORT"
			fi
			any_key
			menu
			;;
		9 )
			echo -e -n "\n  Are you sure you want to Reboot y/N?: "
			read -n 1 y_or_n
			if [[ "$y_or_n" = "Y" || "$y_or_n" = "y" ]]; then
				echo -e "\n  Rebooting, Bye Bye"
				nvram commit
				/sbin/reboot
				exit 0
			else
				echo -e "  ABORT"
				any_key
			fi
			menu
			;;
		0 ) echo -e "\n  Thanks for using wireguard-companion.sh"; exit 0 ;;
		*) echo -e $red"  Wrong option."$clear; WrongCommand;;
	esac
}

clear
menu
