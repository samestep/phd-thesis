{ pkgs, ... }:
{
  packages = [ pkgs.odin ];
  run = "odin run expr.odin -file";
}
