{ pkgs, ... }:
{
  packages = [ pkgs.koka ];
  run = "koka -O2 -o expr expr.kk >&2 && chmod +x expr && ./expr";
}
