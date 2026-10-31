{ pkgs, ... }:
{
  packages = [
    pkgs.rocq-core
    pkgs.rocqPackages.stdlib
  ];
  run = "rocq compile main.v | sed -n 's/^ *= //p'";
}
