{ lib, config, ... }:
let
  inherit (lib) mkOption types;
  pins = import ./pins.nix;

  names =
    directory:
    lib.optionals (builtins.pathExists directory) (
      map (file: builtins.head (lib.splitString "." file)) (
        builtins.attrNames (builtins.readDir directory)
      )
    );

  theme =
    { name, config, ... }:
    let
      pin = pins.${config.plugin};
    in
    {
      options = {
        plugin = mkOption {
          type = types.enum (builtins.attrNames pins);
          default = name;
          description = "The pin holding the colorscheme.";
        };
        colorscheme = mkOption {
          type = types.enum (names "${pin.source}/colors");
          default = name;
          description = "What `:colorscheme` loads.";
        };
        background = mkOption {
          type = types.enum [
            "dark"
            "light"
          ];
          default = "dark";
          description = "'background' while loading it.";
        };
        lualine = mkOption {
          type = types.enum (
            lib.concatMap (source: names "${source}/lua/lualine/themes") [
              pins.lualine.source
              pin.source
            ]
          );
          default = "auto";
          description = "lualine's theme for the status line.";
        };
        setup = mkOption {
          type = types.str;
          default = "";
          description = "Vim commands to run before loading it.";
        };

        # What the themes page lists: the plugin's pinned commit and its date.
        source = mkOption {
          type = types.path;
          readOnly = true;
          description = "The plugin's source.";
        };
        author = mkOption {
          type = types.str;
          readOnly = true;
          description = "The plugin's author.";
        };
        href = mkOption {
          type = types.str;
          readOnly = true;
          description = "The plugin's pinned commit.";
        };
        date = mkOption {
          type = types.str;
          readOnly = true;
          description = "When that commit was made.";
        };
      };

      config = {
        inherit (pin) source date;
        author = pin.owner;
        href = "https://github.com/${pin.owner}/${pin.repo}/tree/${pin.rev}";
      };
    };
in
{
  options.site = {
    themes = mkOption {
      type = types.attrsOf (types.submodule theme);
      default = { };
      description = "The site's themes, by name.";
    };
    defaultTheme = mkOption {
      type = types.enum (builtins.attrNames config.site.themes);
      description = "The theme a visitor sees before picking one.";
    };
    defaultLightTheme = mkOption {
      type = types.nullOr (
        types.enum (
          builtins.attrNames (lib.filterAttrs (_: theme: theme.background == "light") config.site.themes)
        )
      );
      default = null;
      description = "The theme a visitor whose system is in light mode sees instead, if any.";
    };
  };

  config.site = {
    defaultTheme = "melange";
    defaultLightTheme = "melange-light";
    themes = import ./data/themes.nix;
  };
}
