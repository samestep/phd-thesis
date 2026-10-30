{ pkgs, ... }:
{
  packages = [ pkgs.c3c ];
  run = "c3c compile expr.c3 -o expr >&2 && ./expr";
}
