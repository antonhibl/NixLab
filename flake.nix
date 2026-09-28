{
  description = "nixlab — the shared toolchain as an installable env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    dracula-nvim = {
      url = "github:maxmx03/dracula.nvim/7fadc372bbb9638c19a18c2497167d854cdd6a19";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, dracula-nvim }:
    let
      systems = [ "aarch64-linux" "x86_64-linux" ];
      forAll = f: nixpkgs.lib.genAttrs systems (s: f nixpkgs.legacyPackages.${s});
    in
    {
      packages = forAll (pkgs:
        let nvim = import ./nvim-plugins.nix { inherit pkgs dracula-nvim; };
        in {
          toolchainEnv = pkgs.buildEnv { name = "nixlab-tools"; paths = import ./toolchain.nix pkgs; };
          nvimPlugins = nvim.plugins;
          nvimTreesitter = nvim.treesitter;
        });

      devShells = forAll (pkgs: {
        default = pkgs.mkShell { packages = import ./toolchain.nix pkgs; };
      });
    };
}
