# tests/lib/enhanced-assertions.nix
# Enhanced assertion utilities with detailed error reporting for test debugging

{ pkgs, lib }:

let
  # Enhanced assertion with detailed error reporting
  # Parameters: name, condition, message, ?expected, ?actual, ?file, ?line
  assertTestWithDetails =
    name: condition: message: expected: actual: file: line:
    let
      result = if condition then
        pkgs.runCommand "test-${name}-pass" { } ''
          echo "PASS: ${name}"
          touch $out
        ''
      else
        pkgs.runCommand "test-${name}-fail" { } ''
          echo "FAIL: ${name}"
          echo "  📝 ${message}"
          ${lib.optionalString (expected != null) ''
          echo "  🔮 Expected: ${expected}"
          ''}
          ${lib.optionalString (actual != null) ''
          echo "  🔍 Actual: ${actual}"
          ''}
          ${lib.optionalString (file != null) ''
          echo "  📍 Location: ${file}${lib.optionalString (line != null) ":${toString line}"}"
          ''}
          exit 1
        '';
    in
    result;

  # File content validation with diff support
  # Note: Nix 3.14.0+ cannot use builtins.readFile on derivations at eval time
  # Instead, we compare files at build time using diff
  assertFileContent =
    name: expectedPath: actualPath:
    pkgs.runCommand "test-${name}" {
      inherit expectedPath actualPath;
    } ''
      if diff -u "$expectedPath" "$actualPath" > /dev/null 2>&1; then
        echo "PASS: ${name}"
        touch $out
      else
        echo "FAIL: ${name}"
        echo "  📝 File content mismatch"
        echo "  📍 Expected: $expectedPath"
        echo "  📍 Actual: $actualPath"
        echo ""
        echo "Diff:"
        diff -u "$expectedPath" "$actualPath" || true
        exit 1
      fi
    '';
in
{
  inherit assertTestWithDetails assertFileContent;
}
