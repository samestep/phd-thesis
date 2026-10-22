{ pkgs, ... }:
let
  # Effekt isn't in nixpkgs; this is its official release, a self-running JAR.
  effekt = pkgs.fetchurl {
    url = "https://github.com/effekt-lang/effekt/releases/download/v0.82.0/effekt.tgz";
    hash = "sha256-hLO4z4uLeCiGXX5F9xI7/MlAZk+uI2WyYnGsFfFx4lI=";
  };
in
{
  packages = [
    pkgs.jdk
    pkgs.nodejs
  ];
  run = ''
    tar -xzf ${effekt}
    java -Xss32m -jar package/bin/effekt --build expr.effekt >&2
    node -e "require('./out/expr.js').main()"
  '';
}
