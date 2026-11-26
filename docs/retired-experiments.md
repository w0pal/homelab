# Retired experiments

This page keeps the history of things that are no longer installed or running. The main README only lists the live stack.

No internal, work, client, employer, professional, or non-homelab project is recorded here. Private checkouts are never part of this repo.

## Retired services

| Experiment | State | What replaced it |
|---|---|---|
| Dockge | Not installed. Compose file and DNS rewrite removed. | Podman Compose files under `podman/`. |
| Cockpit | Not installed. DNS rewrite removed. | No replacement. |
| Uptime Kuma | Not installed. DNS rewrite removed. | No replacement. |
| Watchtower | Container no longer started. | `scripts/podman-auto-update.sh` runs `podman auto-update` every Monday at 03:00 Asia/Jakarta from root's crontab. |
| ZTE B860H | Old hardware retired. | HP EliteDesk 800 G3 DM 35W, hostname `takamatsu`. |

## Configs kept, not running

| Name | State | Note |
|---|---|---|
| `opencode-bot` | Config kept, container not running. | Build context under `services/opencode-bot/`. |
| `hermes-agent` | Config kept, container not running. | Build context under `services/hermes-agent/`. |
| `watchtower` | Config kept, container not running. | Superseded by `scripts/podman-auto-update.sh`. |

## Retired automation

| Item | State | Current path |
|---|---|---|
| `auto-commit-homelab.sh` five-minute cron | Retired. | Hermes AI GitOps cron runs every five minutes. |
| GitHub Actions auto-commit workflow | Manual only. | Run it from the Actions tab for a one-off sync. |

## Verify the live stack

```sh
podman ps --format '{{.Names}}'
rc-update show default
crontab -l | grep auto-update
```

The first command should show only current services. Retired names should not appear in the running list.
