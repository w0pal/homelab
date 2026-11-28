#!/bin/sh
# Clean stale local state for the homelab host.
# Dry run by default. Use --apply to perform changes.
# No AI calls, no network, no container names from private checkouts.
set -eu

APPLY=0
case "${1:-}" in
  --apply) APPLY=1 ;;
  -h|--help)
    echo "Usage: $0 [--apply]"
    exit 0
    ;;
  "")
    ;;
  *)
    echo "unknown option: $1" >&2
    exit 1
    ;;
esac

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
USER_NAME=${SUDO_USER:-${DOAS_USER:-$(id -un)}}
if [ "$USER_NAME" = root ] && [ -d "$REPO_DIR" ]; then
  repo_owner=$(stat -c %U "$REPO_DIR" 2>/dev/null || true)
  if [ -n "$repo_owner" ] && [ "$repo_owner" != root ]; then
    USER_NAME=$repo_owner
  fi
fi
HOME_DIR=$(getent passwd "$USER_NAME" 2>/dev/null | cut -d: -f6 || true)
[ -n "$HOME_DIR" ] || HOME_DIR="/home/$USER_NAME"

run() {
  if [ "$APPLY" = 1 ]; then
    "$@"
  else
    printf '[dry-run]'
    printf ' %s' "$@"
    printf '\n'
  fi
}

run_as_user() {
  if [ "$APPLY" = 1 ]; then
    if [ "$(id -u)" -eq 0 ]; then
      su - "$USER_NAME" -c "$1"
    else
      sh -c "$1"
    fi
  else
    printf '[dry-run] as %s: %s\n' "$USER_NAME" "$1"
  fi
}

echo "Repo: $REPO_DIR"
echo "Target user: $USER_NAME"
echo "Mode: $([ "$APPLY" = 1 ] && echo apply || echo dry-run)"

# 1. Failed first Nix install left a chroot store that is no longer used.
if [ -d /nix/var/nix ] && [ -d "$HOME_DIR/.local/share/nix/root" ]; then
  echo "Nix chroot leftover: $HOME_DIR/.local/share/nix/root"
  run chmod -R u+w "$HOME_DIR/.local/share/nix/root"
  run rm -rf "$HOME_DIR/.local/share/nix/root"
else
  echo "Nix chroot leftover: none"
fi

# 2. Old Nix profile generations and unreachable store paths.
if command -v nix >/dev/null 2>&1 || [ -x /usr/bin/nix ]; then
  NIX_BIN=$(command -v nix 2>/dev/null || echo /usr/bin/nix)
  run_as_user "export NIX_CONFIG='experimental-features = nix-command flakes'; $NIX_BIN profile wipe-history && $NIX_BIN store gc"
else
  echo "skip Nix history cleanup: nix not found"
fi

# 3. npm extraneous packages left by removed globals.
if [ -x "$HOME_DIR/.nix-profile/bin/npm" ] && [ -f "$HOME_DIR/.npm-global/package.json" ]; then
  # npm has no global prune in this version. Detect extraneous entries from
  # the global tree and remove their directories directly.
  extras=$("$HOME_DIR/.nix-profile/bin/npm" ls -g --prefix "$HOME_DIR/.npm-global" --depth=0 2>/dev/null | awk '/extraneous/ {print $2}' | sed -E 's/@[0-9][^@]*$//' || true)
  for pkg in $extras; do
    [ -n "$pkg" ] || continue
    run rm -rf "$HOME_DIR/.npm-global/lib/node_modules/$pkg"
  done
  # Older bootstrap versions installed a second project-style tree here.
  if [ -d "$HOME_DIR/.npm-global/node_modules" ]; then
    run rm -rf "$HOME_DIR/.npm-global/node_modules"
    run rm -f "$HOME_DIR/.npm-global/package-lock.json"
  fi
else
  echo "skip npm prune: npm or manifest not found"
fi

# 4. apk download cache. This needs root.
if [ "$(id -u)" -eq 0 ]; then
  run apk cache clean
else
  echo "skip apk cache clean: run this script with doas to include it"
fi

# 5. Podman state. Containers are reported by count and fingerprint only.
PODMAN=${PODMAN:-podman}
if command -v "$PODMAN" >/dev/null 2>&1; then
  stopped=$("$PODMAN" ps -a --format '{{.Names}}\t{{.Status}}' 2>/dev/null | awk -F '\t' '$2 !~ /^Up/' | wc -l | tr -d ' ')
  echo "stopped containers: $stopped (not removed automatically)"

  tmp=$(mktemp -d "${TMPDIR:-/tmp}/homelab-cleanup.XXXXXX")
  "$PODMAN" ps -a --format '{{.ImageID}}' 2>/dev/null | sort -u > "$tmp/used" || true
  "$PODMAN" images --format '{{.ID}}' 2>/dev/null | sort -u > "$tmp/all" || true
  comm -13 "$tmp/used" "$tmp/all" > "$tmp/unused" || true
  unused=$(wc -l < "$tmp/unused" | tr -d ' ')
  echo "unused images: $unused"
  if [ "$unused" -gt 0 ]; then
    echo "unused image fingerprint: $(sha256sum "$tmp/unused" | cut -c1-16)"
    while IFS= read -r id; do
      [ -n "$id" ] || continue
      run "$PODMAN" image rm "$id"
    done < "$tmp/unused"
  fi
  rm -rf "$tmp"
else
  echo "skip Podman cleanup: podman not found"
fi

echo "Nix store: $(du -sh /nix/store 2>/dev/null | cut -f1 || echo unknown)"
echo "npm-global: $(du -sh "$HOME_DIR/.npm-global" 2>/dev/null | cut -f1 || echo unknown)"
