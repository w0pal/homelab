#!/bin/sh
# Keep the local portfolio API alive behind the homelab-status Tailscale funnel.
# A reboot restarts Podman and Tailscale via OpenRC, but the API lives in a tmux
# session and does not come back by itself. This script restores both.

exec 9>/tmp/portfolio-api-watchdog.lock
/usr/bin/flock -n 9 || exit 0

USER_NAME=${SUDO_USER:-$(id -un)}
HOME_DIR=$(getent passwd "$USER_NAME" 2>/dev/null | cut -d: -f6)
[ -n "$HOME_DIR" ] || HOME_DIR="/home/$USER_NAME"
PROJECT=$HOME_DIR/storage/Projects/portfolio-web
SESSION=portfolio-api
HEALTH=http://127.0.0.1:3001/api/homelab
FUNNEL_PATH=/homelab-status
LOG=$HOME_DIR/.local/log/portfolio-api-watchdog.log
ts() { /bin/date '+%F %T'; }

healthy() {
  /usr/bin/curl -fsS --max-time 5 "$HEALTH" >/dev/null 2>&1
}

if ! healthy; then
  echo "$(ts) API unhealthy, restarting $SESSION" >> "$LOG"
  if $HOME_DIR/.nix-profile/bin/tmux has-session -t "$SESSION" 2>/dev/null; then
    $HOME_DIR/.nix-profile/bin/tmux kill-session -t "$SESSION" >/dev/null 2>&1 || true
  fi
  /usr/bin/pkill -f 'node --env-file=.env scripts/dev-api.mjs' >/dev/null 2>&1 || true
  /bin/sleep 1
  $HOME_DIR/.nix-profile/bin/tmux new-session -d -s "$SESSION" -x 120 -y 30 \
    "cd $PROJECT && $HOME_DIR/.nix-profile/bin/npm run dev:api" >/dev/null 2>&1
  /bin/sleep 4
  if healthy; then
    echo "$(ts) API healthy again" >> "$LOG"
  else
    echo "$(ts) API still unhealthy" >> "$LOG"
  fi
fi

if ! $HOME_DIR/.nix-profile/bin/tailscale funnel status 2>/dev/null | /bin/grep -q -- "$FUNNEL_PATH"; then
  echo "$(ts) funnel path missing, re-adding $FUNNEL_PATH" >> "$LOG"
  $HOME_DIR/.nix-profile/bin/tailscale funnel --bg --https=443 \
    --set-path="$FUNNEL_PATH" http://127.0.0.1:3001/api/homelab \
    >> "$LOG" 2>&1
fi
