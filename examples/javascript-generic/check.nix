{ pkgs, ... }:
{
  packages = [ pkgs.nodejs ];
  run = "node expr.mjs";
}
