{ pkgs, ... }:
{
  packages = [
    pkgs.kotlin
    pkgs.jdk
  ];
  run = ''
    kotlinc -nowarn main.kt -include-runtime -d main.jar >&2
    java -jar main.jar
  '';
}
