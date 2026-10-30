{ pkgs, ... }:
{
  packages = [ pkgs.perl ];
  run = "perl expr.pl";
}
