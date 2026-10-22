{ pkgs, ... }:
{
  packages = [ pkgs.eff ];
  # The toplevel echoes every definition's type; keep only what the program prints.
  run = "eff expr.eff 2>/dev/null | grep -Ev '^(val |- : )'";
}
