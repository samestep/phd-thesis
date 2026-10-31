{ pkgs, ... }:
{
  packages = [ pkgs.rakudo ];
  run = "raku main.raku";
}
