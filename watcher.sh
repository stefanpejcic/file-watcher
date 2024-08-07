#!/bin/bash

# Directories to watch
NGINX_CONF_DIR="/etc/nginx/sites-available"
DNS_ZONES_DIR="/etc/bind/zones"
USERS_DIR="/etc/openpanel/openpanel/core/users" # todo, exclude dot files and watch only for folder, not files in them!

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


# Extract domain name from file name without .conf suffix
extract_domain_name() {
  local filename="$1"
  local domain_name=$(basename "$filename" .conf)
  echo "$domain_name"
}

# Nginx
reload_nginx() {
  local file="$1"
  local event="$2"


  echo "$(date): Detected Nginx Configuration Change"
  
  if [[ "$event" == "CREATE" ]]; then
    # Extract domain name from file name (without .conf suffix)
    local domain_name=$(extract_domain_name "$file")
    echo "$(date): New domain added: $domain_name - starting SSL generation.."
    generate_ssl "$domain_name"
  fi

  nginx -t
  if [ $? -eq 0 ]; then

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


# phpMyAdmin for OpenPanel users
reload_phpmyadmin() {
  echo "$(date): Detected change in $USERS_DIR"
  echo "$(date): Running: opencli phpmyadmin --enable"
  opencli phpmyadmin --enable
  if [ $? -ne 0 ]; then
    echo "$(date): 'opencli phpmyadmin --enable' failed"
  fi
}

# opencli ssl-domain <DOMAIN_NAME>
generate_ssl() {
  local domain_name="$1"
  echo "$(date): Generating SSL certificate for domain $domain_name"
  opencli ssl-domain "$domain_name"
  if [ $? -eq 0 ]; then
    echo "$(date): SSL certificate generated successfully for $domain_name"
  else
    echo "$(date): Failed to generate SSL certificate for $domain_name"
  fi
}


# Check and install inotifywait if necessary
check_and_install_inotifywait

mkdir -p /etc/bind/zones


# --exclude "$USERS_DIR/.*/.*"

# Main loop
while true; do
  echo "Waiting for changes in $NGINX_CONF_DIR, $DNS_ZONES_DIR, $USERS_DIR..."
  inotifywait --exclude .swp -e create -e modify -e delete -e move \
              "$NGINX_CONF_DIR" "$DNS_ZONES_DIR" "$USERS_DIR" \
              --format '%e %w%f' |
  while read -r EVENT FILE; do
    echo "Change detected: $EVENT in $FILE"
    if [[ "$FILE" == "$NGINX_CONF_DIR"*.conf ]]; then
      reload_nginx "$FILE" "$EVENT"
    elif [[ "$FILE" == "$DNS_ZONES_DIR"*.zone ]]; then
      reload_dns "$FILE"
    ##elif [[ "$FILE" == "$USERS_DIR"* && ! "$FILE" == "$USERS_DIR"*/** ]]; then
    ##  reload_phpmyadmin
    fi
  done
done
