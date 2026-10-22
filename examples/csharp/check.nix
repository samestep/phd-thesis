{ pkgs, ... }:
{
  packages = [ pkgs.dotnet-sdk_10 ];
  run = ''
    export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1 DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
    export DOTNET_CLI_HOME=$HOME NUGET_PACKAGES=$HOME/nuget NuGetAudit=false
    dotnet run expr.cs
  '';
}
