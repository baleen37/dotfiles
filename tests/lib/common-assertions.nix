# tests/lib/common-assertions.nix
#
# Assertions that carry their own failure message, so a red check tells you what
# was wrong instead of just which line was false.
#
# Every function takes a trailing `message` argument; pass `null` to get the
# generated one, which is usually the more informative option.
#
#   assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
#   assertions.assertAttrEquals "git-editor" gitSettings.core "editor" "vim" null
{
  pkgs,
  lib,
  ...
}:

rec {
  # Base primitive: like test-helpers.assertTest but with a nullable message.
  assertCondition =
    name: condition: message:
    let
      displayMessage = if message != null then message else "Assertion failed: ${name}";
    in
    if condition then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "PASS: ${name}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "FAIL: ${name}"
        echo "  ${displayMessage}"
        exit 1
      '';

  assertAttrExists =
    name: obj: attrName: message:
    assertCondition name (builtins.hasAttr attrName obj) (
      if message != null then message else "Attribute '${attrName}' not found"
    );

  # Same as assertAttrExists but for a dotted path, e.g. "system.defaults.dock".
  assertAttrPathExists =
    name: obj: attrPath: message:
    let
      pathParts = lib.splitString "." attrPath;
      hasPath = lib.hasAttrByPath pathParts obj;
    in
    assertCondition name hasPath (
      if message != null then message else "Attribute path '${attrPath}' not found"
    );

  assertAttrEquals =
    name: obj: attrName: expectedValue: message:
    let
      actualValue = obj.${attrName} or null;
    in
    assertCondition name (actualValue == expectedValue) (
      if message != null then
        message
      else
        "Attribute '${attrName}' should be ${toString expectedValue}, got ${toString actualValue}"
    );

  assertListContains =
    name: list: element: message:
    assertCondition name (builtins.elem element list) (
      if message != null then message else "List should contain '${toString element}'"
    );

  assertListNotEmpty =
    name: list: message:
    assertCondition name (list != [ ]) (
      if message != null then message else "List should not be empty"
    );

  assertNotNull =
    name: value: message:
    assertCondition name (value != null) (
      if message != null then message else "Value should not be null"
    );
}
