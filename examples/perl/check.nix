{ pkgs, ... }:
{
  packages = [ pkgs.perl ];
  run = "perl main.pl";
}
