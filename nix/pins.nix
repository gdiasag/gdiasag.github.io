let
  inherit (import ./utils.nix) timestamp;
  inherit (builtins.fromJSON (builtins.readFile ../npins/sources.json)) pins;

  pin =
    name:
      {
        repository,
        revision,
        hash,
        ...
      }:
      assert repository.type == "Github";
      let
        # Rather than npins' own `fetchTarball`, for the commit's date.
        tree = builtins.fetchTree {
          type = "github";
          inherit (repository) owner repo;
          rev = revision;
        };
        pinned = builtins.convertHash {
          inherit hash;
          hashAlgo = "sha256";
          toHashFormat = "sri";
        };
      in
      if tree.narHash != pinned then
        throw "${name} isn't what npins pinned: ${tree.narHash} rather than ${pinned}"
      else
        {
          source = tree.outPath;
          inherit (repository) owner repo;
          rev = revision;
          date = timestamp tree.lastModifiedDate;
        };
in
builtins.mapAttrs pin pins
