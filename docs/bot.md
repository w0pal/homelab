# Bot

## Renovate (auto dependency updates)

This repo keeps a [Renovate](https://github.com/renovatebot/renovate) config
for GitHub Actions updates. The auto-commit workflow was removed, so there are
no workflow files left to update today. Container image refresh is handled
by `podman auto-update` every Monday at 03:00, described in
[Automation](automation.md#weekly-image-refresh). Check `renovate.json` for the
remaining rules.

Renovate pull requests use `.github/renovate-pr-template.md`. The old
GitHub Actions auto-commit workflow is retired; see
[retired experiments](retired-experiments.md).
