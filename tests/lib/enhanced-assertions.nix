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
  assertFileContent =
    name: expectedPath: actualPath:
    let
      expectedContent = builtins.readFile expectedPath;
      actualContent = builtins.readFile actualPath;
    in
    assertTestWithDetails name
      (expectedContent == actualContent)
      "File content mismatch"
      expectedContent
      actualContent
      expectedPath
      null;
in
{
  inherit assertTestWithDetails assertFileContent;
}
