# Auto commit

## Hermes GitOps cron

A Hermes cron job watches the host every five minutes. It runs
`scripts/sync-homelab.sh`, reviews the diff, and groups changes by feature.
Each feature gets its own Conventional Commit with a short body that names the
files and explains the change. The job pushes to `main` once after all commits.

The job uses the `git-conventional-push` and `w0pal-writing-style` skills. It
never commits secrets or real `.env` files. It skips runs when nothing changed.

Documentation stays in sync too. The monitor includes `system/inventory.txt`,
so the AI job updates the README when a service is installed or removed. It
also runs `scripts/generate-bootstrap.sh`, so `bootstrap.sh` always reflects
the current snapshot. Documentation changes get their own Conventional Commit.
The full rules are in [ai-rules.md](ai-rules.md).

Private rule: internal, work, client, employer, professional, or non-homelab
projects are never included in inventory, README, bootstrap, docs, commits,
branch names, tags, issues, or pull requests. Use only the generic phrase
`private checkout` when a mention is unavoidable.

The Hermes cron job itself is not stored in this repo. It lives in the Hermes
profile. On a fresh host, `scripts/setup-hermes-cron.sh` installs the helper
scripts and registers the job through `hermes cron create`. The generated
`bootstrap.sh` calls that setup script, so a clone plus
`sudo ./bootstrap.sh --apply` brings back the dotfiles, service configs, OpenRC
services, and the AI GitOps cron.

## Monitoring the repo from Paseo

A Paseo workspace shows the history of its own agents and sessions, not the
full git log of the checkout. Its **Changes → Commits** panel is a diff against
the workspace base: on a synced `main` with no workspace commits on top,
`Commits 0` and `No commits ahead of base yet` are the expected result, not a
broken or empty repository. This filtering is intentional upstream
([issue #4882](https://github.com/getpaseo/paseo/issues/4882)); a repository-wide
history view has only been requested, not shipped
([discussion #7250](https://github.com/getpaseo/paseo/discussions/7250)).
The homelab git history is complete. `git rev-list --count HEAD` reports every
commit and the clone is not shallow. Use git or the monitor script for the whole
picture.

`scripts/repo-monitor.sh` is a read-only report: branch and sync state, dirty
files, the full commit graph, branches, the GitOps cron status and recent runs,
and HTTP status for the local API, funnel, public API, and public page. Set
`LIMIT=30` to shorten the commit graph.

```sh
./scripts/repo-monitor.sh
LIMIT=30 ./scripts/repo-monitor.sh
```

`paseo.json` registers the same report as the `repo-monitor` workspace script,
along with branch-name and commit-message rules for agents started in this
project. The Paseo **homelab repo monitor** schedule runs the report hourly and
posts a short summary in the app. The Hermes cron remains the authority for
committing and pushing; the Paseo monitor only reads.

## New containers

`scripts/sync-homelab.sh` compares every running container with the managed
list built from `podman/*.yml` and the two built-in workers. A container started
from a compose file outside this repo shows up as
`unmanaged_container_count` and `unmanaged_container_fingerprint` in
`system/inventory.txt`. Names are intentionally left out of the tracked file
because one could belong to a private checkout.

The count or fingerprint changing alters the monitor output, so the GitOps cron
wakes up even though no tracked file changed. The agent then inspects the live
container, skips anything private, adds a sanitized `podman/podman-<name>.yml`
for homelab services, and reruns the sync until the count returns to zero.
That compose file is the tracked change the cron commits.

The monitor now also emits a fresh retry token and a content fingerprint while
the repo is pending. A failed run is retried on the next tick instead of being
suppressed by identical output, and a same-size file edit still registers as a
change. Clean sync state produces no output and no agent run.

The installed copy in `~/.hermes/scripts` resolves the repo from the cron
workdir, with `$HOME/homelab` as fallback. It does not derive the repo from its
own script path, so it cannot end up watching the Hermes profile instead.

## Health check

The command-by-command check is in
[troubleshooting rules](troubleshooting-rules.md#auto-commit-health-check).
