{ moss, ... }:
{
  packages = [ moss ];
  shared = [
    "common.moss"
    "arena.moss"
    "doubledouble.moss"
    "shadow.moss"
  ];
  run = "moss \"$main\"";
}
