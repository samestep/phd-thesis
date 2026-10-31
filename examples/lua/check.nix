{ pkgs, ... }:
{
  packages = [ pkgs.lua5_4 ];
  run = "lua main.lua";
}
