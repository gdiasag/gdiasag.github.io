{ config, ... }:
let
  inherit (config.site) themes;
  pins = import ./pins.nix;
in
{
  perSystem =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      colorscheme =
        name: theme:
        pkgs.runCommand "colorscheme-${name}.scss" { } ''
          export HOME=$TMPDIR
          ${lib.getExe config.packages.neovim} \
            --cmd 'set rtp^=${theme.source},${pins.lualine.source},${pins.nvim-web-devicons.source}' \
            -l ${../_nvim/theme.lua} \
            ${
              lib.escapeShellArgs [
                name
                theme.colorscheme
                theme.background
                theme.lualine
                theme.setup
              ]
            } > $out
        '';
    in
    {
      packages.colorschemes = pkgs.runCommand "colorschemes" { } ''
        mkdir $out
        cat ${lib.concatStringsSep " " (lib.mapAttrsToList colorscheme themes)} > $out/_colorschemes.scss
      '';
    };
}
