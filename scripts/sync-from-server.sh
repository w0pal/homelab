#!/bin/bash
# Sync homeserver configs to GitHub repo
# Run this on the homeserver via cron or systemd timer

set -euo pipefail

REPO_DIR="/home/homeserver/homelab"
SSH_KEY="${HOMESERVER_SSH_KEY_PATH:-$HOME/.ssh/id_ed25519}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $*"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $*"
}

# Check if repo exists
if [ ! -d "$REPO_DIR/.git" ]; then
    error "Git repo not found at $REPO_DIR"
    exit 1
fi

cd "$REPO_DIR"

# Pull latest changes first
log "Pulling latest changes from origin..."
git pull --rebase origin main 2>/dev/null || warn "Could not pull from origin (maybe no upstream yet)"

# Sync configs from server to repo
log "Syncing AdGuard Home config..."
cp /home/homeserver/AdGuardHome.yaml services/adguardhome/AdGuardHome.yaml

log "Stripping secrets from configs..."
sed -i 's/^\(  password:\).*/\1 ""/' services/adguardhome/AdGuardHome.yaml

log "Syncing Vaultwarden docker-compose..."
cp /home/homeserver/vaultwarden/docker-compose.yml services/vaultwarden/docker-compose.yml

log "Syncing Watchtower docker-compose..."
cp /home/homeserver/watchtower/docker-compose.yml services/watchtower/docker-compose.yml

log "Syncing Nginx Proxy Manager docker-compose..."
cp /home/homeserver/homelab/services/nginx-proxy-manager/docker-compose.yml services/nginx-proxy-manager/docker-compose.yml

# Check for changes
if git diff --quiet; then
    log "No changes detected"
    exit 0
fi

# Show what changed
log "Changes detected:"
git diff --stat

# Commit and push
log "Committing changes..."
git add -A
git commit -m "chore: auto-sync homeserver configs" -m "Auto-synced from homeserver at $(date -u +'%Y-%m-%d %H:%M:%S UTC')"

log "Pushing to origin..."
git push origin main

log "Sync complete!"
