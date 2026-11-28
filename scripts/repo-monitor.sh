#!/bin/sh
# Read-only health and history report for the homelab repo.
# Used from a Paseo terminal/workspace script and by the Paseo monitor schedule.
# Never writes to the repo, never prints credentials.
set -u
REPO=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPO" || exit 1

LIMIT=${LIMIT:-0}
HERMES=${HERMES:-$(command -v hermes || true)}
CURL=$(command -v curl || true)

printf '%s\n' '=== homelab repo monitor ==='
printf 'repo: %s\n' "$REPO"
printf 'checked: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

printf '\n%s\n' '--- git state ---'
printf 'branch: %s\n' "$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)"
printf 'head: %s\n' "$(git rev-parse --short HEAD)"
git status -sb | sed -n '1p'
if git rev-parse --verify --quiet '@{upstream}' >/dev/null; then
  set -- $(git rev-list --left-right --count '@{upstream}...HEAD')
  printf 'ahead/behind: %s/%s\n' "$2" "$1"
fi
printf 'commits reachable from HEAD: %s\n' "$(git rev-list --count HEAD)"
printf 'shallow clone: %s\n' "$(git rev-parse --is-shallow-repository)"

DIRTY=$(git status --porcelain -uall)
if [ -z "$DIRTY" ]; then
  printf 'working tree: clean\n'
else
  printf 'working tree: %s changed path(s)\n' "$(printf '%s\n' "$DIRTY" | wc -l | tr -d ' ')"
  printf '%s\n' "$DIRTY" | sed -n '1,20p'
fi

printf '\n%s\n' '--- full git history ---'
if [ "$LIMIT" -gt 0 ] 2>/dev/null; then
  git log --graph --oneline --decorate --all -n "$LIMIT"
else
  git log --graph --oneline --decorate --all
fi

printf '\n%s\n' '--- branches ---'
git for-each-ref --format='%(refname:short) %(objectname:short)' refs/heads refs/remotes/origin

if [ -n "$HERMES" ] && [ -x "$HERMES" ]; then
  printf '\n%s\n' '--- GitOps cron ---'
  JOB_ID=$("$HERMES" cron list 2>/dev/null | awk '/^  [0-9a-f]+ \[/{id=$1} /Name: +homelab-ai-gitops/{print id; exit}')
  if [ -n "$JOB_ID" ]; then
    printf 'job id: %s\n' "$JOB_ID"
    "$HERMES" cron list 2>/dev/null | grep -A4 -B1 'homelab-ai-gitops' | sed -n '1,8p'
    printf '%s\n' 'recent runs:'
    "$HERMES" cron runs "$JOB_ID" --limit 5 2>/dev/null | sed -n '1,12p'
  else
    printf 'homelab-ai-gitops: not registered\n'
  fi
fi

if [ -n "$CURL" ]; then
  printf '\n%s\n' '--- endpoints (HTTP status) ---'
  for ENDPOINT in \
    'local API|http://192.168.0.240:3001/api/homelab' \
    'funnel|https://takamatsu.tailb43e01.ts.net/homelab-status' \
    'public API|https://w0pal.my.id/api/homelab' \
    'public page|https://w0pal.my.id/now'; do
    NAME=${ENDPOINT%%|*}
    URL=${ENDPOINT#*|}
    CODE=$("$CURL" -sS -o /dev/null -w '%{http_code}' --max-time 8 "$URL" 2>/dev/null || printf '000')
    printf '%-11s %s %s\n' "$NAME" "$CODE" "$URL"
  done
fi

printf '\n%s\n' '=== end report ==='
