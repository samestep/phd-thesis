{ pkgs, ... }:
{
  packages = [ pkgs.rocq-core ];
  run = "rocq compile expr.v | sed -n 's/^ *= //p'";
}
