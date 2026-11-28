{
  description = "Pinned CLI tools for the homelab host";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      phpWithExtensions = pkgs:
        pkgs.php83.withExtensions ({ enabled, all }: enabled ++ (with all; [
          bcmath
          curl
          dom
          gd
          intl
          mbstring
          opcache
          pcntl
          pdo_mysql
          pdo_sqlite
          phar
          posix
          session
          simplexml
          sockets
          sodium
          tokenizer
          xml
          xmlreader
          xmlwriter
          zip
        ]));

      tools = pkgs: with pkgs; [
        btop
        binutils
        cargo
        chafa
        cmake
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
        pciutils
        poppler-utils
        rclone
        ripgrep
        rsync
        smartmontools
        speedtest-cli
        tesseract
        tree-sitter
        usbutils
        yazi
        zoxide
        (phpWithExtensions pkgs)
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
