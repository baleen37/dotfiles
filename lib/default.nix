# Mitchell-style utilities - minimal functions only
{ nixpkgs }:
{
  # Platform detection
  getPlatform =
    system:
    if nixpkgs.lib.hasSuffix "-darwin" system then
      "darwin"
    else if nixpkgs.lib.hasSuffix "-linux" system then
      "linux"
    else
      throw "Unsupported system: ${system}";

  # User resolution
  getUser =
    {
      default ? "",
    }:
    let
      envUser = builtins.getEnv "USER";
    in
    if envUser != "" then envUser else default;
}
