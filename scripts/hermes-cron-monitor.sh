#!/bin/sh
# Hermes cron monitor for the homelab GitOps repo.
# Refresh the snapshot, then emit a stable change summary. Hermes suppresses the
# agent run when this output is byte-identical to the previous output. While the
# repo still has work to sync, emit a fresh token so an interrupted or failed
# attempt is retried on the next tick instead of being suppressed forever.
set -eu
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
# The installed copy lives in ~/.hermes/scripts, so its parent is not the repo.
# The cron runs with the repo as workdir; fall back to the standard location.
if [ ! -f "$REPO/scripts/sync-homelab.sh" ]; then
  if [ -f "$(pwd)/scripts/sync-homelab.sh" ]; then
    REPO=$(pwd)
  elif [ -f "$HOME/homelab/scripts/sync-homelab.sh" ]; then
    REPO="$HOME/homelab"
  else
    printf '%s\n' 'homelab repo not found; monitor cannot run' >&2
    exit 1
  fi
fi

$REPO/scripts/sync-homelab.sh >/dev/null 2>&1 || true
$REPO/scripts/generate-bootstrap.sh >/dev/null 2>&1 || true

cd "$REPO"

ahead=0
behind=0
if git rev-parse --verify --quiet '@{upstream}' >/dev/null; then
  set -- $(git rev-list --left-right --count '@{upstream}...HEAD')
  behind=$1
  ahead=$2
fi

DIRTY=$(git status --porcelain -uall)
if [ -z "$DIRTY" ] && [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
  exit 0
fi

printf '%s\n' '--- status ---'
printf '%s\n' "$DIRTY" | sort
printf '%s\n' '--- content fingerprint ---'
git diff HEAD | sha256sum | cut -d' ' -f1
git ls-files --others --exclude-standard | while IFS= read -r f; do
  [ -f "$f" ] && sha256sum "$f"
done | sha256sum | cut -d' ' -f1
printf 'ahead=%s behind=%s\n' "$ahead" "$behind"
printf '%s\n' '--- retry token ---'
date -u '+%Y-%m-%dT%H:%M:%SZ'
printf '%s\n' '--- live inventory ---'
cat system/inventory.txt 2>/dev/null || true
