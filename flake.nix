{
  description = "Pinned CLI tools for the homelab host";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));

      tools = pkgs: with pkgs; [
        btop
        binutils
        cargo
        chafa
        claude-code
        cmake
        codex
        (php83Packages.composer)
        dmidecode
        eza
        fastfetch
        fd
        ffmpeg
        fio
        fzf
        gh
        ghostscript
        go
        gcc
        htop
        imagemagick
        inxi
        iw
        jq
        lazygit
        m4
        gnumake
        neovim
        nmap
        nodejs
        paseo
        pciutils
        poppler-utils
        rclone
        ripgrep
        smartmontools
        speedtest-cli
        tailscale
        tesseract
        tmux
        tree-sitter
        usbutils
        yazi
        zoxide
        zsh
        php83
      ];
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.buildEnv {
          name = "homelab-userland";
          paths = tools pkgs;
          pathsToLink = [ "/bin" "/share" ];
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = tools pkgs ++ [ pkgs.go pkgs.nodejs pkgs.python3 ];
        };
      });
    };
}
