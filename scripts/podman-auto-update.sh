#!/bin/sh
set -eu

# Weekly Podman image refresh for selected registry-backed services.
# Runs from root's crontab every Monday at 03:00 Asia/Jakarta.
/usr/bin/podman auto-update --format '{{.Container}} {{.Image}} {{.Result}}' >> /var/log/podman-auto-update.log 2>&1
