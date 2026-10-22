{ pkgs, ... }:
{
  packages = [ pkgs.bash ];
  run = "bash expr.sh";
}
