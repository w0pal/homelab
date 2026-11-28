# Nix package layer

This flake pins userland CLI tools and dev toolchains. It does not replace apk, OpenRC or the container runtime.

## What is pinned

`flake.nix` declares btop, binutils, cargo, chafa, claude-code, cmake, codex, composer, dmidecode, eza, fastfetch, fd, ffmpeg, fio, fzf, gh, ghostscript, go, gcc, htop, imagemagick, inxi, iw, jq, lazygit, m4, gnumake, neovim, nmap, nodejs, paseo, pciutils, poppler-utils, rclone, ripgrep, smartmontools, speedtest-cli, tailscale, tesseract, tmux, tree-sitter, usbutils, yazi, zoxide, zsh and php83. The dev shell adds Go, Node.js and Python without putting them in the host profile.

Claude Code and Codex replace the npm globals `@anthropic-ai/claude-code` and `@openai/codex`, and Paseo replaces `@getpaseo/cli`. Their npm copies have been removed. `claude-code` is unfree, so the flake imports nixpkgs with `allowUnfree = true`. Paseo comes from nixpkgs (`paseo` 0.16.2) and its OpenRC unit calls the Nix binary by absolute path because daemons do not inherit the zsh PATH. 9router stays on the npm-global copy, currently 0.5.123, because nixpkgs is several patch versions behind. Its unit runs that CLI with the Nix `node` and leaves `--skip-update` off so the CLI can auto-update. Only codebuddy, bansos-router and Vercel remain on npm besides 9router: nixpkgs has no usable package for them, and `vercel-pkg` provides `pkg`, not the Vercel CLI.

`flake.lock` is the pin. Commit it whenever it changes. A rebuild from the same lockfile gets the same package versions on this host or another one.

## How the host uses it

`nix` is listed in `system/etc/apk/world`. On a fresh clone, `bootstrap.sh --apply --packages` installs it, creates `/nix/var/nix` and `/nix/store`, gives `/nix` to the target user, and installs this flake's profile as that user. No manual `npm install -g` is needed for Claude Code, Codex or Paseo. 9router remains an npm-global install because the npm copy is newer.

The remaining npm-global CLIs are tracked as a pinned manifest in `configs/npm-global/package.json`. `bootstrap.sh --apply --packages` installs that manifest into `$HOME/.npm-global`. `scripts/sync-npm-global.sh` refreshes the manifest from the live install, so an auto-update such as 9router becomes a repo diff. `node_modules` are never committed. Bootstrap also approves npm install scripts with pinned entries for a fresh clone.

zsh puts `$HOME/.nix-profile/bin` ahead of the apk paths, so the Nix versions win while both exist. It also adds `$HOME/.nix-profile/share/zsh/site-functions` to `fpath`, so completions keep working after the apk completion packages are removed.

The `gh` wrappers in `configs/local-bin/` select the GitHub account from the repo owner. They call the Nix binary instead of the removed `/usr/bin/gh`. They read tokens from `gh auth token` at runtime. Never hardcode a token in those scripts.

`bootstrap.sh --apply --packages` does this on a fresh host. To refresh an existing profile without a full bootstrap:

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
nix profile install path:$HOME/homelab#default
nix profile upgrade homelab
```

Enter the pinned dev shell with `nix develop path:$HOME/homelab`.

If Nix warns that `/nix/var/nix` does not exist, create `/nix/var/nix` and `/nix/store` before installing the profile. Without those directories Nix falls back to a chroot store under `~/.local/share/nix/root`. That leftover can be deleted after a successful install into `/nix/store`.

## What stays on apk

The remaining `system/etc/apk/world` entries are boot, firmware, init, network, container and basic shell packages. Examples: `linux-lts`, `linux-firmware-*`, `grub-efi`, `mdadm`, `nftables`, `dnsmasq`, `openssh`, the Podman stack, and basic commands such as `lsblk`, `coreutils`, `sed`, `grep`, `tar`, `curl`, `git` and `rsync`. The 03:00 Nextcloud backup cron calls `rsync` with cron's default PATH, so rsync stays on apk.

The OpenRC unit for paseo calls its Nix binary by absolute path. The 9router unit runs the npm-global CLI with the Nix `node`, with auto-update enabled. portfolio-api still calls the Nix `node`, and `ensure-portfolio-api.sh` uses the Nix `tmux`, `npm` and `tailscale` CLI. The apk `tailscale` package still provides `tailscaled` and its OpenRC service; the Nix CLI talks to that daemon and warns about a version mismatch. The apk `zsh` stays because `/bin/zsh` is the login shell in `/etc/passwd` and is the only zsh entry in `/etc/shells`. Changing that needs a root shell change, so the login shell stays on apk while `zsh` typed in a session resolves to Nix.

`sync-homelab.sh` filters the Nix-owned entries out of the apk snapshot so the GitOps cron cannot reintroduce them. Library packages that are still needed by retained apk packages remain as apk dependencies, not as duplicate userland commands.

## glibc on Alpine

Nix-built binaries carry their own glibc under `/nix/store`, so these tools run on musl without `gcompat`. A vendor installer that checks for Alpine is a different problem. Use the nixpkgs version when it exists. For a downloaded binary, use `gcompat` or a Podman container.

## Current status

Nix 2.31.5 is installed on `takamatsu` and the profile points at the locked `homelab-userland` store path. The apk copies of the migrated tools are removed by the owner with `apk del`; until then they are only fallbacks behind the Nix profile.
