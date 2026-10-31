{ pkgs, ... }:
{
  # nixpkgs marks its Swift compiler broken on some platforms (aarch64-linux,
  # until Swift 6.4.0 switches its linker to LLD).
  supported = !pkgs.swiftPackages.swiftc.meta.broken;
  packages = [ pkgs.swift ];
  run = ''
    swiftc main.swift -o main >&2
    ./main
  '';
}
