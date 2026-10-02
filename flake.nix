{
  description = "gustavo's terminal";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        ./nix/add.nix
        ./nix/colorschemes.nix
        ./nix/data
        ./nix/dev.nix
        ./nix/favicon.nix
        ./nix/fonts.nix
        ./nix/gems.nix
        ./nix/neovim.nix
        ./nix/site.nix
        ./nix/styles.nix
        ./nix/themes.nix
      ];
    };
}
