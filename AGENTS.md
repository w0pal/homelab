# Agent rules

Read `docs/ai-rules.md` before troubleshooting, cloning, or changing files in this repo.

The strict rule: never include internal, work, client, employer, professional, or non-homelab projects in this repository, its inventory, bootstrap, docs, commits, branches, tags, issues, or pull requests. If a private checkout appears in live output, skip it and use only the generic phrase `private checkout` when a mention is unavoidable.

Never commit secrets, real `.env` files, tokens, or keys. Get owner consent before root operations. Do not type passwords into chat or tools. Verify every claim with a real command result and check the public endpoint before calling a service fixed.

Let the Hermes AI cron commit. Do not commit by hand while it is active.

## Install these dotfiles on another machine

When the owner asks to install the dotfiles from
`https://github.com/w0pal/homelab`, carry out the install. Do not stop at a
description.

1. Clone the repo, then read `README.md`, `docs/ai-rules.md`, and this file.
2. Detect the target user and home. Never assume a username:
   ```sh
   USER_NAME=${SUDO_USER:-$(id -un)}
   HOME_DIR=$(getent passwd "$USER_NAME" | cut -d: -f6)
   ```
3. Read `/etc/os-release`. Map the package names in `system/etc/apk/world` to
   the local package manager: `apk` on Alpine, `apt` on Debian and Ubuntu,
   `dnf` on Fedora, `pacman` on Arch. Install the equivalent tools, not the
   literal Alpine package list.
4. Copy `configs/zsh/.zshrc` to `$HOME_DIR/.zshrc`, the rest of `configs/zsh`
   to `$HOME_DIR/.config/zsh`, and `configs/nvim` to `$HOME_DIR/.config/nvim`.
   Those files use `$HOME`, so they work for any user.
5. Run `./bootstrap.sh` first as a dry run, then `sudo ./bootstrap.sh --apply`.
   Bootstrap renders the `{{HOMELAB_USER}}` and `{{HOMELAB_HOME}}` placeholders in
   the OpenRC files from `$USER_NAME` and `$HOME_DIR`.
6. On a systemd host, translate `init/*.openrc` into systemd units with the
   rendered user and paths. Do not install OpenRC units there.
7. Skip `--containers` unless the owner wants services started. Real `.env`
   files stay local and never travel with the repo.
8. Verify with `git status`, `zsh -n`, and a fresh bootstrap dry run. Report
   what was installed and what was skipped.

No tracked file should contain the original username or its home path. If a
host snapshot brings one back, replace it with the placeholders above before
any commit.
