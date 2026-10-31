{ moss, ... }:
{
  packages = [ moss ];
  shared = [ "common.moss" ];
  run = "moss main.moss";
}
