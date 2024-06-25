#!/bin/bash
#################################################################
# 
# To install, simply run this command:
#
# bash <(curl -sSL https://raw.githubusercontent.com/stefanpejcic/file-watcher/main/install.sh)
#
#################################################################

mkdir -p /usr/local/admin/scripts/

git clone https://github.com/stefanpejcic/file-watcher /usr/local/admin/scripts/watcher

chmod +x /usr/local/admin/scripts/watcher/watcher.sh
cp /usr/local/admin/scripts/watcher/watcher.service /etc/systemd/system/watcher.service

systemctl daemon-reload
systemctl enable watcher.service
systemctl start watcher.service

#systemctl status watcher.service
