{ lib, config, ...}:
let
  inherit (config.site)
    favicon
    defaultTheme
    ;
  inherit (import ./utils.nix) fontFile;
in
{
  options.site.favicon = lib.mkOption {
    type = lib.types.str;
    description = "What the favicon shows";
  };

  config.site.favicon = ">_";

  config.perSystem =
    { pkgs, config, ...}:
    {
      packages.favicon =
        pkgs.runCommand "favicon"
          {
            nativeBuildInputs = [
              (pkgs.python3.withPackages (ps: [
                ps.fonttools
                ps.brotli
              ]))
            ];
          }
          ''
            mkdir $out

            python3 ${../scripts/favicon.py} ${config.packages.font}/fonts/${fontFile "regular"} \
              ${config.packages.colorschemes}/_colorschemes.scss \
              ${
                lib.escapeShellArgs [
                  defaultTheme
                  favicon
                ]
              } > $out/favicon.svg
          '';
    };
}

