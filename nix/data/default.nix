{ lib, ... }:
let
  inherit (lib) mkOption types;

  date = types.strMatching "[0-9]{4}-[0-9]{2}-[0-9]{2}";

  field = type: description: mkOption { inherit type description; };
  optional = 
    type: description:
    mkOption {
      type = types.nullOr type;
      default = null;
      inherit description;
    };

  listing =
    description: options: check:
    mkOption {
      type = types.listOf (types.submodule { inherit options; });
      default = [ ];
      apply = map (entry: check (lib.filterAttrs (_: value: value != null) entry));
      inherit description;
    };

  pdfIn =
    directory: entry:
    lib.warnIf (
      entry ? pdf && builtins.pathExists (../.. + "/${directory}/${entry.pdf})")
    ) "${directory}/${entry.pdf} is listed in nix/data/${directory}.nix, but isn't there" entry;

  entry = {
    title = field types.str "Its name in the listing.";
    date = field date "Its date in the listing.";
    symlink = optional types.str "Where the symlink leads.";
    pdf = optional types.str "The PDF's file name.";
    size = optional types.ints.positive "The PDF's size, in bytes.";
  };
in
{
  options.site.data = {
    books = listing "The books/ listing." entry (pdfIn "books");
    slides = listing "The slides/ listing." (
      entry // { extension = optional types.str "The symlink's extension, mp4 unless set."; }
    ) (pdfIn "slides");
    external-posts = listing "Posts published elsewhere, symlinks in the notes/ listing." {
      title = field types.str "The post's title.";
      date = field date "When it was published.";
      href = field types.str "Where it was published.";
      size = optional types.ints.positive "Its size, in bytes.";
    } lib.id;
  };

  config.site.data = {
    books = import ./books.nix;
    slides = import ./slides.nix;
    external-posts = import ./external-posts.nix;
  };
}
