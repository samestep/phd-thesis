{ pkgs, ... }:
{
  packages = [ pkgs.flix ];
  run = "flix run 2>/dev/null";
}
