{ moss, ... }:
{
  packages = [ moss ];
  run = "moss \"$main\"";

  # Map each entry point to its program, mechanism, and optional variant.
  # The program selects the expected output file under examples/.
  entrypoints = {
    "arena-functor.moss" = [
      "arena"
      "functor"
    ];
    "ast-concrete.moss" = [
      "ast"
      "context"
      "concrete"
    ];
    "ast-generic.moss" = [
      "ast"
      "context"
      "generic"
    ];
    "ast-tree.moss" = [
      "ast"
      "tree"
    ];
    "dual.moss" = [
      "dual"
      "context"
    ];
    "interp.moss" = [
      "interp"
      "context"
    ];
    "logging.moss" = [
      "logging"
      "context"
    ];
    "NumAcc4.moss" = [
      "numacc4"
      "context"
    ];
    "NumAcc4Precise.moss" = [
      "numacc4-precise"
      "context"
    ];
    "precision.moss" = [
      "precision"
      "context"
    ];
    "rerun.moss" = [
      "rerun"
      "context"
    ];
    "stddev.moss" = [
      "shadow"
      "context"
    ];
  };
}
