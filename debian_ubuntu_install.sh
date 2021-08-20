#!/bin/sh

set -e
umask 0022
export LC_ALL=C
export PATH=$PATH:/sbin
export DEBIAN_FRONTEND=noninteractive 

echo "Check user..."
if [ "$(id -u)" -ne 0 ]; then echo 'Please run as root.' >&2; exit 1; fi

# Check Linux version
echo "Check Linux version..."
if test -f /etc/os-release ; then
	. /etc/os-release
else
	. /usr/lib/os-release
fi
if [ "$ID" = "debian" ] && [ "$VERSION_ID" != "9" ] && [ "$VERSION_ID" != "10" ]; then
	echo "This script only work with Debian Stretch (9.x) or Debian Buster (10.x)"
	exit 1
elif [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" != "18.04" ] && [ "$VERSION_ID" != "19.04" ] && [ "$VERSION_ID" != "20.04" ]; then
	echo "This script only work with Ubuntu 18.04, 19.04 or 20.04"
	exit 1
elif [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
	echo "This script only work with Ubuntu 18.04, Ubuntu 19.04, Ubutun 20.04, Debian Stretch (9.x) or Debian Buster (10.x)"
	exit 1
fi

echo "Check architecture..."
ARCH=$(dpkg --print-architecture | tr -d "\n")
if [ "$ARCH" != "amd64" ]; then
	echo "Only x86_64 (amd64) is supported"
	exit 1
fi

echo "Check virtualized environment"
VIRT="$(systemd-detect-virt 2>/dev/null || true)"
if [ -z "$(uname -a | grep mptcp)" ] && [ -n "$VIRT" ] && ([ "$VIRT" = "openvz" ] || [ "$VIRT" = "lxc" ] || [ "$VIRT" = "docker" ]); then
	echo "Container are not supported: kernel can't be modified."
	exit 1
fi

# Check if DPKG is locked and for broken packages
#dpkg -i /dev/zero 2>/dev/null
#if [ "$?" -eq 2 ]; then
#	echo "E: dpkg database is locked. Check that an update is not running in background..."
#	exit 1
#fi
echo "Check about broken packages..."
apt-get check >/dev/null 2>&1
if [ "$?" -ne 0 ]; then
	echo "E: \`apt-get check\` failed, you may have broken packages. Aborting..."
	exit 1
fi



echo "Remove lock and update packages list..."
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/cache/apt/archives/lock
apt-get update
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/cache/apt/archives/lock
apt update -y
echo "Install apt-transport-https, gnupg etc"
apt-get -y install apt-transport-https gnupg 

if [ "$ID" = "debian" ] && [ "$VERSION_ID" = "9" ]; then
	echo "Update Debian 9 Stretch to Debian 10 Buster"
	apt-get -y -f --force-yes upgrade
	apt-get -y -f --force-yes dist-upgrade
	sed -i 's:stretch:buster:g' /etc/apt/sources.list
	apt-get update
	apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade
	apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade
	VERSION_ID="10"
fi
if [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" = "18.04" ] && [ "$UPDATE_OS" = "yes" ]; then
	echo "Update Ubuntu 18.04 to Ubuntu 20.04"
	apt-get -y -f --force-yes upgrade
	apt-get -y -f --force-yes dist-upgrade
	sed -i 's:bionic:focal:g' /etc/apt/sources.list
	apt-get update
	apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade
	apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade
	VERSION_ID="20.04"
fi


apt -y install git

git clone https://gitee.com/link4all_admin/vps.git

cd vps
sh install.sh