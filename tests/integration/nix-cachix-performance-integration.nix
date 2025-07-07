{ pkgs, lib, ... }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Mock build scenario to test cache effectiveness
  mockBuildDerivation = pkgs.writeTextFile {
    name = "mock-build-test";
    text = ''
      # This simulates checking if nix-community.cachix.org is being used
      echo "Testing nix-community.cachix.org cache utilization..."
    '';
  };

in
testHelpers.runTests "nix-cachix-performance-integration" [
  {
    name = "should-have-working-nix-show-config";
    test = ''
      # Test that nix show-config works and shows our substituters
      echo "Testing nix show-config output..."

      # This test will run in the actual nix environment
      nix show-config | grep -i substituters > /tmp/substituters_output

      if grep -q "nix-community.cachix.org" /tmp/substituters_output; then
        echo "✅ nix show-config shows nix-community.cachix.org in substituters"
      else
        echo "❌ nix show-config does not show nix-community.cachix.org"
        echo "Substituters output:"
        cat /tmp/substituters_output
        exit 1
      fi
    '';
  }

  {
    name = "should-have-working-trusted-users-config";
    test = ''
      # Test that trusted-users configuration is working
      echo "Testing trusted-users configuration..."

      nix show-config | grep -i trusted-users > /tmp/trusted_users_output

      if grep -q "trusted-users" /tmp/trusted_users_output; then
        echo "✅ trusted-users configuration is present"
        cat /tmp/trusted_users_output
      else
        echo "❌ trusted-users configuration not found"
        exit 1
      fi
    '';
  }

  {
    name = "should-not-show-untrusted-substituter-warning";
    test = ''
      # Test that we don't get "ignoring untrusted substituter" warnings
      echo "Testing for untrusted substituter warnings..."

      # Run a simple nix command and check for warnings
      nix --version 2>&1 | grep -i "ignoring untrusted substituter" > /tmp/warnings_output || true

      if [[ -s /tmp/warnings_output ]]; then
        echo "❌ Still getting untrusted substituter warnings:"
        cat /tmp/warnings_output
        exit 1
      else
        echo "✅ No untrusted substituter warnings detected"
      fi
    '';
  }

  {
    name = "should-have-accessible-cache-servers";
    test = ''
      # Test that cache servers are accessible
      echo "Testing cache server accessibility..."

      # Test cache.nixos.org
      if curl -s -f --connect-timeout 5 "https://cache.nixos.org/nix-cache-info" > /dev/null; then
        echo "✅ cache.nixos.org is accessible"
      else
        echo "⚠️  cache.nixos.org is not accessible (network issue?)"
      fi

      # Test nix-community.cachix.org
      if curl -s -f --connect-timeout 5 "https://nix-community.cachix.org/nix-cache-info" > /dev/null; then
        echo "✅ nix-community.cachix.org is accessible"
      else
        echo "⚠️  nix-community.cachix.org is not accessible (network issue?)"
      fi
    '';
  }

  {
    name = "should-preserve-user-nix-conf";
    test = ''
      # Test that user's nix.conf is preserved and not conflicting
      echo "Testing user nix.conf preservation..."

      user_nix_conf="$HOME/.config/nix/nix.conf"

      if [[ -f "$user_nix_conf" ]]; then
        echo "✅ User nix.conf exists at $user_nix_conf"

        # Check if it still contains our expected settings
        if grep -q "nix-community.cachix.org" "$user_nix_conf"; then
          echo "✅ User nix.conf contains nix-community.cachix.org"
        else
          echo "⚠️  User nix.conf does not contain nix-community.cachix.org"
        fi
      else
        echo "⚠️  User nix.conf not found at $user_nix_conf"
      fi
    '';
  }
]
