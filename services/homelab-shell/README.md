# homelab-shell

Public read-only shell for the portfolio's **Terminal** page. Visitors type
whitelisted commands on the site; this worker container picks them up from
the portfolio API queue, runs them against read-only host mounts, and posts
the output back. No inbound ports, no container runtime socket, no shell interpretation.

## Allowed commands

`fastfetch`, `btop` (3s TUI snapshot via pyte), `df -h`, `free -h`, `uptime`,
`uname -a`, `lsblk`, `hostname`, `date` — plus client-side `help` / `clear`.

The API (`api/terminal.js` in portfolio-web) validates and canonicalizes
every submission against the same whitelist, rate-limits visitors (1 cmd /
2s / IP, queue cap 5), and the worker re-validates before executing.
Commands run as fixed argv via `subprocess` — visitor input never reaches a
shell.

## Isolation

- non-root (`nobody`), `cap_drop: ALL`, `no-new-privileges`, read-only rootfs
- host mounts all `:ro` (`/proc`, `/sys`, `/etc/os-release`, `/` → `/host`)
- no published ports, no host network, no container runtime socket, outbound HTTPS only
- 256 MB / 1 CPU / 64 pids limits

## Setup

```bash
cp .env.example .env
# edit .env:
#   HOMELAB_API_URL=https://<your-portfolio>/api/terminal
#   HOMELAB_SHELL_TOKEN=<same token as HOMELAB_SHELL_TOKEN on Vercel>
cd ../..
podman-compose -f podman/podman-shell.yml up -d --build
podman logs -f homelab-shell
```

On Vercel set `HOMELAB_SHELL_TOKEN` to the same value. Upstash Redis is
reused from the Anki/homelab trackers (the queue uses BLPOP long-polling);
without Redis the API falls back to an in-memory queue for local dev.

## Local dev

```
HOMELAB_API_URL=http://192.168.0.240:3001/api/terminal
```

(`npm run dev:api` in portfolio-web serves `/api/terminal` on port 3001.)

## Notes

- `df -h` reports the host root via the `/host` mount; the worker relabels
  the mountpoint to `/` in the output.
- `btop` has no batch mode, so the worker runs it in a pty for ~3 seconds,
  emulates the screen with pyte, and serializes the final frame to ANSI
  (256/truecolor) for the web terminal.
- Host LAN IP is not exposed here; `hostname` reads `/host/etc/hostname`.
