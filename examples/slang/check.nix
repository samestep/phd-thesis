{ pkgs, ... }:
{
  packages = [ pkgs.shader-slang ];
  # Slang's CPU target: `slangc` emits C++ and compiles it with the C++
  # compiler on the `PATH` into an executable.
  run = "slangc main.slang -target executable -o main >&2 && ./main";
}
