{
  perSystem =
    { pkgs, lib, ... }:
    let
      inherit (import ./utils.nix) fontFile;

      family = "Commit Mono";

      faces =
        let
          face = file: weight: style: {
            file = "${pkgs.commit-mono}/share/fonts/truetype/${file}";
            inherit weight style;
          };
        in
        {
          regular = face "CommitMono-400-Regular.ttf" "normal" "normal";
          bold = face "CommitMono-700-Regular.ttf" "bold" "normal";
          italic = face "CommitMono-400-Italic.ttf" "normal" "italic";
          bold-italic = face "CommitMono-700-Italic.ttf" "bold" "italic";
        };

      partial = pkgs.writeText "_font.scss" ''
        $family: ${builtins.toJSON family};
        ${lib.concatStrings (
          lib.mapAttrsToList (name: face: ''
            @font-face {
              font-family: $family;
              font-weight: ${face.weight};
              font-style: ${face.style};
              font-display: swap;
              src: url("fonts/${fontFile name}") format("woff2")
            }
          '') faces
        )}
      '';
    in
    {
      packages.font = pkgs.runCommand "font" { nativeBuildInputs = [ pkgs.woff2 ]; } ''
        mkdir -p $out/fonts

        cp ${partial} $out/_font.scss
        
        ${lib.concatStrings (
          lib.mapAttrsToList (name: face: ''
            cp ${face.file} ${name}.ttf
            woff2_compress ${name}.tff
            mv ${name}.woff2 $out/fonts/${fontFile name}
          '') faces
        )}
      '';
    };
}
