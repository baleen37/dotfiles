{ pkgs, lib, ... }:

let
  # Import the Darwin configuration
  darwinConfig = import ../../hosts/darwin/default.nix {
    config = {};
    pkgs = pkgs;
  };

  # Extract nix configuration
  nixConfig = darwinConfig.nix;

  # Test helper functions
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Expected values
  expectedSubstituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];

  expectedTrustedPublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

in
testHelpers.runTests "nix-cachix-trusted-users" [
  {
    name = "should-have-nix-community-cachix-in-substituters";
    test = ''
      # Test that nix-community.cachix.org is in substituters
      if [[ "${toString nixConfig.settings.substituters}" == *"nix-community.cachix.org"* ]]; then
        echo "✅ nix-community.cachix.org found in substituters"
      else
        echo "❌ nix-community.cachix.org not found in substituters"
        exit 1
      fi
    '';
  }

  {
    name = "should-have-trusted-users-configured";
    test = ''
      # Test that trusted-users includes expected values
      trusted_users="${toString nixConfig.settings.trusted-users}"
      if [[ "$trusted_users" == *"root"* ]] && [[ "$trusted_users" == *"@admin"* ]]; then
        echo "✅ trusted-users configuration includes root and @admin"
      else
        echo "❌ trusted-users configuration missing expected values"
        echo "Got: $trusted_users"
        exit 1
      fi
    '';
  }

  {
    name = "should-have-cachix-trusted-public-key";
    test = ''
      # Test that nix-community.cachix.org public key is configured
      public_keys="${toString nixConfig.settings.trusted-public-keys}"
      if [[ "$public_keys" == *"nix-community.cachix.org-1"* ]]; then
        echo "✅ nix-community.cachix.org public key found"
      else
        echo "❌ nix-community.cachix.org public key not found"
        exit 1
      fi
    '';
  }

  {
    name = "should-have-both-cache-and-community-public-keys";
    test = ''
      # Test that both cache.nixos.org and nix-community.cachix.org keys are present
      public_keys="${toString nixConfig.settings.trusted-public-keys}"
      if [[ "$public_keys" == *"cache.nixos.org-1"* ]] && [[ "$public_keys" == *"nix-community.cachix.org-1"* ]]; then
        echo "✅ Both cache.nixos.org and nix-community.cachix.org public keys found"
      else
        echo "❌ Missing required public keys"
        echo "Got: $public_keys"
        exit 1
      fi
    '';
  }

  {
    name = "should-preserve-existing-nix-settings";
    test = ''
      # Test that existing nix settings are preserved
      if [[ "${toString nixConfig.enable}" == "false" ]]; then
        echo "✅ nix.enable = false preserved (Determinate Nix manages nix settings)"
      else
        echo "❌ nix.enable setting changed unexpectedly"
        exit 1
      fi

      if [[ "${toString nixConfig.gc.automatic}" == "false" ]]; then
        echo "✅ nix.gc.automatic = false preserved"
      else
        echo "❌ nix.gc.automatic setting changed unexpectedly"
        exit 1
      fi
    '';
  }
]
