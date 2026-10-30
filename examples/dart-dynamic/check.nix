{ pkgs, ... }:
{
  packages = [ pkgs.dart ];
  run = ''
    export PUB_CACHE=$HOME/pub
    dart --disable-analytics run expr.dart
  '';
}
