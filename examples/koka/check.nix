{ pkgs, ... }:
{
  packages = [ pkgs.koka ];
  run = "koka -O2 -o main main.kk >&2 && chmod +x main && ./main";
}
