#!/bin/bash

# Directories to watch
NGINX_CONF_DIR="/etc/nginx/sites-available"
DNS_ZONES_DIR="/etc/bind/zones"
SYSTEMD_DIR="/etc/systemd/system"
OPENADMIN_DIR="/usr/local/admin"
WATCHER_DIR="/usr/local/admin/scripts/watcher"

# Function to check if inotifywait is installed and install it if necessary
check_and_install_inotifywait() {
  if ! command -v inotifywait &> /dev/null; then
    echo "inotifywait not found. Installing inotify-tools..."
    sudo apt-get update
    sudo apt-get install -y inotify-tools
    if [ $? -ne 0 ]; then
      echo "Failed to install inotify-tools. Exiting."
      exit 1
    fi
  fi
}

# Nginx
reload_nginx() {
  nginx -t
  if [ $? -eq 0 ]; then
    echo "$(date): Detected Nginx Configuration Change"
    echo "$(date): Executing: nginx -s reload"
    nginx -s reload
  else
    echo "$(date): Nginx configuration test failed"
  fi
}

# Named
reload_dns() {
  local zone_file="$1"
  local zone_name="$(basename "$zone_file" .zone)"
  echo "$(date): Detected DNS Zone Change in $zone_file"
  echo "$(date): Checking DNS configuration for $zone_name"

  named-checkzone "$zone_name" "$zone_file"
  if [ $? -eq 0 ]; then
    echo "$(date): DNS configuration test passed for $zone_name"
    echo "$(date): Reloading DNS zone $zone_name"
    rndc reload "$zone_name"
  else
    echo "$(date): DNS configuration test failed for $zone_name"
    echo "$(date): Not reloading DNS zone $zone_name"
  fi
}


# systemd
reload_systemd() {
  echo "$(date): Detected change in $SYSTEMD_DIR"
  echo "$(date): Running: systemctl daemon-reload"
  systemctl daemon-reload
  if [ $? -ne 0 ]; then
    echo "$(date): systemctl daemon-reload failed"
  fi
}

# OpenAdmin
reload_openadmin() {
  echo "$(date): Detected change in $OPENADMIN_DIR"
  echo "$(date): Running: service admin reload"
  service admin reload
  if [ $? -ne 0 ]; then
    echo "$(date): service admin reload failed"
  fi
}

# watcher itself
reload_watcher() {
  echo "$(date): Detected change in $WATCHER_DIR"
  echo "$(date): Running: service watcher restart"
  service watcher restart
  if [ $? -ne 0 ]; then
    echo "$(date): service watcher restart failed"
  fi
}

# Check and install inotifywait if necessary
check_and_install_inotifywait

# Main loop
while true; do
  echo "Waiting for changes in $NGINX_CONF_DIR or $DNS_ZONES_DIR..."
  inotifywait --exclude .swp -e create -e modify -e delete -e move "$NGINX_CONF_DIR" "$DNS_ZONES_DIR"
  
  CHANGED_FILES=$(inotifywait --exclude .swp -e create -e modify -e delete -e move --format '%w%f' "$NGINX_CONF_DIR" "$DNS_ZONES_DIR")

  for FILE in $CHANGED_FILES; do
    echo "Change detected in: $FILE"
    if [[ "$FILE" == "$NGINX_CONF_DIR"* ]]; then
      reload_nginx
    elif [[ "$FILE" == "$DNS_ZONES_DIR"*.zone ]]; then
      reload_dns "$FILE"
    elif [[ "$FILE" == "$SYSTEMD_DIR"* ]]; then
      reload_systemd
    elif [[ "$FILE" == "$WATCHER_DIR"* ]]; then
      reload_watcher
    elif [[ "$FILE" == "$OPENADMIN_DIR"* ]]; then
      reload_openadmin
    fi
  done
done
