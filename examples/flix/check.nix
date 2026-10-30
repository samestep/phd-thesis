{ pkgs, ... }:
{
  packages = [ pkgs.flix ];
  # On macOS the JVM takes `user.home` from the build user's account
  # (/var/empty), not from $HOME, and resolving dependencies writes there.
  run = ''
    export JAVA_TOOL_OPTIONS=-Duser.home=$HOME
    flix run 2>/dev/null
  '';
}
