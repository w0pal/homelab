#!/bin/sh
# Start existing Podman containers at boot.
# Compose files are only used by bootstrap to create containers once.
set -eu
LOG=/var/log/podman-boot.log

/usr/bin/podman network reload --all >>"$LOG" 2>&1 || true

for c in $(/usr/bin/podman ps -a --format '{{.Names}}' 2>/dev/null); do
  status=$(/usr/bin/podman inspect "$c" --format '{{.State.Status}}' 2>/dev/null || true)
  [ "$status" = running ] && continue
  /usr/bin/podman start "$c" >>"$LOG" 2>&1 || true
done
