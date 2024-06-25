# file-watcher
Auto-reload services when changes are detected in BIND or Nginx configuration files


- **Nginx* - when change is detected in `/etc/nginx/sites-available`, run `nginx -t` then `nginx -s reload`
- **Named** -  when chaneg is detected in `/etc/bind/zones`, run `named-checkzone` then `rndc reload`
