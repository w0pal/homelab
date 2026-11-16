#!/bin/bash
# Snapshot this server's config into ~/homelab (sanitized). Idempotent.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"

copy_file() { # src dst [mode]
  local src=$1 dst=$2 mode=${3:-}
  [ -r "$src" ] || return 0
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  [ -n "$mode" ] && chmod "$mode" "$dst" || true
}

# --- system (readable /etc subset) ---
copy_file /etc/hostname system/etc/hostname
copy_file /etc/hosts system/etc/hosts
copy_file /etc/fstab system/etc/fstab
copy_file /etc/network/interfaces system/etc/network/interfaces
copy_file /etc/apk/repositories system/etc/apk/repositories
copy_file /etc/apk/world system/etc/apk/world
copy_file /etc/modules system/etc/modules
copy_file /etc/conf.d/docker system/etc/conf.d/docker
copy_file /etc/ssh/sshd_config system/etc/ssh/sshd_config
copy_file /etc/rc.conf system/etc/rc.conf
copy_file /etc/local.d/wifi-powersave.start system/etc/local.d/wifi-powersave.start

# OpenRC service scripts we maintain
copy_file /etc/init.d/9router system/etc/init.d/9router
copy_file /etc/init.d/hermes-gateway system/etc/init.d/hermes-gateway

# runlevels (default)
if [ -d /etc/runlevels/default ]; then
  mkdir -p system/etc/runlevels
  ls /etc/runlevels/default 2>/dev/null | sort > system/etc/runlevels/default.list || true
fi

# user crontab (fallback to crontab -l)
if [ -r /etc/crontabs/tomori ]; then
  copy_file /etc/crontabs/tomori system/crontab.tomori
else
  crontab -l > system/crontab.tomori 2>/dev/null || true
fi

# --- services: copy live compose files, sanitize secrets ---
sanitize_compose() {
  # redact obvious secrets/tokens/passwords in env/args lines
  sed -E \
    -e 's/(ADMIN_TOKEN=).*/\1${ADMIN_TOKEN}/' \
    -e 's/(INITIAL_PASSWORD:).*/\1 "${INITIAL_PASSWORD}"/' \
    -e 's/(JWT_SECRET:).*/\1 "${JWT_SECRET}"/' \
    -e 's/(PASSWORD=).*/\1${PASSWORD}/' \
    -e 's/(TOKEN=).*/\1${TOKEN}/' \
    -e 's/(SECRET=).*/\1${SECRET}/'
}

sync_compose() { # src_dir name
  local src=$1 name=$2
  [ -f "$src/docker-compose.yml" ] || [ -f "$src/docker-compose.yaml" ] || return 0
  mkdir -p "services/$name"
  local f
  for f in "$src"/docker-compose.yml "$src"/docker-compose.yaml "$src"/.env.example; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in
      docker-compose.yml|docker-compose.yaml)
        sanitize_compose < "$f" > "services/$name/$(basename "$f")"
        ;;
      .env.example)
        cp "$f" "services/$name/.env.example"
        ;;
    esac
  done
}

sync_compose /home/tomori/containers/adguardhome adguardhome
sync_compose /home/tomori/containers/vaultwarden vaultwarden
sync_compose /home/tomori/containers/watchtower watchtower
sync_compose /home/tomori/containers/nginx-proxy-manager nginx-proxy-manager
sync_compose /home/tomori/containers/9router 9router
[ -d /home/tomori/containers/dockge ] && sync_compose /home/tomori/containers/dockge dockge || true

# adguard runtime config (sanitized) if readable (repo copy kept otherwise)
for agh in /home/tomori/containers/adguardhome/conf/AdGuardHome.yaml /home/tomori/containers/adguardhome/AdGuardHome.yaml; do
  if [ -r "$agh" ]; then
    cp "$agh" services/adguardhome/AdGuardHome.yaml
    sed -i 's/^\(  password:\).*/\1 ""/' services/adguardhome/AdGuardHome.yaml 2>/dev/null || true
    break
  fi
done

# remove junk
rm -f docker.txt
