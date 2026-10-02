{
  self,
  config,
  ...
}:
let
  inherit (config.site)
    themes
    defaultTheme
    defaultLightTheme
    data
    ;
  inherit (import ./lib.nix) timestamp fontFile;
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
      buildConfig = pkgs.writeText "_config.build.yml" (
        builtins.toJSON (
          {
            time = timestamp (self.lastModifiedDate or "19700101000000");
            build = {
              branch = "main";
              revision = self.rev or self.dirtyRev or "unknown";
              ruby = pkgs.ruby.version;
              neovim = pkgs.neovim-unwrapped.version;
            };
            themes = lib.mapAttrsToList (name: theme: {
              inherit name;
              inherit (theme) author href date;
              default = name == defaultTheme;
              default_light = name == defaultLightTheme;
            }) themes;
            font.regular = "/css/fonts/${fontFile "regular"}";
            kramdown.syntax_highlighter_opts.command = lib.getExe config.packages.highlight;
          }
          // data
        )
      );

      jekyll = "${config.packages.gems}/bin/jekyll";
      sass = lib.getExe config.packages.sass;
    in
    {
      packages.default = pkgs.stdenvNoCC.mkDerivation {
        name = "site";

        src = lib.fileset.toSource {
          root = ../.;
          fileset = lib.fileset.difference ../. (
            lib.fileset.unions [
              ../flake.nix
              ../flake.lock
              ../nix
              ../npins
              ../Gemfile
              ../Gemfile.lock
              ../gemset.nix
              ../_nvim
              ../_sass
              ../.github
              ../.gitignore
            ]
          );
        };

        LC_ALL = "C.UTF-8";
        JEKYLL_ENV = "production";

        buildPhase = ''
          runHook preBuild

          cp -r --no-preserve=mode ${config.packages.css} css

          install -m 644 ${config.packages.favicon}/favicon.svg favicon.svg

          ${jekyll} build --trace --config _config.yml,${buildConfig}

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall

          cp -r _site $out
          
          runHook postInstall
        '';
      };

      packages.serve = pkgs.writeShellApplication {
        name = "serve";
        text = ''
          export LC_ALL=C.UTF-8

          install -D -m 644 -t css/fonts ${config.packages.font}/fonts/*
          install -m 644 ${config.packages.favicon}/favicon.svg favicon.svg
          
          ${sass} _sass/main.scss css/main.css
          ${sass} --watch _sass/main.scsss:csss/main.css &

          trap 'kill $!' EXIT
          
          ${jekyll} serve --trace --drafts --config _config.yml,${buildConfig} "$@"
        '';
      };

      apps.default.program = config.packages.serve;
    };
}
