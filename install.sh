#!/bin/sh

#wget http://www.mine.com.cn/dl/install.tar.gz

# if grep 'DVD Binary' /etc/apt/sources.list;then
# sed  -i '/DVD Binary/d' /etc/apt/sources.list
# cat << EOF >> /etc/apt/sources.list
# deb http://mirrors.163.com/debian/ buster main non-free contrib
# deb http://mirrors.163.com/debian/ buster-updates main non-free contrib
# deb http://mirrors.163.com/debian/ buster-backports main non-free contrib
# deb http://mirrors.163.com/debian-security/ buster/updates main non-free contrib
# deb-src http://mirrors.163.com/debian/ buster main non-free contrib
# deb-src http://mirrors.163.com/debian/ buster-updates main non-free contrib
# deb-src http://mirrors.163.com/debian/ buster-backports main non-free contrib
# deb-src http://mirrors.163.com/debian-security/ buster/updates main non-free contrib
# EOF
# fi

# tar zxvf install.tar.gz
apt update
apt -y install pkg-config libpcre3-dev libmbedtls-dev libsodium-dev libc-ares-dev libev-dev  libtool automake make autoconf iperf3 ntp net-tools psmisc git python3-pip gcc
pip3 install speedtest-cli
dpkg -i linux-headers_amd64.deb
dpkg -i linux-image_amd64.deb
dpkg -i linux-libc-dev_amd64.deb


kernel0=$(grep  -e submenu /boot/grub/grub.cfg|cut -d"'" -f2)
kernel1=$(grep  -e menuentry /boot/grub/grub.cfg|grep 5.4.178|cut -d"'" -f2|head -n1)
if [ -n "$kernel1" ];then
	# sed -i "s/GRUB_DEFAULT=.*/GRUB_DEFAULT=\"$kernel0\>$kernel1\"/" /etc/default/grub
	sed -i "s#GRUB_DEFAULT=.*#GRUB_DEFAULT=\"$kernel0>$kernel1\"#" /etc/default/grub
fi
update-grub

cd shadowsocks-libev-3.3.5/
./autogen.sh
./configure --disable-documentation 
make 
cp src/ss-server /bin/
cd ../
cp ./etc / -r
cp .usr/bin/* /usr/bin -rf

update-rc.d ss-server defaults
update-rc.d iperf3 defaults

#change iptable
apt-get install iptables-persistent
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

rm -rf linux-headers_amd64.deb linux-image_amd64.deb linux-libc-dev_amd64.deb shadowsocks-libev-3.3.5/ /etc/sysctl.d/custom.conf


# tar zxvf openvpnconf.tar.gz -C /
cp ./etc/ / -r
echo "Install OpenVPN"
rm -f /var/lib/dpkg/lock
rm -f /var/lib/dpkg/lock-frontend
rm -f /lib/systemd/network/openvpn.network
apt-get -y install openvpn easy-rsa

systemctl enable openvpn@server
systemctl enable openvpn
systemctl enable openvpn-server@server
systemctl start openvpn-server@server
systemctl enable showip.service
systemctl start showip.service

if grep -q '^nameserver 127.0.0.53' "/etc/resolv.conf"; then
	resolv_conf="/run/systemd/resolve/resolv.conf"
else
	resolv_conf="/etc/resolv.conf"
fi
# Obtain the resolvers from resolv.conf and use them for OpenVPN
sed -i '/dhcp-option DNS/d' /etc/openvpn/server/server.conf
sed -i '/dhcp-option DNS/d' /etc/openvpn/server.conf

grep -v '^#\|^;' "$resolv_conf" | grep '^nameserver' | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | while read line; do
	echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server/server.conf
	echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server.conf
done

ethname=`route -n |grep "^0.0.0.0"|head -n1 |awk '{print $8}'`
sed -i 's/eth0/'$ethname'/g' /etc/iptables/rules.v4
sed -i 's/eth0/'$ethname'/g' /etc/iptables/rules.v6
#安装 x-ui
bash x-ui-install.sh

apt install libssl-dev -f
git clone https://gitee.com/link4all_admin/chipvpn.git
cd chipvpn
make
cp bin/chipvpn /usr/bin/tcpvpn
cp server.json /etc/
cd ../
rm -rf chipvpn
update-rc.d tcpvpn defaults
bash x-ui-install.sh
rm -rf ../vps


if curl -s cip.cc|grep "中国";then
sed -i 's/4443/443/g' /etc/config.json
echo "Success, please allow TCP ports 443, 60011 (for network bonding) and 3389 (for speedtest), reboot the server by 'reboot' command ."
else
sed -i 's/4443/59999/g' /etc/config.json
echo "Success, please allow TCP ports 59999, 60011 (for network bonding) and 3389 (for speedtest), reboot the server by 'reboot' command ."
fi

# reboot


