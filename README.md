# file-watcher
Auto-reload services when changes are detected in BIND or Nginx configuration files


- **Nginx** - when change is detected in `/etc/nginx/sites-available`, run [`nginx -t`](https://www.oreilly.com/library/view/nginx-troubleshooting/9781785288654/ch01s02.html) and [`nginx -s reload`](https://nginx.org/en/docs/beginners_guide.html#control)
- **Named** -  when change is detected in `/etc/bind/zones`, run [`named-checkzone`](https://linux.die.net/man/8/named-checkzone) and [`rndc reload`](https://docs.oracle.com/cd/E19253-01/816-4556/dnsref-8/index.html)


## Install

```bash
git clone https://github.com/stefanpejcic/file-watcher /usr/local/admin/scripts/watcher && bash /usr/local/admin/scripts/watcher/install.sh
```
