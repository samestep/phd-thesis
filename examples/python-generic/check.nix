{ pkgs, ... }:
{
  packages = [ pkgs.python3 ];
  run = "python3 expr.py";
}
