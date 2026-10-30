{ moss, ... }:
{
  packages = [ moss ];
  run = "moss expr.moss";
}
