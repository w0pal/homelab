#!/bin/sh
# Idempotently install the Hermes cron helper files and register the GitOps job.
# Run as the target user, not root.
set -eu
REPO=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TARGET="$HOME/.hermes/scripts"

mkdir -p "$TARGET"
cp "$REPO/scripts/hermes-cron-monitor.sh" "$TARGET/homelab-change-monitor.sh"
cp "$REPO/scripts/hermes-ai-commit.prompt.txt" "$TARGET/homelab-ai-commit.prompt.txt"
chmod 755 "$TARGET/homelab-change-monitor.sh"

if hermes cron list 2>/dev/null | grep -q 'homelab-ai-gitops'; then
  echo "Hermes cron homelab-ai-gitops already registered"
  exit 0
fi

prompt=$(cat "$TARGET/homelab-ai-commit.prompt.txt")
hermes cron create 5m \
  --name homelab-ai-gitops \
  --workdir "$REPO" \
  --monitor-script homelab-change-monitor.sh \
  --skill git-commit-permission \
  --skill git-conventional-push \
  --skill w0pal-writing-style \
  --skill docs-generator \
  --deliver local \
  --failure-deliver local \
  "$prompt"
