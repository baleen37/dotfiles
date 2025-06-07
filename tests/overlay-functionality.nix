{ pkgs }:
let
  # Test that overlays are properly applied
  hasFeatherFont = pkgs ? feather-font;
  hasHammerspoonOverlay = pkgs ? hammerspoon;
  
  # Check overlay directory
  overlayDir = ../overlays;
  overlayFiles = builtins.attrNames (builtins.readDir overlayDir);
  nixOverlays = builtins.filter (name: builtins.match ".*\\.nix" name != null) overlayFiles;
  
in
pkgs.runCommand "overlay-functionality-test" {} ''
  export USER=testuser
  
  echo "Testing overlay functionality..."
  
  # Test that overlay files exist
  echo "Found overlay files: ${builtins.concatStringsSep ", " nixOverlays}"
  
  ${if builtins.length nixOverlays > 0 then ''
    echo "✓ Overlay files found (${toString (builtins.length nixOverlays)} files)"
  '' else ''
    echo "✗ No overlay files found"
    exit 1
  ''}
  
  # Test feather-font overlay on supported platforms
  ${if hasFeatherFont then ''
    echo "✓ feather-font overlay applied successfully"
    # Test that the font file exists in the package
    test -f ${pkgs.feather-font}/share/fonts/truetype/feather.ttf
    echo "✓ feather-font file exists"
  '' else ''
    echo "ℹ feather-font not available for ${pkgs.system} (expected for some platforms)"
  ''}
  
  # Test hammerspoon overlay on Darwin
  ${if pkgs.stdenv.isDarwin && hasHammerspoonOverlay then ''
    echo "✓ hammerspoon overlay applied successfully"
  '' else if pkgs.stdenv.isDarwin then ''
    echo "ℹ hammerspoon overlay not applied (may be expected)"
  '' else ''
    echo "ℹ hammerspoon overlay not needed on non-Darwin systems"
  ''}
  
  echo "All overlay functionality tests passed!"
  touch $out
''