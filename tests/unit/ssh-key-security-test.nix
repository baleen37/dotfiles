{ pkgs, lib, src }:

let
  # Test for SSH key validation and security in copy-keys script
  testScript = pkgs.writeShellScript "test-ssh-key-security" ''
    set -euo pipefail

    echo "=== Testing SSH key security in copy-keys script ==="

    # Test 1: Check for key integrity validation
    echo "🔍 Testing for SSH key integrity validation..."

    FAILED_TESTS=()

    for script in ${src}/apps/*/copy-keys; do
      if [[ -f "$script" ]]; then
        script_name=$(basename $(dirname "$script"))/$(basename "$script")
        echo "Checking $script_name..."

        # Should validate SSH keys before copying
        if grep -q "ssh-keygen.*-l\|ssh-add.*-L\|validate.*key\|verify.*key" "$script"; then
          echo "✅ PASS: $script_name validates SSH keys"
        else
          echo "❌ FAIL: $script_name doesn't validate SSH keys"
          FAILED_TESTS+=("$script_name: missing key validation")
        fi
      fi
    done

    # Test 2: Check for backup of existing keys
    echo ""
    echo "🔍 Testing for existing key backup..."

    for script in ${src}/apps/*/copy-keys; do
      if [[ -f "$script" ]]; then
        script_name=$(basename $(dirname "$script"))/$(basename "$script")

        # Should backup existing keys
        if grep -q "backup\|\.bak\|\.backup" "$script"; then
          echo "✅ PASS: $script_name creates backups"
        else
          echo "❌ FAIL: $script_name doesn't backup existing keys"
          FAILED_TESTS+=("$script_name: missing backup mechanism")
        fi
      fi
    done

    # Test 3: Check for secure file permissions
    echo ""
    echo "🔍 Testing for secure file permissions..."

    for script in ${src}/apps/*/copy-keys; do
      if [[ -f "$script" ]]; then
        script_name=$(basename $(dirname "$script"))/$(basename "$script")

        # Should set proper permissions on private keys (600)
        if grep -q "chmod 600.*id_" "$script"; then
          echo "✅ PASS: $script_name sets secure permissions"
        else
          echo "❌ FAIL: $script_name doesn't set secure permissions"
          FAILED_TESTS+=("$script_name: missing secure permissions")
        fi
      fi
    done

    # Test 4: Check for mount path validation
    echo ""
    echo "🔍 Testing for USB mount path validation..."

    for script in ${src}/apps/*/copy-keys; do
      if [[ -f "$script" ]]; then
        script_name=$(basename $(dirname "$script"))/$(basename "$script")

        # Should validate mount path before using
        if grep -q "test.*MOUNT_PATH\|\[ -n.*MOUNT_PATH\|\[\[ -n.*MOUNT_PATH" "$script"; then
          echo "✅ PASS: $script_name validates mount path"
        else
          echo "❌ FAIL: $script_name doesn't validate mount path"
          FAILED_TESTS+=("$script_name: missing mount path validation")
        fi
      fi
    done

    echo ""
    echo "=== Test Results ==="
    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "  - $test"
      done
      echo "SSH key security issues found!"
      exit 1
    else
      echo "✅ All SSH key security tests passed!"
      exit 0
    fi
  '';

in
pkgs.runCommand "ssh-key-security-test" {
  buildInputs = [ pkgs.bash pkgs.gnugrep ];
} ''
  echo "Running SSH key security tests..."
  ${testScript}

  echo "SSH key security test completed"
  touch $out
''
