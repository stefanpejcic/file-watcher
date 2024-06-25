# file-watcher
Auto-reload services when changes are detected in configuration files


- **nginx** - when change is detected in `/etc/nginx/sites-available`, run [`nginx -t`](https://www.oreilly.com/library/view/nginx-troubleshooting/9781785288654/ch01s02.html) and [`nginx -s reload`](https://nginx.org/en/docs/beginners_guide.html#control)
- **named** -  when change is detected in `/etc/bind/zones`, run [`named-checkzone`](https://linux.die.net/man/8/named-checkzone) and [`rndc reload`](https://docs.oracle.com/cd/E19253-01/816-4556/dnsref-8/index.html)
- **systemd** -  when change is detected in `/etc/systemd/system`, run [`systemctl daemon-reload`](https://www.man7.org/linux/man-pages/man1/systemctl.1.html)

## Install

```bash
bash <(curl -sSL https://raw.githubusercontent.com/stefanpejcic/file-watcher/main/install.sh)
```
