{
  fontFile = face: "${face}.woff2";

  timestamp =
    date:
    let
      part = builtins.substring;
    in
      "${part 0 4 date}-${part 4 2 date}-${part 6 2 date} ${part 8 2 date}:${part 10 2 date}:${part 12 2 date} +0000";
}
