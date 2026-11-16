#!/bin/bash
# Sync server config and auto-commit changes with conventional messages.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_DIR"
LOCK="/tmp/homelab-autocommit.lock"
exec 9>"$LOCK"
flock -n 9 || exit 0

# sync
./scripts/sync-homelab.sh >/dev/null 2>&1 || true

# nothing to do?
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi

commit_path() { # path
  local p="$1" type scope msg
  case "$p" in
    system/etc/init.d/*)      type=chore; scope=init; msg="update $(basename "$p") service script" ;;
    system/etc/network/*)     type=chore; scope=network; msg="update $(basename "$p")" ;;
    system/etc/apk/*)         type=chore; scope=apk; msg="update $(basename "$p")" ;;
    system/etc/ssh/*)         type=chore; scope=ssh; msg="update $(basename "$p")" ;;
    system/etc/runlevels/*)   type=chore; scope=init; msg="update runlevel $(basename "$p")" ;;
    system/crontab.*)         type=chore; scope=cron; msg="update user crontab" ;;
    system/etc/*)             type=chore; scope=system; msg="update $(basename "$p")" ;;
    system/*)                 type=chore; scope=system; msg="update $(echo "$p" | sed 's#^system/##')" ;;
    services/*/docker-compose.yml|services/*/docker-compose.yaml)
      type=chore; scope="service/$(echo "$p" | cut -d/ -f2)"; msg="update compose" ;;
    services/*/.env.example)  type=chore; scope="service/$(echo "$p" | cut -d/ -f2)"; msg="update env example" ;;
    services/*/AdGuardHome.yaml)
      type=chore; scope="service/adguardhome"; msg="update AdGuardHome config" ;;
    services/*)               type=chore; scope="service/$(echo "$p" | cut -d/ -f2)"; msg="update config" ;;
    configs/*)                type=chore; scope=config; msg="update $(echo "$p" | sed 's#^configs/##')" ;;
    scripts/*)                type=chore; scope=scripts; msg="update $(basename "$p")" ;;
    .github/*)                type=ci; scope=github; msg="update $(basename "$p")" ;;
    README.md)                type=docs; scope=readme; msg="update documentation" ;;
    *)                        type=chore; scope=homelab; msg="update $(basename "$p")" ;;
  esac
  git add -- "$p"
  if ! git diff --cached --quiet -- "$p"; then
    git commit -m "${type}(${scope}): ${msg}" -- "$p" >/dev/null 2>&1 || true
  fi
}

# commit each changed/untracked path separately
while IFS= read -r p; do
  [ -n "$p" ] || continue
  commit_path "$p"
done < <(git status --porcelain -uall | awk '{print substr($0,4)}' | sed 's/^"//;s/"$//' | sort -u)

# optional push if remote configured and auth works (non-fatal)
if git remote get-url origin >/dev/null 2>&1; then
  git push origin main >/dev/null 2>&1 || true
fi
