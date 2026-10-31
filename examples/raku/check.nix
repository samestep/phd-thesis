{ pkgs, ... }:
{
  packages = [ pkgs.rakudo ];
  run = "raku expr.raku";
}
