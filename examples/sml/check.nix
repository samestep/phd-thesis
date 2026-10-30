{ pkgs, ... }:
{
  packages = [ pkgs.mlton ];
  run = "mlton -output expr expr.sml && ./expr";
}
