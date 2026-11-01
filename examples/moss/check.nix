{ moss, ... }:
{
  packages = [ moss ];
  shared = [
    "common.moss"
    "arena.moss"
  ];
  run = "moss main.moss";
}
