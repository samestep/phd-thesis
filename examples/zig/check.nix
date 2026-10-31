{ pkgs, ... }:
{
  packages = [ pkgs.zig ];
  run = ''
    export ZIG_GLOBAL_CACHE_DIR=$HOME/zig-cache ZIG_LOCAL_CACHE_DIR=$HOME/zig-local
    zig run main.zig 2>&1
  '';
}
