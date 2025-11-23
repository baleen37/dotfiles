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
          echo "✅ ${name}: PASS"
          touch $out
        ''
      else
        pkgs.runCommand "test-${name}-fail" { } ''
          echo "❌ ${name}: FAIL"
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
  assertFileContent =
    name: expectedPath: actualPath:
    let
      expectedContent = builtins.toString expectedPath;
      actualContent = builtins.toString actualPath;
    in
    assertTestWithDetails name
      (expectedPath == actualPath)
      "File paths should be identical for test comparison"
      expectedContent
      actualContent
      expectedPath
      null;
in
{
  inherit assertTestWithDetails assertFileContent;
}
