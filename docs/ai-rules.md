# AI rules for this repo

Use these rules when an AI clones this repo or troubleshoots the host.

## Before doing anything

1. Read `README.md`, `docs/troubleshooting-rules.md`, `docs/ai-rules.md`, and `init/README.md`.
2. Read `system/inventory.txt` for the live snapshot. Treat it as evidence, not as a guess.
3. Check the runtime before running commands. Use `podman ps` and `rc-update show default`.
4. Verify the live path from Compose labels or process arguments. Do not assume the repo path is the live path.
5. Never read or print `.env` values. Env files are loaded by the service itself.

## Private projects

This is the strictest rule.

- Never add an internal, work, client, employer, professional, or non-homelab project to `README.md`, `system/inventory.txt`, `bootstrap.sh`, Podman Compose files, init scripts, docs, commit messages, branch names, tags, issues, or pull requests.
- Never write its name, path, image name, container name, hostname, repo name, or any identifier in a tracked file. Use only the generic phrase `private checkout` when a mention is unavoidable.
- If a private checkout appears in live output, skip it. Do not copy its compose file, do not add it to inventory, and do not include it in a commit.
- If a diff contains a private identifier, remove it from the tracked set before committing. Report the problem to the owner in chat without repeating the identifier.
- The AI GitOps cron follows this rule. Do not weaken it.

## Secrets and credentials

- Never type a password, token, API key, or card number into chat or a tool prompt.
- Never commit a real `.env` file, token, key, credential, or private URL.
- Use placeholders in examples. Commit only `.env.example` files.
- For root operations, get owner consent first. Use the documented helper container pattern instead of asking for a password.

## Evidence before claims

Put the command next to its real result. If a command could not run, say so. Never invent output.

| Check | Command | Expected |
|---|---|---|
| Container up | `podman ps --format '{{.Names}}\t{{.Status}}'` | Expected service is `Up` |
| Local status API | `curl -sS -o /dev/null -w '%{http_code}\n' http://192.168.0.240:3001/api/homelab` | `200` |
| Funnel | `curl -sS -o /dev/null -w '%{http_code}\n' https://takamatsu.tailb43e01.ts.net/homelab-status` | `200` |
| Public API | `curl -sS -o /dev/null -w '%{http_code}\n' https://w0pal.my.id/api/homelab` | `200` |
| Public page | `curl -sS -o /dev/null -w '%{http_code}\n' https://w0pal.my.id/now` | `200` |
| Boot config | `rc-update show default | grep -E 'cgroups|local'` | Both listed |

Do not call a service fixed until the public endpoint returns the expected status.

## Fresh clone

```sh
git clone https://github.com/w0pal/homelab.git
cd homelab
./bootstrap.sh
sudo ./bootstrap.sh --apply
sudo ./bootstrap.sh --apply --packages --containers
```

After bootstrap, verify in this order: runlevel, cgroup mount, Podman networks, container list, local API, funnel, public API, public page. Use the commands in `docs/troubleshooting-rules.md`.

## Auto commit

- Do not commit by hand while the AI cron is active. Let the cron commit.
- If a cron run hangs, cancel it before retrying.
- Each commit carries one feature and a non-empty Conventional Commit body that names the files and explains the change.
- The cron must ignore private checkouts and secrets. If either appears in a diff, stop before committing.
- After a push, verify `HEAD` matches `origin/main`.

## Recovery order

When a service is down, follow this chain:

```text
producer
  -> local API
  -> reverse proxy
  -> Tailscale funnel
  -> Vercel rewrite
  -> browser endpoint
```

Fix the earliest broken layer first. Recheck every later layer after a change. Never skip the public endpoint check.
