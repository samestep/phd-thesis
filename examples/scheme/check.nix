{ pkgs, ... }:
{
  packages = [ pkgs.guile ];
  run = "guile --no-auto-compile main.scm";
}
