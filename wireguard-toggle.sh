#!/bin/sh
#DEBUG=; set -x # comment/uncomment to disable/enable debug mode

#	name: wireguard-toggle.sh
#	version: 0.4 beta, 5-dec-2023, by egc
#	purpose: 
#	script type: standalone
#	 1. enable jffs2 (administration->jffs2) or use USB stick for storage with /jffs
#	 2. download script from
#	 3. make this script executable with chmod +x /jffs/wireguard-toggle.sh
#	 4. run from command line with/jfss/wireguard-toggle.sh
#	limitations:
#    - requires dd-wrt build 52241 or later


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
		echo -e "\tTunnel $1 is now ${green}enabled${clear}"
		menu
	elif [[ $tstate -eq 1 ]]; then
		toggle_confirm $1 0
		echo -e "\tTunnel $1 is now ${red}disabeld${clear}"
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
		echo -e $red"\tWrong option."$clear; return 1
	fi
}

menu(){
	echo -e "\n\tWireGuard tunnels with number, state and label\n"
	show_tunnels
	echo -ne "
	WireGuard toggle script to enable/disable tunnels from the command line
	$(ColorGreen '1)') Showtunnels
	$(ColorGreen '2)') Toggle
	$(ColorGreen '9)') Save, Restart WireGuard
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
		9 )
			echo -e -n "\tAre you sure to save changes and restart Wireguard y/n ?: "
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
		0 ) exit 0 ;;
		*) echo -e $red"\tWrong option."$clear; WrongCommand;;
	esac
}

menu

