# User Info Test
#
# Unit tests for lib/user-info.nix centralized user information
# Tests user identity consistency across all configurations
{
  inputs,
  system,
  nixtest ? { },
  pkgs,
  lib,
  self,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit lib pkgs; };
  userInfo = import ../../lib/user-info.nix;

in
{
  platforms = ["any"];
  value = helpers.testSuite "user-info" [
    # Test 1: userInfo structure has required attributes
    (helpers.assertTest "user-info-has-required-attributes" (
      builtins.hasAttr "name" userInfo
      && builtins.hasAttr "email" userInfo
    ) "userInfo should have name and email attributes")

    # Test 2: name is non-empty string
    (helpers.assertTest "user-info-name-is-non-empty" (
      builtins.typeOf userInfo.name == "string"
      && builtins.stringLength userInfo.name > 0
    ) "userInfo.name should be a non-empty string")

    # Test 3: email is non-empty string
    (helpers.assertTest "user-info-email-is-non-empty" (
      builtins.typeOf userInfo.email == "string"
      && builtins.stringLength userInfo.email > 0
    ) "userInfo.email should be a non-empty string")

    # Test 4: email contains @ symbol (basic format validation)
    (helpers.assertTest "user-info-email-has-at-sign" (
      lib.hasInfix "@" userInfo.email
    ) "userInfo.email should contain @ symbol")

    # Test 5: email contains dot (basic format validation)
    (helpers.assertTest "user-info-email-has-dot" (
      lib.hasInfix "." userInfo.email
    ) "userInfo.email should contain dot")

    # Test 6: userInfo only contains expected attributes
    (helpers.assertTest "user-info-only-contains-expected-attributes" (
      let
        attrs = builtins.attrNames userInfo;
        expectedAttrs = [ "name" "email" ];
        unexpectedAttrs = builtins.filter (attr: !builtins.elem attr expectedAttrs) attrs;
      in
      builtins.length unexpectedAttrs == 0
    ) "userInfo should only contain name and email attributes")

    # Test 7: Specific user values (Jiho Lee's info)
    (helpers.assertTest "user-info-has-correct-name" (
      userInfo.name == "Jiho Lee"
    ) "userInfo.name should be 'Jiho Lee'")

    # Test 8: Specific email value
    (helpers.assertTest "user-info-has-correct-email" (
      userInfo.email == "baleen37@gmail.com"
    ) "userInfo.email should be 'baleen37@gmail.com'")
  ];
}
