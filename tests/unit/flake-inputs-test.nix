# Every direct flake input that takes a `nixpkgs` input must follow the root
# nixpkgs. An input that brings its own nixpkgs still evaluates and builds, so the
# only symptom is a second nixpkgs in the closure and cache misses on everything
# built from it — nothing fails until someone notices the download size.
#
# Reads flake.lock rather than flake.nix: the lock is what Nix actually resolved.
{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  lock = builtins.fromJSON (builtins.readFile ../../flake.lock);
  rootInputs = lock.nodes.${lock.root}.inputs;

  # A root input name maps to a lock node name (a string) for direct inputs.
  nodeOf = name: lock.nodes.${rootInputs.${name}};

  withNixpkgs = lib.filter (name: name != "nixpkgs" && ((nodeOf name).inputs or { }) ? nixpkgs) (
    lib.attrNames rootInputs
  );

  notFollowing = lib.filter (name: (nodeOf name).inputs.nixpkgs != [ "nixpkgs" ]) withNixpkgs;
in
helpers.testSuite "flake-inputs" [
  (helpers.assertTest "inputs-with-nixpkgs-exist" (
    withNixpkgs != [ ]
  ) "expected at least one root input that takes nixpkgs; the lock lookup is probably broken")

  (helpers.assertTest "inputs-follow-root-nixpkgs" (notFollowing == [ ])
    "these flake inputs bring their own nixpkgs; add inputs.nixpkgs.follows = \"nixpkgs\": ${lib.concatStringsSep ", " notFollowing}"
  )
]
