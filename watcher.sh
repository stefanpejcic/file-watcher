#!/bin/bash

# Directories to watch
NGINX_CONF_DIR="/etc/nginx/sites-available"
DNS_ZONES_DIR="/etc/bind/zones"

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

# Function to reload Nginx
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

# Function to reload a DNS zone
reload_dns() {
  local zone_file="$1"
  local zone_name="$(basename "$zone_file" .zone)"
  echo "$(date): Detected DNS Zone Change in $zone_file"
  echo "$(date): Executing: rndc reload $zone_name"
  rndc reload "$zone_name"
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
    fi
  done
done
