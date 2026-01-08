# tests/unit/lib-user-info-edge-cases-test.nix
# Edge case and validation tests for lib/user-info.nix centralized user information
# Tests invalid email formats, invalid name formats, type validation, and unexpected attributes

{
  inputs,
  system,
  nixtest ? { },
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  userInfo = import ../../lib/user-info.nix;

  # Helper function to validate email format
  validateEmail = email:
    let
      hasAt = lib.hasInfix "@" email;
      parts = builtins.split "@" email;
      atCount = (builtins.length parts - 1) / 2;  # split returns [match non-match match ...]
      hasDomain = atCount >= 1 && builtins.stringLength (builtins.elemAt parts 2) > 0;
      hasTLD = atCount >= 1 && lib.hasInfix "." (builtins.elemAt parts 2);
    in
    hasAt && atCount == 1 && hasDomain && hasTLD;

  # Helper function to validate name format
  validateName = name:
    let
      trimmed = lib.removeSuffix " " (lib.removePrefix " " name);
      hasContent = builtins.stringLength trimmed > 0;
      noNewlines = !lib.hasInfix "\n" name;
      reasonableLength = builtins.stringLength name <= 100;
    in
    hasContent && noNewlines && reasonableLength;

  # Helper function to check type validation
  checkType = expectedType: value:
    builtins.typeOf value == expectedType;

in
{
  platforms = ["any"];
  value = {
    # Test 1: Current userInfo email is valid (has @ symbol)
    current-email-has-at-sign = helpers.assertTest "user-info-email-has-at-sign" (
      lib.hasInfix "@" userInfo.email
    ) "Current userInfo.email should contain @ symbol";

    # Test 2: Current userInfo email is valid (has domain)
    current-email-has-domain = helpers.assertTest "user-info-email-has-domain" (
      let
        parts = builtins.split "@" userInfo.email;
        domain = if builtins.length parts >= 3 then builtins.elemAt parts 2 else "";
      in
      builtins.stringLength domain > 0
    ) "Current userInfo.email should have a domain after @";

    # Test 3: Current userInfo email is valid (has TLD)
    current-email-has-tld = helpers.assertTest "user-info-email-has-tld" (
      let
        parts = builtins.split "@" userInfo.email;
        domain = if builtins.length parts >= 3 then builtins.elemAt parts 2 else "";
      in
      lib.hasInfix "." domain
    ) "Current userInfo.email should have a TLD (dot in domain)";

    # Test 4: Current userInfo email has exactly one @ symbol
    current-email-single-at = helpers.assertTest "user-info-email-single-at" (
      let
        parts = builtins.split "@" userInfo.email;
        atCount = builtins.length parts - 1;
      in
      atCount == 1
    ) "Current userInfo.email should have exactly one @ symbol";

    # Test 5: Email without @ should be invalid
    invalid-email-no-at = helpers.assertTest "user-info-invalid-email-no-at" (
      validateEmail "invalidemail.com" == false
    ) "Email without @ symbol should be invalid";

    # Test 6: Email without domain should be invalid
    invalid-email-no-domain = helpers.assertTest "user-info-invalid-email-no-domain" (
      validateEmail "user@" == false
    ) "Email without domain should be invalid";

    # Test 7: Email without TLD should be invalid
    invalid-email-no-tld = helpers.assertTest "user-info-invalid-email-no-tld" (
      validateEmail "user@localhost" == false
    ) "Email without TLD should be invalid (no dot in domain)";

    # Test 8: Email with multiple @ symbols should be invalid
    invalid-email-multiple-at = helpers.assertTest "user-info-invalid-email-multiple-at" (
      validateEmail "user@domain@com" == false
    ) "Email with multiple @ symbols should be invalid";

    # Test 9: Current userInfo name is non-empty
    current-name-non-empty = helpers.assertTest "user-info-name-non-empty" (
      builtins.stringLength userInfo.name > 0
    ) "Current userInfo.name should be non-empty";

    # Test 10: Current userInfo name has no leading/trailing whitespace
    current-name-no-extra-whitespace = helpers.assertTest "user-info-name-no-extra-whitespace" (
      let
        trimmed = lib.removeSuffix " " (lib.removePrefix " " userInfo.name);
      in
      userInfo.name == trimmed
    ) "Current userInfo.name should not have leading/trailing whitespace";

    # Test 11: Current userInfo name has no newlines
    current-name-no-newlines = helpers.assertTest "user-info-name-no-newlines" (
      !lib.hasInfix "\n" userInfo.name
    ) "Current userInfo.name should not contain newlines";

    # Test 12: Current userInfo name is reasonable length
    current-name-reasonable-length = helpers.assertTest "user-info-name-reasonable-length" (
      builtins.stringLength userInfo.name <= 100
    ) "Current userInfo.name should be reasonable length (<= 100 characters)";

    # Test 13: Empty name should be invalid
    invalid-name-empty = helpers.assertTest "user-info-invalid-name-empty" (
      validateName "" == false
    ) "Empty name should be invalid";

    # Test 14: Whitespace-only name should be invalid
    invalid-name-whitespace-only = helpers.assertTest "user-info-invalid-name-whitespace-only" (
      validateName "   " == false
    ) "Whitespace-only name should be invalid";

    # Test 15: Name with newlines should be invalid
    invalid-name-with-newlines = helpers.assertTest "user-info-invalid-name-with-newlines" (
      validateName "John\nDoe" == false
    ) "Name with newlines should be invalid";

    # Test 16: Name too long should be invalid
    invalid-name-too-long = helpers.assertTest "user-info-invalid-name-too-long" (
      validateName (builtins.concatStringsSep "" (builtins.genList 101 (i: "a"))) == false
    ) "Name longer than 100 characters should be invalid";

    # Test 17: Current userInfo.name is a string
    current-name-is-string = helpers.assertTest "user-info-name-is-string" (
      checkType "string" userInfo.name
    ) "Current userInfo.name should be a string";

    # Test 18: Current userInfo.email is a string
    current-email-is-string = helpers.assertTest "user-info-email-is-string" (
      checkType "string" userInfo.email
    ) "Current userInfo.email should be a string";

    # Test 19: Non-string name should be invalid
    invalid-name-type-number = helpers.assertTest "user-info-invalid-name-type-number" (
      checkType "string" 12345
    ) "Non-string name (number) should be invalid type";

    # Test 20: Non-string email should be invalid
    invalid-email-type-number = helpers.assertTest "user-info-invalid-email-type-number" (
      checkType "string" 12345
    ) "Non-string email (number) should be invalid type";

    # Test 21: Non-string name (boolean) should be invalid
    invalid-name-type-boolean = helpers.assertTest "user-info-invalid-name-type-boolean" (
      checkType "string" true
    ) "Non-string name (boolean) should be invalid type";

    # Test 22: Non-string email (boolean) should be invalid
    invalid-email-type-boolean = helpers.assertTest "user-info-invalid-email-type-boolean" (
      checkType "string" false
    ) "Non-string email (boolean) should be invalid type";

    # Test 23: Current userInfo has only expected attributes
    current-info-only-expected-attrs = helpers.assertTest "user-info-only-expected-attrs" (
      let
        attrs = builtins.attrNames userInfo;
        expectedAttrs = [ "name" "email" ];
        unexpectedAttrs = builtins.filter (attr: !builtins.elem attr expectedAttrs) attrs;
      in
      builtins.length unexpectedAttrs == 0
    ) "Current userInfo should only contain name and email attributes";

    # Test 24: Adding unexpected attribute should be detectable
    unexpected-attribute-detectable = helpers.assertTest "user-info-unexpected-attribute-detectable" (
      let
        testInfo = userInfo // { unexpectedAttr = "value"; };
        attrs = builtins.attrNames testInfo;
        expectedAttrs = [ "name" "email" ];
        unexpectedAttrs = builtins.filter (attr: !builtins.elem attr expectedAttrs) attrs;
      in
      builtins.length unexpectedAttrs > 0
    ) "Adding unexpected attribute to userInfo should be detectable";

    # Test 25: Valid email format should pass validation
    valid-email-format-passes = helpers.assertTest "user-info-valid-email-format-passes" (
      validateEmail "user@example.com"
    ) "Valid email format should pass validation";

    # Test 26: Valid name format should pass validation
    valid-name-format-passes = helpers.assertTest "user-info-valid-name-format-passes" (
      validateName "John Doe"
    ) "Valid name format should pass validation";

    # Test 27: Name with leading/trailing whitespace should be trimmable
    name-with-whitespace-trimmable = helpers.assertTest "user-info-name-whitespace-trimmable" (
      let
        nameWithSpaces = "  John Doe  ";
        trimmed = lib.removeSuffix " " (lib.removePrefix " " nameWithSpaces);
      in
      trimmed == "John Doe"
    ) "Name with leading/trailing whitespace should be trimmable";

    # Test 28: Email with subdomain should be valid
    valid-email-subdomain = helpers.assertTest "user-info-valid-email-subdomain" (
      validateEmail "user@mail.example.com"
    ) "Email with subdomain should be valid";

    # Test 29: Email with plus sign in local part should be valid
    valid-email-plus-sign = helpers.assertTest "user-info-valid-email-plus-sign" (
      validateEmail "user+tag@example.com"
    ) "Email with plus sign in local part should be valid";

    # Test 30: Email with dots in local part should be valid
    valid-email-dots-local = helpers.assertTest "user-info-valid-email-dots-local" (
      validateEmail "user.name@example.com"
    ) "Email with dots in local part should be valid";

    # Test 31: Name with hyphen should be valid
    valid-name-hyphen = helpers.assertTest "user-info-valid-name-hyphen" (
      validateName "Mary-Jane Smith"
    ) "Name with hyphen should be valid";

    # Test 32: Name with apostrophe should be valid
    valid-name-apostrophe = helpers.assertTest "user-info-valid-name-apostrophe" (
      validateName "O'Connor"
    ) "Name with apostrophe should be valid";

    # Test 33: Name with single character should be valid
    valid-name-single-char = helpers.assertTest "user-info-valid-name-single-char" (
      validateName "A"
    ) "Name with single character should be valid";

    # Test 34: Email case insensitivity (same email different case)
    email-case-insensitive = helpers.assertTest "user-info-email-case-insensitive" (
      let
        email1 = "user@example.com";
        email2 = "USER@EXAMPLE.COM";
        # Both should be valid format
      in
      validateEmail email1 && validateEmail email2
    ) "Email validation should accept uppercase and lowercase";

    # Test 35: Current userInfo values match expected format
    current-values-valid-format = helpers.assertTest "user-info-current-values-valid-format" (
      validateEmail userInfo.email && validateName userInfo.name
    ) "Current userInfo values should pass format validation";
  };
}
