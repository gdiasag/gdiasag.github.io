{
  perSystem =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      packages.symbols =
        pkgs.runCommand "symbols"
          {
            nativeBuildInputs = [
              (pkgs.python3.withPackages (ps: [
                ps.fonttools
                ps.brotli
              ]))
            ];
            font = "${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols/SymbolsNerdFontMono-Regular.ttf";
          }
          ''
            pyftsubset "$font" --unicodes=U+E0A0,U+E712,U+F48A,U+F0219 --flavor=woff2 --output-file=symbols.woff2

            mkdir $out

            cat > $out/_symbols.scss <<EOF
            @font-face {
              font-family: "Symbols Nerd Font Mono";
              src: url(data:font/woff2;base64,$(base64 -w0 symbols.woff2)) format("woff2");
              unicode-range: U+E0A0, U+E712, U+F48A, U+F0219;
            }
            EOF
          '';

      packages.sass = pkgs.writeShellApplication {
        name = "site-sass";
        text = ''
          exec ${lib.getExe pkgs.dart-sass} --style=compressed \
            --load-path=${config.packages.colorschemes} --load-path=${config.packages.font} \
            --load-path=${config.packages.symbols} "$@"
        '';
      };

      packages.css = pkgs.runCommand "css" { } ''
        mkdir $out
        cp -r ${config.packages.font}/fonts $out/fonts
        ${lib.getExe config.packages.sass} --no-source-map ${
          lib.fileset.toSource {
            root = ../_sass;
            fileset = ../_sass;
          }
        }/main.scss $out/main.css
      '';
    };
}
