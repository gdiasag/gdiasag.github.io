{
  perSystem =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
        grammars:
        map (name: grammars.${name}) [
          "bash"
          "c"
          "comment"
          "cpp"
          "css"
          "diff"
          "go"
          "haskell"
          "html"
          "javascript"
          "json"
          "lua"
          "make"
          "markdown"
          "markdown_inline"
          "nix"
          "ocaml"
          "python"
          "racket"
          "ruby"
          "rust"
          "sql"
          "toml"
          "tsx"
          "typescript"
          "yaml"
          "zig"
        ]
      );
      runtime = lib.concatStringsSep "," ([ treesitter ] ++ treesitter.dependencies);
    in
    {
      packages.neovim = pkgs.writeShellApplication {
        name = "site-nvim";
        text = ''
          exec ${lib.getExe pkgs.neovim-unwrapped} --clean --headless --cmd 'set rtp^=${runtime}' "$@"
        '';
      };

      packages.highlight = pkgs.writeShellApplication {
        name = "nvim-highlight";
        text = ''
          exec ${lib.getExe config.packages.neovim} -l ${../_nvim/highlight.lua} "$@"
        '';
      };
    };
}
