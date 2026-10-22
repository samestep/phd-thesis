{ pkgs, ... }:
{
  packages = [ pkgs.unison-ucm ];
  # A transcript loads the file into a fresh codebase and compiles `main`.
  run = "ucm transcript build.md </dev/null >&2 && ucm run.compiled expr.uc </dev/null 2>/dev/null";
}
