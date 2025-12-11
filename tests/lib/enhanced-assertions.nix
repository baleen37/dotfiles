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
      # Use toString to get the path after the derivation is built
      # This avoids the issue with builtins.readFile on unbuilt derivations
      expectedContent = builtins.readFile (toString expectedPath);
      actualContent = builtins.readFile (toString actualPath);
    in
    assertTestWithDetails name
      (expectedContent == actualContent)
      "File content mismatch"
      expectedContent
      actualContent
      (toString expectedPath)
      null;
in
{
  inherit assertTestWithDetails assertFileContent;
}
