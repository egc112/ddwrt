#!/bin/sh
#DEBUG=; set -x # comment/uncomment to disable/enable debug mode

#	name: wireguard-toggle.sh
#	version: 0.5 beta, 6-dec-2023, by egc
#	purpose: 
#	script type: standalone
#	installation:
#	 1. enable jffs2 (administration->jffs2) or use USB stick for storage with /jffs
#	 2. change to direcdtory in which you want the script to download e.g.: cd /jffs 
#	 3. download script from github with:
#		curl -LJO https://raw.githubusercontent.com/egc112/ddwrt/main/wireguard-toggle.sh
#		or
#		wget --no-check-certificate --content-disposition https://raw.githubusercontent.com/egc112/ddwrt/main/wireguard-toggle.sh
#	 3. make this script executable with chmod +x /jffs/wireguard-toggle.sh
#	 4. run from command line with/jfss/wireguard-toggle.sh
#	usage:
#	 toggle tunnels to enable/disable the tunnel and restart wireguard
#	limitations:
#    	 - requires dd-wrt build 52241 or later

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
	echo -ne $green$1$clear
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

WrongCommand () {
	#do nothing
	menu
}

toggle_confirm(){
	[[ $2 -eq 0 ]] && state="${red}disable${clear}" || state="${green}enable${clear}"
	echo -e -n "\tAre you sure you want to ${state} tunnel ${yellow}$1${clear}: y/n ? : "
	read  y_or_n
	if [[ "$y_or_n" = "Y" || "$y_or_n" = "y" ]]; then
		#echo -e " Toggle tunnel $1"
		nvram set oet${1}_en=$2
		return 0
	else
		echo -e "Abort"
		menu
	fi
}

toggle_tunnel(){
	tstate=$(nvram get oet${1}_en)
	if [[ $tstate -eq 0 ]]; then
		toggle_confirm $1 1
		echo -e "\tTunnel $1 will be ${green}enabled${clear} after Restart"
		menu
	elif [[ $tstate -eq 1 ]]; then
		toggle_confirm $1 0
		echo -e "\tTunnel $1 will be ${red}disabeld${clear} after Restart"
		menu
	else
		echo -e $red"\tTunnel $1 does not exist"$clear Please choose an existing tunnel; return 1
	fi
	return 0
}

show_tunnels(){
	for oet in $(nvram show 2>/dev/null | sed -n  '/oet._en=./p' | sed 's/_en//g' | sort) ; do 
		oetid=${oet%??}
		[[ ! -z ${oetid}_label ]] && oetname=$(nvram get ${oetid}_label)
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
		echo -e "\ttunnel $(ColorYellow $oetid) $state $fstaten $(ColorBlue $oetname)" 
	done
	#echo -e ""
}

submenu_toggle () {
	show_tunnels
	echo -ne "
	$(ColorYellow 'Please enter the tunnel number you want to toggle, 0=Exit': ) "
	read tn
	if  [[ $tn -eq 0 ]]; then
		echo -e "\tReturning to main menu"
		return 0
	elif [[ $tn -gt 0 && $tn -lt 20 ]] ; then
		echo -e "\tYou chose tunnel number $tn"
		toggle_tunnel $tn
		return 0
	else
		echo -e $red"\t\nWrong option."$clear; return 1
	fi
}

menu(){
	echo -e "\n\tWireGuard tunnels with number, state, fail_state and label\n"
	show_tunnels
	echo -ne "
	WireGuard toggle script to enable/disable tunnels from the command line
	$(ColorGreen '1)') Showtunnels
	$(ColorGreen '2)') Toggle
	$(ColorGreen '7)') Save, Restart WireGuard
	$(ColorGreen '8)') Save, Restart WireGuard and whole Firewall, this will temporarily suspend services!
	$(ColorGreen '9)') Save, Reboot Router
	$(ColorGreen '0)') Exit
	$(ColorBlue 'Choose an option:') "
	read a
	case $a in
		"1"|"" )
			menu
			;;
		2 )
			echo -e "\tYou chose main item 2, Toggle tunnel\n"
			submenu_toggle
			menu
			;;
		7 )
			echo -e -n "\tAre you sure to save changes and restart WireGuard y/n ?: "
			read y_or_n
			if [[ "$y_or_n" = "Y" || "$y_or_n" = "y" ]]; then
				echo -e "\tSaving and Restarting"
				nvram commit
				/usr/bin/wireguard-restart.sh
			else
				echo -e "\tABORT"
			fi
			menu
			;;
		8 )
			echo -e -n "\tAre you sure to save changes and restart WireGuard and the whole Firewall y/n ?: "
			read y_or_n
			if [[ "$y_or_n" = "Y" || "$y_or_n" = "y" ]]; then
				echo -e "\tSaving and Restarting Firewall"
				nvram commit
				restart firewall
			else
				echo -e "\tABORT"
			fi
			menu
			;;
		9 )
			echo -e -n "\tAre you sure you want to Reboot y/n ?: "
			read y_or_n
			if [[ "$y_or_n" = "Y" || "$y_or_n" = "y" ]]; then
				echo -e "\tRebooting, Bye Bye"
				nvram commit
				/sbin/reboot
			else
				echo -e "\tABORT"
			fi
			menu
			;;
		0 ) exit 0 ;;
		*) echo -e $red"\tWrong option."$clear; WrongCommand;;
	esac
}

menu
