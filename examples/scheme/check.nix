{ pkgs, ... }:
{
  packages = [ pkgs.guile ];
  run = "guile --no-auto-compile expr.scm";
}
