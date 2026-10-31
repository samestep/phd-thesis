{ pkgs, ... }:
{
  packages = [ pkgs.mlton ];
  run = "mlton -output main main.sml && ./main";
}
