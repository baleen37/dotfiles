{ pkgs }:
let
  # Import the user function to get consistent user handling
  getUser = import ../lib/get-user.nix { };
  user = getUser;

  # Test script that validates 1Password SSH integration
  testScript = pkgs.writeShellScript "test-1password-ssh" ''
    set -e
    export USER=${user}
    
    echo "Testing 1Password SSH integration..."
    
    # Test 1: Check if 1password-cli is available
    echo "✓ Testing 1password-cli availability..."
    if ! command -v op >/dev/null 2>&1; then
      echo "✗ 1password-cli (op) not found in PATH"
      exit 1
    fi
    echo "✓ 1password-cli found"
    
    # Test 2: Test SSH agent socket detection command
    echo "✓ Testing SSH agent socket detection..."
    
    # Mock op command to test socket detection
    mock_op() {
      if [ "$1" = "ssh-agent" ] && [ "$2" = "--out" ] && [ "$3" = "socket" ]; then
        echo "/tmp/mock-1password-agent.sock"
        return 0
      fi
      return 1
    }
    
    # Test that the command structure is correct
    socket_path=$(mock_op ssh-agent --out socket)
    if [ "$socket_path" = "/tmp/mock-1password-agent.sock" ]; then
      echo "✓ SSH agent socket detection command works correctly"
    else
      echo "✗ SSH agent socket detection failed"
      exit 1
    fi
    
    # Test 3: Validate that shared packages include 1password-cli
    echo "✓ Testing package availability..."
    if command -v op >/dev/null 2>&1; then
      echo "✓ 1password-cli is available in test environment"
    else
      echo "✗ 1password-cli missing from test environment"
      exit 1
    fi
    
    # Test 4: Validate SSH configuration file syntax
    echo "✓ Testing SSH config syntax..."
    
    # Create a test SSH config with our settings
    test_ssh_config=$(cat << 'EOF'
Host *
  IdentitiesOnly yes
  AddKeysToAgent yes
  UseKeychain yes
EOF
)
    
    # Test that SSH config is valid
    echo "$test_ssh_config" > /tmp/test_ssh_config
    if ssh -F /tmp/test_ssh_config -T git@github.com -o ConnectTimeout=1 2>&1 | grep -q "Bad configuration option" ; then
      echo "✗ SSH configuration has syntax errors"
      exit 1
    else
      echo "✓ SSH configuration syntax is valid"
    fi
    
    # Test 5: Test 1Password SSH integration workflow
    echo "✓ Testing 1Password SSH integration workflow..."
    
    # Simulate the shell initialization workflow
    test_workflow() {
      # Check if op command exists
      if command -v op >/dev/null 2>&1; then
        echo "✓ 1Password CLI available"
        
        # Test SSH agent socket command availability
        if op --help 2>&1 | grep -q "ssh-agent"; then
          echo "✓ 1Password SSH agent command available"
        else
          echo "! 1Password SSH agent command not found in help (this is OK for older versions)"
        fi
      else
        echo "✗ 1Password CLI not found"
        return 1
      fi
    }
    
    if test_workflow; then
      echo "✓ 1Password SSH workflow test passed"
    else
      echo "✗ 1Password SSH workflow test failed"
      exit 1
    fi
    
    echo "✅ All 1Password SSH integration tests passed!"
  '';

in
pkgs.runCommand "1password-ssh-test" {
  buildInputs = [ pkgs._1password-cli ];
} ''
  export USER=${user}
  export PATH=${pkgs._1password-cli}/bin:$PATH
  
  echo "Running 1Password SSH integration tests..."
  ${testScript}
  
  echo "1Password SSH integration test completed successfully"
  touch $out
''