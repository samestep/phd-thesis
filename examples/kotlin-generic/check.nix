{ pkgs, ... }:
{
  packages = [
    pkgs.kotlin
    pkgs.jdk
  ];
  run = ''
    kotlinc -nowarn expr.kt -include-runtime -d expr.jar >&2
    java -jar expr.jar
  '';
}
