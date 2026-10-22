{ pkgs, ... }:
{
  packages = [ pkgs.hare ];
  supported = pkgs.lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.hare;
  run = ''
    export XDG_CACHE_HOME=$HOME/cache
    hare build -o expr expr.ha >&2 && ./expr
  '';
}
