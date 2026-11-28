{
  description = "Pinned CLI tools for the homelab host";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      tools = pkgs: with pkgs; [
        btop
        chafa
        eza
        fastfetch
        fd
        fzf
        gh
        jq
        lazygit
        rclone
        ripgrep
        yazi
        zoxide
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
