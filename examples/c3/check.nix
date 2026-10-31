{ pkgs, ... }:
{
  packages = [ pkgs.c3c ];
  run = "c3c compile main.c3 -o main >&2 && ./main";
}
