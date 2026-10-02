{
  perSystem =
    { pkgs, config, ...}:
    {
      formatter = pkgs.nixfmt;

      devShells.default = pkgs.mkShell {
        packages = [
          config.packages.gems
          config.packages.neovim
          config.packages.sass
          pkgs.bundix
          pkgs.npins
        ];
      };
    };
}
