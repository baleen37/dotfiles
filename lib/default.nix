# Mitchell-style utilities - minimal functions only
{ nixpkgs }:
{
  /*
    Platform detection utility

    Extracts the platform family from a system string by examining the suffix.
    This provides a simplified platform classification for cross-platform
    configuration management.

    Args:
      system (string): The full system identifier (e.g., "x86_64-darwin", "aarch64-linux")

    Returns:
      string: "darwin" for macOS systems, "linux" for Linux systems

    Throws:
      Error: If the system string doesn't end with "-darwin" or "-linux"

    Examples:
      getPlatform "x86_64-darwin"  # => "darwin"
      getPlatform "aarch64-linux"  # => "linux"
      getPlatform "windows-x86_64" # => throws error
  */
  getPlatform =
    system:
    if nixpkgs.lib.hasSuffix "-darwin" system then
      "darwin"
    else if nixpkgs.lib.hasSuffix "-linux" system then
      "linux"
    else
      throw "Unsupported system: ${system}";

  /*
    User resolution utility

    Resolves the current username by first checking the USER environment
    variable, then falling back to a provided default value. This enables
    flexible user detection in both impure and pure evaluation contexts.

    Args:
      attrs.default (string, optional): Fallback username when USER env var is empty.
                                       Defaults to empty string if not provided.
                                       Must be non-empty when used as fallback.

    Returns:
      string: The username from USER environment variable or default value

    Throws:
      Error: If default is empty and USER environment variable is also empty

    Examples:
      getUser { default = "nixuser"; }  # When USER is set, returns USER value
      getUser { default = "nixuser"; }  # When USER is empty, returns "nixuser"
      getUser { }                      # When USER is set, returns USER value
      getUser { }                      # When USER is empty, throws error
  */
  getUser =
    {
      default ? "",
    }:
    let
      envUser = builtins.getEnv "USER";
      result = if envUser != "" then envUser else default;
      # Trim whitespace from result and check if it's empty
      trimmedResult = nixpkgs.lib.strings.trim result;
    in
    if trimmedResult == "" then
      throw "getUser: Cannot determine username - USER environment variable is empty and no valid default provided"
    else
      trimmedResult;
}
