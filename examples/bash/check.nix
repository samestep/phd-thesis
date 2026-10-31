{ pkgs, ... }:
{
  packages = [ pkgs.bash ];
  run = "bash main.sh";
}
