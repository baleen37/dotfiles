# tests/lib/enhanced-assertions.nix
{ pkgs, lib }:

let
  # Enhanced assertion with detailed error reporting
  assertTestWithDetails =
    name: condition: message:
    let
      expected = null;
      actual = null;
      file = null;
      line = null;
    in
    if condition then
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
      expectedPath;
in
{
  inherit assertTestWithDetails assertFileContent;
}
