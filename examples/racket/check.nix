{ pkgs, ... }:
{
  packages = [ pkgs.racket ];
  run = "racket main.rkt";
}
