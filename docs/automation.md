# Automation

The host runs a few unattended jobs. Each has its own note:

- [Bot](bot.md), Renovate dependency updates.
- [Auto commit](auto-commit.md), the Hermes GitOps cron and its Paseo monitor.
- [Issues](issues.md), known UI quirks and where to check when a job looks wrong.

This page covers the recurring host tasks that are not tied to those two.

## Weekly image refresh

`scripts/podman-auto-update.sh` runs `podman auto-update` every Monday at
03:00 Asia/Jakarta from root's crontab. Every compose file in `podman/`
carries the `io.containers.autoupdate=registry` label, so the refresh picks
them up.

## Podman boot recovery

The host uses rootful Podman on Alpine OpenRC. `scripts/podman-cgroup-boot.sh`
restores the cgroup2 mount, then `scripts/podman-boot.sh` reloads the Podman
networks and starts every container that is not already running. Compose files
in `podman/` only create containers once, during bootstrap. The generated
`bootstrap.sh` installs both scripts into `/etc/local.d` when run with
`--containers`.

## Rules and recovery

The AI GitOps cron follows [the repo rules](ai-rules.md). Service recovery
order and endpoint checks are in [troubleshooting rules](troubleshooting-rules.md).
Retired jobs are listed in [retired experiments](retired-experiments.md).
