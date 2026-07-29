# tests/unit/lib-user-info-test.nix
#
# lib/user-info.nix is a two-attribute literal, so there is nothing here worth
# restating as an equality assertion — git-configuration-test.nix already proves
# the values reach programs.git.
#
# What is worth guarding is shape: a typo'd address propagates silently into
# every commit, and an extra attribute would be silently ignored by consumers.
{
  pkgs,
  lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  userInfo = import ../../lib/user-info.nix;

  surroundingWhitespace = [
    " "
    "\t"
    "\n"
    "\r"
  ];
  isPadded = s: lib.any (c: lib.hasPrefix c s || lib.hasSuffix c s) surroundingWhitespace;
in
{
  platforms = [ "any" ];
  value = helpers.testSuite "lib-user-info" [
    (helpers.assertTest "email-is-well-formed" (
      builtins.match "[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+" userInfo.email != null
    ) "user-info.email must be a single well-formed address; it is baked into every commit")

    (helpers.assertTest "name-is-trimmed-and-non-empty" (
      userInfo.name != "" && !(isPadded userInfo.name)
    ) "user-info.name must be non-empty with no surrounding whitespace")

    (helpers.assertTest "exports-exactly-name-and-email" (
      builtins.attrNames userInfo == [
        "email"
        "name"
      ]
    ) "user-info.nix must export exactly name and email; consumers ignore anything else")
  ];
}
