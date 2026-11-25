#!/bin/sh
# Hermes cron monitor for the homelab GitOps repo.
# Refresh the snapshot, then emit a stable change summary. Hermes suppresses the
# agent run when this output is byte-for-byte unchanged, so keep timestamps out.
set -eu
REPO=/home/tomori/homelab

/home/tomori/homelab/scripts/sync-homelab.sh >/dev/null 2>&1 || true
/home/tomori/homelab/scripts/generate-bootstrap.sh >/dev/null 2>&1 || true

cd "$REPO"
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi

printf '%s\n' '--- status ---'
git status --porcelain -uall | sort
printf '%s\n' '--- diff stat ---'
git diff --stat
printf '%s\n' '--- live inventory ---'
cat system/inventory.txt 2>/dev/null || true
