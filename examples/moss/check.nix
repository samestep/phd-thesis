{ moss, ... }:
{
  packages = [ moss ];
  shared = [
    "common.moss"
    "arena.moss"
    "doubledouble.moss"
  ];
  run = "moss \"$main\"";
}
