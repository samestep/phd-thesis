{ pkgs, ... }:
{
  packages = [
    pkgs.rocq-core
    pkgs.rocqPackages.stdlib
  ];
  run = "rocq compile expr.v | sed -n 's/^ *= //p'";
}
