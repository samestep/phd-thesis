{ pkgs, ... }:
{
  packages = [ pkgs.nim ];
  run = "nim r --hints:off --nimcache:$HOME/nimcache expr.nim";
}
