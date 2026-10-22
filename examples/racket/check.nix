{ pkgs, ... }:
{
  packages = [ pkgs.racket ];
  run = "racket expr.rkt";
}
