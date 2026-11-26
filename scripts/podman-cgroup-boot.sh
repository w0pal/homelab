#!/bin/sh
# Ensure cgroup2 is mounted before Podman boot script runs.
[ "$(stat -fc %T /sys/fs/cgroup 2>/dev/null)" = cgroup2fs ] && exit 0
mount -t cgroup2 none /sys/fs/cgroup 2>/dev/null || true
rc-service cgroups start >/dev/null 2>&1 || true
