{
  perSystem =
    { pkgs, ... }:
    {
      packages.add = pkgs.writeShellApplication {
        name = "add";
        runtimeInputs = [
          pkgs.git
          pkgs.nixfmt
          pkgs.npins
          pkgs.python3
        ];

        text = ''
          exec python3 ${../scripts/add.py} "$@"
        ''
      }
    }
}
