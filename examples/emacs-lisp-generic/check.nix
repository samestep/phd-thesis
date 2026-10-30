{ pkgs, ... }:
{
  packages = [ pkgs.emacs-nox ];
  run = "emacs --batch --quick --script expr.el";
}
