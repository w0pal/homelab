#!/bin/sh
# Renew the Tailscale-issued Let's Encrypt cert for takamatsu.tailb43e01.ts.net
# used by nginx-proxy-manager proxy host 7 (Vaultwarden, LAN access via the
# AdGuard DNS rewrite takamatsu.tailb43e01.ts.net -> 192.168.0.240).
#
# Cert lives at /data/custom_ssl/npm-3/{fullchain.pem,privkey.pem} inside the
# nginx-proxy-manager container. `tailscale cert --min-validity 720h` renews
# only when <30 days of validity remain; nginx is reloaded only on change.
# Installed in user crontab (weekly). Log: ~/.local/log/takamatsu-cert.log
set -eu

DOMAIN=takamatsu.tailb43e01.ts.net
CTR=nginx-proxy-manager
CERTDIR=/data/custom_ssl/npm-3
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

/usr/bin/tailscale cert --cert-file "$TMP/fullchain.pem" --key-file "$TMP/privkey.pem" --min-validity 720h "$DOMAIN"

CHANGED=0
for f in fullchain.pem privkey.pem; do
    if ! /usr/bin/docker exec "$CTR" cat "$CERTDIR/$f" 2>/dev/null | cmp -s - "$TMP/$f"; then
        /usr/bin/docker cp "$TMP/$f" "$CTR:$CERTDIR/$f"
        CHANGED=1
    fi
done

if [ "$CHANGED" = 1 ]; then
    /usr/bin/docker exec "$CTR" sh -c "chmod 644 $CERTDIR/fullchain.pem; chmod 600 $CERTDIR/privkey.pem"
    /usr/bin/docker exec "$CTR" nginx -t
    /usr/bin/docker exec "$CTR" nginx -s reload
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') cert renewed, nginx reloaded"
else
    echo "$(date '+%Y-%m-%dT%H:%M:%S%z') cert unchanged"
fi
