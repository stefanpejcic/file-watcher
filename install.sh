#!/bin/bash
#################################################################
# 
# To install, simply run this command:
#
# git clone https://github.com/stefanpejcic/file-watcher /usr/local/admin/scripts/watcher && bash /usr/local/admin/scripts/watcher/install.sh
#
#################################################################

mkdir -p /usr/local/admin/scripts/
cp /usr/local/admin/scripts/watcher/watcher.service /etc/systemd/system/watcher.service

systemctl daemon-reload
systemctl enable watcher.service
systemctl start watcher.service

#systemctl status watcher.service
