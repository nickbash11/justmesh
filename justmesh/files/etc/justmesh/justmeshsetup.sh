#!/bin/sh

if [ -z $1 ]
then
	echo "Usage: $0 [hostname|network|wireless|alfred]"
	exit
fi

MESHID=justMesh
APNAME=justAP

if [ ! -d /sys/class/net/eth0 ]
then
	echo "eth0 does not exist, configuring is broken" > /justmesh
	exit
fi

if [ ! -z "$(cat /etc/openwrt_release | grep DISTRIB_RELEASE= | grep 18)" ]
then
	release=18
elif [ ! -z "$(cat /etc/openwrt_release | grep DISTRIB_RELEASE= | grep 19)" ]
then
	release=19
else
	echo "unknown version of openwrt" > /justmesh
	exit
fi

ETH_LIST=$(ls /sys/class/net/ | grep "^eth[0-9]$" 2>/dev/null)
WLAN_LIST=$(ls /sys/class/ieee80211/ 2>/dev/null)

if [[ "$1" == "hostname" ]]
then
	cat /sys/class/net/eth0/address | awk -F":" '{print "node-"$5$6}'
elif [[ "$1" == "network" ]]
then
	function PoorMansRandomGenerator {
		local digits="${1}" # The number of digits to generate
		local number

		# Some read bytes can't be used, se we read twice the number of required bytes
		dd if=/dev/urandom bs=$digits count=2 2> /dev/null | while read -r -n1 char
		do
			number=$number$(printf "%d" "'$char")
			if [ ${#number} -ge $digits ]
			then
				echo ${number:0:$digits}
				break;
			fi
		done
	}

	switch=$(swconfig list | awk '{print $2}')

	if [[ ! -z ${switch} ]]
	then
		ports_count=$(swconfig dev ${switch} show | grep Port | wc -l)
		count=$(seq -s " " 0 $(( ${ports_count} -1 )))

		echo "config switch" 
		echo "	option name '${switch}'"
		echo "	option reset '1'"
		echo "	option enable_vlan '1'"
		echo ""
		echo "config switch_vlan"
		echo "	option device '${switch}'"
		echo "	option vlan '1'"
		echo "	option ports '${count}'"
		echo ""
	fi

	while [ true ]
	do
		octet2=$(PoorMansRandomGenerator 3 | sed 's/^0*//')
		if [ $octet2 -le 255 ]
		then
			break;
		fi
	done

	while [ true ]
	do
		octet3=$(PoorMansRandomGenerator 3 | sed 's/^0*//')
		if [ $octet3 -le 255 ]
		then
			break;
		fi
	done

	echo "config interface 'loopback'"
	echo "	option ifname 'lo'"
	echo "	option proto 'static'"
	echo "	option ipaddr '127.0.0.1'"
	echo "	option netmask '255.0.0.0'"
	echo ""
	echo "config interface 'mesh'"
	echo "	option ifname 'bat0'"
	echo "	option proto 'static'"
	echo "	option ipaddr '10.${octet2}.${octet3}.1'"
	echo "	option netmask '255.0.0.0'"
	echo ""
	echo "config interface 'lan'"
	echo "	option type 'bridge'"
	echo "	option ifname 'eth0'"
	echo "	option proto 'static'"
	echo "	option ipaddr '10.${octet2}.${octet3}.1'"
	echo "	option netmask '255.255.255.224'"
	echo "	option dns '208.67.222.222 208.67.220.220'"
	echo "	option ip6assign '60'"
	echo ""

	for ethif in $ETH_LIST
	do
		echo "config device '${ethif}_mtu1536'"
		echo "	option name '${ethif}'"
		echo "	option mtu '1536'"
		echo ""
		echo "config device '${ethif}_20'"
		echo "	option type '8021ad'"
		echo "	option name '${ethif}_20'"
		echo "	option ifname '${ethif}'"
		echo "	option vid '20'"
		echo ""

		if [[ "$release" == 19 ]]
		then
			echo "config interface 'bat0_hardif_${ethif}_20'"
			echo "	option ifname '${ethif}_20'"
			echo "	option proto 'batadv_hardif'"
			echo "	option master 'bat0'"
			echo ""
		else
			echo "config interface 'bat0_hardif_${ethif}_20'"
			echo "	option ifname '${ethif}_20'"
			echo "	option proto 'batadv'"
			echo "	option mesh 'bat0'"
			echo ""
		fi
	done

	i=0
	for wlanif in $WLAN_LIST
	do

		while [ true ]
		do
			octet=$(PoorMansRandomGenerator 3 | sed 's/^0*//')
			if [ $octet -le 255 ]
			then
				break;
			fi
		done

		echo "config interface 'mesh_w${i}'"
		echo "	option proto 'static'"
		echo "	option ipaddr '169.254.${octet}.1'"
		echo "	option netmask '255.255.255.248'"
		echo "	option mtu '1536'"
		echo ""
		echo "config device 'wlan${i}_20'"
		echo "	option type '8021q'"
		echo "	option name 'wlan${i}_20'"
		echo "	option ifname '@mesh_w${i}'"
		echo "	option vid '20'"
		echo ""

		if [[ "$release" == 19 ]]
		then
			echo "config interface 'bat0_hardif_wlan${i}_20'"
			echo "	option ifname 'wlan${i}_20'"
			echo "	option proto 'batadv_hardif'"
			echo "	option master 'bat0'"
			echo ""
		else
			echo "config interface 'bat0_hardif_wlan${i}_20'"
			echo "	option ifname 'wlan${i}_20'"
			echo "	option proto 'batadv'"
			echo "	option mesh 'bat0'"
			echo ""
		fi

		i=$(( ${i} +1 ))
	done

	if [[ "$release" == 19 ]]
	then
		echo "config interface 'bat0'"
		echo "	option proto 'batadv'"
		echo "	option bridge_loop_avoidance '1'"
		echo ""
	fi

elif [[ "$1" == "wireless" ]]
then
	i=0
	for phy in $WLAN_LIST
	do
		echo "config wifi-device 'radio${i}'"
		echo "	option type 'mac80211'"
		echo "	option macaddr '$(cat /sys/class/ieee80211/phy${i}/macaddress)'"

		if [ ! -z "$(iw phy phy${i} info | grep '5180 MHz')" ]
		then
			echo "	option channel '36'"
			echo "	option hwmode '11a'"
			if [ ! -z "$(iw phy phy${i} info | grep 'VHT Capabilities')" ]
			then
				echo "	option htmode 'VHT80'"
			fi
		else
			echo "	option channel '6'"
			if [ ! -z "$(iw phy phy${i} info | grep "HT20/HT40")" ]
			then
				echo "	option hwmode '11n'"
				echo "	option htmode 'HT40+'"
			else
				echo "	option hwmode '11g'"
			fi
		fi

		echo "	option txpower '20'"
		echo "	option noscan '1'"
		echo "	option distance '1000'"
		echo "	option disabled '0'"
		echo ""

		i=$(( ${i} +1 ))
	done

	i=0
	for wlanif in $WLAN_LIST
	do
		echo "config wifi-iface 'wlan${i}'"
		echo "	option device 'radio${i}'"
		echo "	option mode 'mesh'"
		echo "	option mesh_id '$MESHID'"
		echo "	option network 'mesh_w${i}'"
		echo "	option ifname 'wlan${i}'"
		echo "	option mesh_fwding '0'"
		echo ""

		if [ $i -eq 0 ]
		then
			echo "config wifi-iface 'wlan${i}ap'"
			echo "	option device 'radio${i}'"
			echo "	option network 'lan'"
			echo "	option ifname 'wlan${i}ap'"
			echo "	option mode 'ap'"
			echo "	option ssid '$APNAME'"
			echo "	option encryption 'none'"
			echo ""
		fi

		i=$(( ${i} +1 ))
	done
elif [[ "$1" == "alfred" ]]
then
	echo "config 'alfred' 'alfred'"
	echo "	option interface 'bat0'"
	echo "	option mode 'master'"
	echo "	option batmanif 'bat0'"
	echo "	option start_vis '0'"
	echo "	option run_facters '0'"
	echo ""
else
	echo "Usage: $0 [hostname|network|wireless|alfred]"
fi
