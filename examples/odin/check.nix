{ pkgs, ... }:
{
  packages = [ pkgs.odin ];
  run = "odin run main.odin -file";
}
