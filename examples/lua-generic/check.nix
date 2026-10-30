{ pkgs, ... }:
{
  packages = [ pkgs.lua5_4 ];
  run = "lua expr.lua";
}
