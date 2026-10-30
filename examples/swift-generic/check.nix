{ pkgs, ... }:
{
  packages = [ pkgs.swift ];
  run = ''
    swiftc expr.swift -o expr >&2
    ./expr
  '';
}
