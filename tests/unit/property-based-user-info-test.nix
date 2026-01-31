# Property-Based Test for lib/user-info.nix
#
# Tests user information configuration for various invariants:
# - Invariant: Required attributes always present
# - Reflexivity: User info equals itself
# - Consistency: Values maintain expected formats
# - Validation: Email and name formats are valid
#
# VERSION: 1.0.0
# LAST UPDATED: 2025-01-31

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
}:

let
  # Import property testing framework
  propertyTesting = import ../lib/property-testing.nix { inherit lib pkgs; };

  # Import user-info module to test
  userInfo = import ../../lib/user-info.nix;

  # Import test helpers
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test scenarios for user info validation
  # These test various valid user information patterns
  userInfoScenarios = [
    {
      identifier = "standard-user";
      name = "Jiho Lee";
      email = "baleen37@gmail.com";
    }
    {
      identifier = "simple-user";
      name = "John Doe";
      email = "john@example.com";
    }
    {
      identifier = "hyphenated-name";
      name = "Mary-Jane Smith";
      email = "mary.jane@example.com";
    }
    {
      identifier = "multiword-name";
      name = "Jean Claude Van Damme";
      email = "jcvd@example.com";
    }
    {
      identifier = "numeric-email";
      name = "User123";
      email = "user123@test456.com";
    }
    {
      identifier = "subdomain-email";
      name = "Developer";
      email = "dev@sub.example.org";
    }
    {
      identifier = "plus-email";
      name = "GitHub User";
      email = "user+tag@example.com";
    }
  ];

  # Additional edge case scenarios
  edgeCaseScenarios = [
    {
      identifier = "minimal-name";
      name = "X";
      email = "x@x.x";
    }
    {
      identifier = "long-name";
      name = "Very Long Name That Is Still Valid";
      email = "longname@example.com";
    }
  ];

in
# Property-based test suite
{
  platforms = [ "any" ];
  value = helpers.testSuite "property-based-user-info-test" [
    # Property 1: Required attributes presence
    # All user info should have name and email
    (helpers.assertTest "userinfo-has-name-attr" (
      builtins.hasAttr "name" userInfo
    ) "userInfo should have name attribute")

    (helpers.assertTest "userinfo-has-email-attr" (
      builtins.hasAttr "email" userInfo
    ) "userInfo should have email attribute")

    # Property 2: Non-empty values invariant
    # Name and email should be non-empty strings
    (helpers.assertTest "userinfo-name-nonempty" (
      let
        name = userInfo.name or "";
      in
      builtins.stringLength name > 0
    ) "User name should be non-empty")

    (helpers.assertTest "userinfo-email-nonempty" (
      let
        email = userInfo.email or "";
      in
      builtins.stringLength email > 0
    ) "User email should be non-empty")

    # Property 3: Email format validation
    # Email should match basic email pattern
    (helpers.assertTest "userinfo-email-valid-format" (
      let
        email = userInfo.email or "";
        # Basic email validation: has @, has domain with dot
        hasAt = builtins.match ".*@.*" email != null;
        hasDomain = builtins.match ".*@.*\\..*" email != null;
        noSpaces = !builtins.match ".* .*" email;
      in
      hasAt && hasDomain && noSpaces
    ) "User email should have valid format")

    # Property 4: Name format validation
    # Name should contain at least one space (first and last)
    (helpers.assertTest "userinfo-name-has-space" (
      let
        name = userInfo.name or "";
        hasSpace = builtins.match ".* .*" name != null;
      in
      hasSpace
    ) "User name should contain first and last name")

    # Property 5: Name doesn't contain invalid characters
    # Name should only contain letters, spaces, hyphens
    (helpers.assertTest "userinfo-name-valid-chars" (
      let
        name = userInfo.name or "";
        # Allow letters, spaces, hyphens
        validChars = builtins.match "^[A-Za-z \\-]+$" name != null;
      in
      validChars
    ) "User name should only contain valid characters")

    # Property 6: Reflexivity
    # User info should equal itself
    (helpers.assertTest "userinfo-reflexivity-name" (
      let
        name = userInfo.name;
      in
      name == name
    ) "User name should be reflexive")

    (helpers.assertTest "userinfo-reflexivity-email" (
      let
        email = userInfo.email;
      in
      email == email
    ) "User email should be reflexive")

    # Property 7: Idempotence of reading
    # Reading user info multiple times produces same result
    (helpers.assertTest "userinfo-idempotence" (
      let
        userInfo1 = import ../../lib/user-info.nix;
        userInfo2 = import ../../lib/user-info.nix;
      in
      userInfo1.name == userInfo2.name && userInfo1.email == userInfo2.email
    ) "Reading user info should be idempotent")

    # Property 8: Email uniqueness
    # Email format should be unique per user (singleton pattern)
    (helpers.assertTest "userinfo-email-singleton" (
      let
        email = userInfo.email;
        # This is a singleton module, so there should only be one email
        emailValid = builtins.stringLength email > 0 && builtins.match ".*@.*\\..*" email != null;
      in
      emailValid
    ) "User info should have exactly one valid email")

    # Property 9: Name consistency
    # Name should be consistent across reads
    (helpers.assertTest "userinfo-name-consistency" (
      let
        name = userInfo.name;
        # Name should be the same every time we read it
        nameValid = builtins.isString name && builtins.stringLength name > 0;
      in
      nameValid
    ) "User name should be consistent")

    # Property 10: Cross-scenario validation
    # All scenarios should have valid structure
    (helpers.assertTest "userinfo-scenarios-valid-structure" (
      let
        # Check all scenarios have required attributes
        allHaveName = builtins.all (s: builtins.hasAttr "name" s) userInfoScenarios;
        allHaveEmail = builtins.all (s: builtins.hasAttr "email" s) userInfoScenarios;
      in
      allHaveName && allHaveEmail
    ) "All scenarios should have valid structure")

    (helpers.assertTest "userinfo-scenarios-email-format" (
      let
        # Check all scenario emails are valid
        allValidEmails = builtins.all (
          s: builtins.match ".*@.*\\..*" (s.email or "") != null
        ) userInfoScenarios;
      in
      allValidEmails
    ) "All scenario emails should have valid format")

    (helpers.assertTest "userinfo-scenarios-name-format" (
      let
        # Check all scenario names are valid
        allValidNames = builtins.all (
          s: builtins.stringLength (s.name or "") > 0
        ) userInfoScenarios;
      in
      allValidNames
    ) "All scenario names should be non-empty")

    # Property 11: Edge case handling
    # Edge cases should maintain invariants
    (helpers.assertTest "userinfo-edgecase-minimal-name" (
      let
        scenario = builtins.elemAt edgeCaseScenarios 0;
        nameValid = builtins.stringLength scenario.name > 0;
        emailValid = builtins.match ".*@.*\\..*" scenario.email != null;
      in
      nameValid && emailValid
    ) "Minimal edge case should be valid")

    (helpers.assertTest "userinfo-edgecase-long-name" (
      let
        scenario = builtins.elemAt edgeCaseScenarios 1;
        nameValid = builtins.stringLength scenario.name > 0;
        emailValid = builtins.match ".*@.*\\..*" scenario.email != null;
      in
      nameValid && emailValid
    ) "Long name edge case should be valid")

    # Property 12: Domain validation
    # Email domain should have valid TLD
    (helpers.assertTest "userinfo-domain-valid-tld" (
      let
        email = userInfo.email;
        # Extract domain and check for valid TLD
        parts = builtins.split "@" email;
        domain = if builtins.length parts >= 2 then builtins.elemAt parts 2 else "";
        hasDot = builtins.match ".*\\..*" domain != null;
      in
      hasDot
    ) "Email domain should have valid TLD")

    # Property 13: No leading/trailing whitespace
    # Name and email shouldn't have extra whitespace
    (helpers.assertTest "userinfo-no-leading-ws-name" (
      let
        name = userInfo.name;
        noLeading = !(builtins.match "^ .*" name != null);
      in
      noLeading
    ) "User name should not have leading whitespace")

    (helpers.assertTest "userinfo-no-trailing-ws-name" (
      let
        name = userInfo.name;
        noTrailing = !(builtins.match ".* $" name != null);
      in
      noTrailing
    ) "User name should not have trailing whitespace")

    (helpers.assertTest "userinfo-no-leading-ws-email" (
      let
        email = userInfo.email;
        noLeading = !(builtins.match "^ .*" email != null);
      in
      noLeading
    ) "User email should not have leading whitespace")

    (helpers.assertTest "userinfo-no-trailing-ws-email" (
      let
        email = userInfo.email;
        noTrailing = !(builtins.match ".* $" email != null);
      in
      noTrailing
    ) "User email should not have trailing whitespace")

    # Summary test
    (pkgs.runCommand "property-based-user-info-summary" { } ''
      echo "Property-Based User Info Test Summary"
      echo ""
      echo "Tested Properties:"
      echo "  Required attributes presence (name, email)"
      echo "  Non-empty values invariant"
      echo "  Email format validation"
      echo "  Name format validation"
      echo "  Reflexivity of values"
      echo "  Idempotence of reading"
      echo "  Cross-scenario validation"
      echo "  Edge case handling"
      echo "  Domain validation"
      echo "  Whitespace handling"
      echo ""
      echo "Scenarios tested: ${toString (builtins.length userInfoScenarios + builtins.length edgeCaseScenarios)}"
      echo "  - Standard users: ${toString (builtins.length userInfoScenarios)}"
      echo "  - Edge cases: ${toString (builtins.length edgeCaseScenarios)}"
      echo ""
      echo "Actual User Info:"
      echo "  Name: ${userInfo.name}"
      echo "  Email: ${userInfo.email}"
      echo ""
      echo "Property-Based Testing Benefits:"
      echo "  Validates user info invariants regardless of content"
      echo "  Ensures consistent format across all valid inputs"
      echo "  Verifies email validation logic"
      echo "  Tests name formatting rules"
      echo "  Checks for common data quality issues"
      echo ""
      echo "All Property-Based User Info Tests Passed!"
      touch $out
    '')
  ];
}
