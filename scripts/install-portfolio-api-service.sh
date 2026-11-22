#!/bin/sh
# Install the portfolio API as an OpenRC service and retire the cron watchdog.
# Run with sudo: sudo sh scripts/install-portfolio-api-service.sh
set -eu

REPO=/home/tomori/homelab
SRC="$REPO/init/portfolio-api.openrc"
DST=/etc/init.d/portfolio-api

install -m 0755 "$SRC" "$DST"
/usr/libexec/rc/bin/checkpath -f -o tomori:tomori -m 0644 /home/tomori/.local/log/portfolio-api.log

# Retire the tmux-based instance so the service can own port 3001.
su tomori -s /bin/sh -c 'tmux kill-session -t portfolio-api 2>/dev/null || true' || true

# Remove the old cron watchdog entries for this API.
tmp=$(mktemp)
/bin/chown tomori:tomori "$tmp"
/bin/chmod 600 "$tmp"
crontab -u tomori -l 2>/dev/null | /bin/grep -v 'ensure-portfolio-api.sh' | /bin/grep -v '# Portfolio API + homelab-status funnel watchdog' > "$tmp" || true
crontab -u tomori "$tmp"
rm -f "$tmp"

rc-update add portfolio-api default
rc-service portfolio-api restart
rc-service portfolio-api status
