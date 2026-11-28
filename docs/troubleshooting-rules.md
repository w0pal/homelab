# Troubleshooting rules

Use this when a homelab service or a public-facing site looks down. Read `docs/ai-rules.md` first when an AI is doing the troubleshooting.

## Rules

1. Check the full chain before changing anything: producer, local API, reverse proxy, Tailscale funnel, Vercel rewrite, browser endpoint.
2. Do not assume the repo path is the live path. Read compose labels and actual processes first.
3. Confirm the runtime with `podman ps` and OpenRC runlevels.
4. Do not expose secrets in commands, logs, chat, or docs. Use env files and placeholders.
5. Do not restart or recreate a stateful container until data paths and volumes are verified.
6. Do not call something fixed until the public endpoint returns the expected status. A healthy container behind a stale proxy rule is still broken.
7. Do not commit by hand while the AI cron is active. Let the cron commit. If it hangs, cancel that run before retrying.
8. Every claim needs a command result next to it. If a command could not run, say so.
9. Never include internal, work, client, employer, professional, or non-homelab projects in docs, inventory, bootstrap, or commits. Use the generic phrase `private checkout` only.

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
cd $HOME/storage/Projects/portfolio-web
node --env-file=.env scripts/dev-api.mjs
```

The OpenRC service must use that same path. Check with:

| Command | Expected |
|---|---|
| `grep '^directory' /etc/init.d/portfolio-api` | `$HOME/storage/Projects/portfolio-web` |
| `ss -ltnp | grep ':3001'` | `0.0.0.0:3001` |
| `curl http://192.168.0.240:3001/api/homelab` | `200` |
| `podman logs --tail 5 homelab-fetch` | `pushed #N` |

The collector posts to `192.168.0.240:3001`, so binding the API only to `127.0.0.1` makes the page show offline even when the funnel works. `scripts/dev-api.mjs` now defaults `HOST=0.0.0.0`.

When starting the service through a helper container, use the host network namespace. A helper started with `--network none` will bind port 3001 inside its own namespace and look healthy from inside while the host sees nothing.

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
$HOME/homelab/scripts/podman-auto-update.sh
```

It runs from root crontab every Monday at 03:00 WIB. Selected containers carry `io.containers.autoupdate=registry`.

## Idle power and persistence

C-states need no configuration on this host. `intel_idle` with the `menu` governor already exposes POLL/C1/C1E/C3/C6/C7s/C8 and the default `intel_idle.max_cstate` is 9. Do not add `intel_idle.max_cstate` or `idle=nomwait`; those restrict deep states and raise idle power.

The runtime-only knobs are set by `system/etc/local.d/power-powersave.start`, which OpenRC's `local` service runs at boot. It sets the HWP energy preference to `balance_power`, keeps turbo and `max_perf_pct` at 100, and sets PCIe ASPM to `powersave`. Bootstrap installs that script with mode 755 so it actually runs.

Verify after a reboot:

| Command | Expected |
|---|---|
| `cat /sys/devices/system/cpu/cpufreq/policy0/energy_performance_preference` | `balance_power` |
| `cat /sys/module/pcie_aspm/parameters/policy` | `[powersave]` |
| `cat /sys/devices/system/cpu/cpuidle/current_driver` | `intel_idle` |

## Auto-commit health check

The GitOps cron job is `homelab-ai-gitops` with ID `9330b977c824`. It runs every five minutes. The monitor refreshes the snapshot first, so a clean repo produces no agent run.

| Command | Expected |
|---|---|
| `hermes cron status` | Gateway running and one active job |
| `hermes cron list` | Schedule `every 5m`, workdir `$HOME/homelab` |
| `hermes cron runs 9330b977c824` | Recent runs show `completed` |
| `git -C $HOME/homelab status -sb` | `## main...origin/main` with no files after the run |
| `git -C $HOME/homelab rev-parse HEAD origin/main` | Both hashes are the same |

To verify end to end, make one small tracked change and wait for the next tick. The agent should commit it with a Conventional Commit body and push once. If the run stays `running` for more than one interval, cancel that run before retrying.
