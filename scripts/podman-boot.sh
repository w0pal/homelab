#!/bin/sh
# Start all Podman compose projects from the host boot local service.
set -eu
REPO=/home/tomori/homelab
for f in "$REPO"/podman/*.yml; do
  [ -f "$f" ] || continue
  /usr/bin/podman-compose -f "$f" up -d >> /var/log/podman-boot.log 2>&1 || true
done
