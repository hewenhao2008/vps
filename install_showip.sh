#!/bin/sh

git clone -b english https://gitee.com/link4all_admin/vps.git

cp vps/usr/bin/showip  /usr/bin/showip
cp vps/etc/systemd/system/showip.service /etc/systemd/system/showip.service

systemctl enable showip.service
systemctl start showip.service

