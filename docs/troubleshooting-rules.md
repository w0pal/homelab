# Troubleshooting rules

Use this when a homelab service or a public-facing site looks down.

## Rules

1. Check the full chain before changing anything: producer, local API, reverse proxy, Tailscale funnel, Vercel rewrite, browser endpoint.
2. Do not assume the repo path is the live path. Read compose labels and actual processes first.
3. Do not assume Docker is the runtime. Confirm with `podman ps`, `docker ps`, and OpenRC runlevels.
4. Do not expose secrets in commands, logs, chat, or docs. Use env files and placeholders.
5. Do not restart or recreate a stateful container until data paths and volumes are verified.
6. Do not call something fixed until the public endpoint returns the expected status. A healthy container behind a stale proxy rule is still broken.
7. Do not commit by hand while the AI cron is active. Let the cron commit. If it hangs, cancel that run before retrying.
8. Every claim needs a command result next to it. If a command could not run, say so.

## Fast checks

| Layer | Command | Expected |
|---|---|---|
| Container runtime | `podman ps --format '{{.Names}}\t{{.Status}}'` | Service is up |
| Local API | `curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3001/api/homelab` | `200` |
| Tailscale funnel | `curl -sS -o /dev/null -w '%{http_code}\n' https://takamatsu.tailb43e01.ts.net/homelab-status` | `200` |
| Vercel rewrite | `curl -sS -o /dev/null -w '%{http_code}\n' https://w0pal.my.id/api/homelab` | `200` |
| Public page | `curl -sS -o /dev/null -w '%{http_code}\n' https://w0pal.my.id/now` | `200` |
| NPM proxy | `curl -ksS -o /dev/null -w '%{http_code}\n' https://nextcloud.lab/status.php` | `200` |
| Boot config | `rc-update show default | grep -E 'cgroups|local'` | Both enabled |

## Homelab status case

The chain is:

```text
homelab-fetch container
  -> POST http://192.168.0.240:3001/api/homelab
  -> local dev API reads/writes .data/homelab.json
  -> Tailserve /homelab-status proxies http://127.0.0.1:3001/api/homelab
  -> Vercel /api/homelab rewrites to Tailscale funnel
  -> /now polls /api/homelab
```

On 2026-11-26 the status was off because `~/Projects/portfolio-web` had only `.data/homelab.json`. The working checkout was still in `~/storage/Projects/portfolio-web`. Starting the API from there restored the chain:

```sh
cd /home/tomori/storage/Projects/portfolio-web
node --env-file=.env scripts/dev-api.mjs
```

Verified results:

| Check | Result |
|---|---|
| `http://127.0.0.1:3001/api/homelab` | `200` |
| `https://takamatsu.tailb43e01.ts.net/homelab-status` | `200` |
| `https://w0pal.my.id/api/homelab` | `200` |
| `https://w0pal.my.id/now` | `200` |
| `podman logs --tail 6 homelab-fetch` | `pushed #1` |

If this breaks again, check the local API before touching Vercel or Tailscale.

## Podman reboot checklist

1. Confirm `cgroups` and `local` are in the default runlevel.
2. Confirm `/etc/local.d/01-podman-cgroup.start` restores cgroup2.
3. Confirm `/etc/local.d/90-podman.start` starts existing containers.
4. Confirm `podman network reload --all` succeeds.
5. Confirm every expected container is up.
6. Confirm the public endpoints, not just the containers.

## Watchtower replacement

Watchtower is retired. Weekly image refresh is handled by:

```sh
/home/tomori/homelab/scripts/podman-auto-update.sh
```

It runs from root crontab every Monday at 03:00 WIB. Selected containers carry `io.containers.autoupdate=registry`.
