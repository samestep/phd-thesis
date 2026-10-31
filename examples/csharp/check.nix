{ pkgs, ... }:
{
  packages = [ pkgs.dotnet-sdk_10 ];
  # On macOS, .NET finds the local app data folder that file-based apps
  # keep their artifacts in through Foundation, which ignores $HOME (the
  # build user's home is /var/empty) unless CFFIXED_USER_HOME says otherwise.
  run = ''
    export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_CLI_HOME=$HOME NUGET_PACKAGES=$HOME/nuget NuGetAudit=false
    export CFFIXED_USER_HOME=$HOME
    mkdir -p "$HOME/Library/Application Support"
    dotnet run main.cs
  '';
}
