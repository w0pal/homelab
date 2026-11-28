# Nix package layer

This flake pins userland CLI tools and dev toolchains. It does not replace apk, OpenRC or the container runtime.

## What is pinned

`flake.nix` declares btop, binutils, cargo, chafa, cmake, composer, dmidecode, eza, fastfetch, fd, ffmpeg, fio, fzf, gh, ghostscript, go, gcc, htop, imagemagick, inxi, iw, jq, lazygit, m4, gnumake, neovim, nmap, pciutils, poppler-utils, rclone, ripgrep, smartmontools, speedtest-cli, tesseract, tree-sitter, usbutils, yazi, zoxide and php83. The dev shell adds Go, Node.js and Python without putting them in the host profile.

`flake.lock` is the pin. Commit it whenever it changes. A rebuild from the same lockfile gets the same package versions on this host or another one.

## How the host uses it

`nix` is listed in `system/etc/apk/world`. On a fresh clone, `bootstrap.sh --apply --packages` installs it and creates `/nix/var/nix` and `/nix/store`, then gives `/nix` to the target user. This is single-user Nix, so there is no daemon and no extra group to manage.

zsh puts `$HOME/.nix-profile/bin` ahead of the apk paths, so the Nix versions win while both exist. It also adds `$HOME/.nix-profile/share/zsh/site-functions` to `fpath`, so completions keep working after the apk completion packages are removed.

The `gh` wrappers in `configs/local-bin/` select the GitHub account from the repo owner. They call the Nix binary instead of the removed `/usr/bin/gh`. They read tokens from `gh auth token` at runtime. Never hardcode a token in those scripts.

Install or refresh the profile from the repo:

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
nix profile install path:$HOME/homelab#default
nix profile upgrade homelab
```

Enter the pinned dev shell with `nix develop path:$HOME/homelab`.

If Nix warns that `/nix/var/nix` does not exist, create `/nix/var/nix` and `/nix/store` before installing the profile. Without those directories Nix falls back to a chroot store under `~/.local/share/nix/root`. That leftover can be deleted after a successful install into `/nix/store`.

## What stays on apk

The remaining `system/etc/apk/world` entries are boot, firmware, init, network, container and basic shell packages. Examples: `linux-lts`, `linux-firmware-*`, `grub-efi`, `mdadm`, `nftables`, `dnsmasq`, `openssh`, `tailscale`, the Podman stack, `nodejs` and `npm` for the OpenRC services, `/usr/bin/tmux` for `ensure-portfolio-api.sh`, and basic commands such as `lsblk`, `coreutils`, `sed`, `grep`, `tar`, `curl`, `git` and `rsync`. The 03:00 Nextcloud backup cron calls `rsync` with cron's default PATH, so rsync stays on apk.

`sync-homelab.sh` filters the Nix-owned entries out of the apk snapshot so the GitOps cron cannot reintroduce them. Library packages that are still needed by retained apk packages remain as apk dependencies, not as duplicate userland commands.

## glibc on Alpine

Nix-built binaries carry their own glibc under `/nix/store`, so these tools run on musl without `gcompat`. A vendor installer that checks for Alpine is a different problem. Use the nixpkgs version when it exists. For a downloaded binary, use `gcompat` or a Podman container.

## Current status

Nix 2.31.5 is installed on `takamatsu` and the profile points at the locked `homelab-userland` store path. The apk copies of the migrated tools are removed by the owner with `apk del`; until then they are only fallbacks behind the Nix profile.
