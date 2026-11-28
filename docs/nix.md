# Nix package layer

This flake pins a small set of userland CLI tools. It does not replace apk or OpenRC.

## What is pinned

`flake.nix` declares btop, chafa, eza, fastfetch, fd, fzf, gh, jq, lazygit, rclone, ripgrep, yazi and zoxide. The dev shell adds Go, Node.js and Python without putting them in the host profile.

`flake.lock` is the pin. Commit it whenever it changes. A rebuild from the same lockfile gets the same package versions on this host or another one.

## How the host uses it

`nix` is listed in `system/etc/apk/world`. On a fresh clone, `bootstrap.sh --apply --packages` installs it and gives `/nix` to the target user. This is single-user Nix, so there is no daemon and no extra group to manage.

zsh puts `$HOME/.nix-profile/bin` ahead of the apk paths. The Nix versions of the tools above win when both are installed. The apk copies stay as a fallback.

zsh also adds `$HOME/.nix-profile/share/zsh/site-functions` to `fpath`, so completions keep working after the apk completion packages are removed.

The `gh` wrappers in `configs/local-bin/` select the GitHub account from the repo owner. They now call the Nix binary instead of the removed `/usr/bin/gh`. They read tokens from `gh auth token` at runtime. Never hardcode a token in those scripts.

Install or refresh the profile from the repo:

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
nix profile install path:$HOME/homelab#default
nix profile upgrade '.*'
```

Enter the pinned dev shell with `nix develop path:$HOME/homelab`.

If Nix warns that `/nix/var/nix` does not exist, create `/nix/var/nix` and `/nix/store` before installing the profile. Without those directories Nix falls back to a chroot store under `~/.local/share/nix/root`. That leftover can be deleted after a successful install into `/nix/store`.

## Why not all 257 apk packages

A lot of that list is libraries, firmware, build dependencies and OpenRC pieces. Nix resolves dependencies from the store, so those entries do not need to be declared twice. apk still owns the kernel, init, services, shell and editor that bootstrap depends on. Moving those would add risk without helping the container layer.

## glibc on Alpine

Nix-built binaries carry their own glibc under `/nix/store`, so these tools run on musl without `gcompat`. A vendor installer that checks for Alpine is a different problem. Use the nixpkgs version when it exists. For a downloaded binary, use `gcompat` or a Podman container.

## Current status

The flake and docs are in the repo. Installing Nix on the live host still needs the initial root step. Until that runs, `nix` is not available on `takamatsu`.
