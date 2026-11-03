{ pkgs, ... }:
{
  packages = [ (pkgs.python3.withPackages (ps: [ ps.mpmath ])) ];
  run = "python3 main.py";
}
