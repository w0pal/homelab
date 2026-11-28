#!/bin/sh
# Install the portfolio API as an OpenRC service and retire the cron watchdog.
# Run with sudo: sudo sh scripts/install-portfolio-api-service.sh
set -eu

REPO=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
USER_NAME=${SUDO_USER:-$(id -un)}
HOME_DIR=$(getent passwd "$USER_NAME" 2>/dev/null | cut -d: -f6)
[ -n "$HOME_DIR" ] || HOME_DIR="/home/$USER_NAME"

SRC="$REPO/init/portfolio-api.openrc"
DST=/etc/init.d/portfolio-api

sed -e "s|{{HOMELAB_USER}}|$USER_NAME|g" -e "s|{{HOMELAB_HOME}}|$HOME_DIR|g" "$SRC" > "$DST"
chmod 0755 "$DST"
/usr/libexec/rc/bin/checkpath -f -o "$USER_NAME:$USER_NAME" -m 0644 "$HOME_DIR/.local/log/portfolio-api.log"

# Retire the tmux-based instance so the service can own port 3001.
su "$USER_NAME" -s /bin/sh -c 'tmux kill-session -t portfolio-api 2>/dev/null || true' || true

# Remove the old cron watchdog entries for this API.
tmp=$(mktemp)
/bin/chown "$USER_NAME:$USER_NAME" "$tmp"
/bin/chmod 600 "$tmp"
crontab -u "$USER_NAME" -l 2>/dev/null | /bin/grep -v 'ensure-portfolio-api.sh' | /bin/grep -v '# Portfolio API + homelab-status funnel watchdog' > "$tmp" || true
crontab -u "$USER_NAME" "$tmp"
rm -f "$tmp"

rc-update add portfolio-api default
rc-service portfolio-api restart
rc-service portfolio-api status
