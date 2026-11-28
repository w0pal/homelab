# Issues

Notes on behavior that looks broken but is expected, plus pointers for real
failures.

## Paseo Changes shows `Commits 0`

The **Changes → Commits** panel in Paseo lists only commits a workspace adds
on top of its base branch. On a synced `main` with a clean tree, `Commits 0`
and `No commits ahead of base yet` are expected; they do not mean the repo has
no history. Upstream confirmed the filtering is intentional
([issue #4882](https://github.com/getpaseo/paseo/issues/4882)), and a
repository-wide history view is still only a request
([discussion #7250](https://github.com/getpaseo/paseo/discussions/7250)).

To see the full history, run `./scripts/repo-monitor.sh` from the repo root or
start the `repo-monitor` script in Paseo. See
[auto commit](auto-commit.md#monitoring-the-repo-from-paseo) for the details.

## GitOps cron looks stuck

Check the active job, its recent runs, and whether `HEAD` matches `origin/main`.
The full check table is in
[troubleshooting rules](troubleshooting-rules.md#auto-commit-health-check).
Do not commit by hand while the cron is active.

## Retired jobs

Old watchers and workflows are listed in
[retired experiments](retired-experiments.md).
