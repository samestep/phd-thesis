{ pkgs, ... }:
{
  packages = [ pkgs.nodejs ];
  run = "node main.mjs";
}
