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
if [ "$ID" = "debian" ] && [ "$VERSION_ID" != "9" ] && [ "$VERSION_ID" != "10" ]  && [ "$VERSION_ID" != "11" ] ; then
	echo "This script only work with Debian Stretch (9.x) or Debian Buster (10.x) or Debian Buster (11.x)"
	exit 1
elif [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" != "18.04" ] && [ "$VERSION_ID" != "19.04" ] && [ "$VERSION_ID" != "20.04" ] && [ "$VERSION_ID" != "22.04" ]; then
	echo "This script only work with Ubuntu 18.04, 19.04 or 20.04 or 22.04"
	exit 1
elif [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
	echo "This script only work with Ubuntu 18.04, Ubuntu 19.04, Ubutun 20.04,Ubutun 22.04, Debian Stretch (9.x) or Debian Buster (10.x)"
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

#clean apt
# mv /var/lib/dpkg/info  /var/lib/dpkg/info_bak
# mkdir /var/lib/dpkg/info
# apt-get update && apt-get -f install
# mv /var/lib/dpkg/info/* /var/lib/dpkg/info_bak/
# rm -rf /var/lib/dpkg/info
# mv /var/lib/dpkg/info_bak /var/lib/dpkg/info

echo "Remove lock and update packages list..."
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/cache/apt/archives/lock
apt-get update
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/cache/apt/archives/lock
apt update -y
if [ "$?" != 0 ];then
apt install dirmngr --install-recommends
gpg --keyserver  pgpkeys.mit.edu --recv-keys 648ACFD622F3D138  0E98404D386FA1D9
gpg -a --export 648ACFD622F3D138  0E98404D386FA1D9 | apt-key add -
fi
echo "Install apt-transport-https, gnupg etc"
apt-get -y install apt-transport-https gnupg mosquitto-clients

# if [ "$ID" = "debian" ] && [ "$VERSION_ID" = "9" ]; then
# 	echo "Update Debian 9 Stretch to Debian 10 Buster"
# 	apt-get -y -f --force-yes upgrade
# 	apt-get -y -f --force-yes dist-upgrade
# 	sed -i 's:stretch:buster:g' /etc/apt/sources.list
# 	apt-get update
# 	apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade
# 	apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade
# 	VERSION_ID="10"
# fi
# if [ "$ID" = "ubuntu" ] && [ "$VERSION_ID" = "18.04" ] ; then
# 	echo "Update Ubuntu 18.04 to Ubuntu 20.04"
# 	apt-get -y -f --force-yes upgrade
# 	apt-get -y -f --force-yes dist-upgrade
# 	sed -i 's:bionic:focal:g' /etc/apt/sources.list
# 	apt-get update
# 	apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" upgrade
# 	apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew" dist-upgrade
# 	VERSION_ID="20.04"
# fi


apt -y install git

if curl -s cip.cc|grep "中国";then
git clone -b english https://gitee.com/link4all_admin/vps.git
else
git clone -b english https://github.com/hewenhao2008/vps.git
fi

cd vps
sh install.sh
