# Shared Overlays
#
# nixpkgs overlays for custom package versions and modifications.
# Applied across all platforms (macOS, NixOS).

{ inputs, ... }:

{
  # Claude Code overlay - Auto-updated hourly from npm
  nixpkgs.overlays = [ inputs.claude-code-nix.overlays.default ];
}
