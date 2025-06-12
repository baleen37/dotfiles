{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "bl-commands-test";
  src = ../.;

  buildInputs = with pkgs; [ bash coreutils ];

  buildPhase = ''
        # Create test environment
        export HOME=$PWD/test-home
        export PATH=$PWD/test-bin:$PATH
        mkdir -p $HOME/.bl/commands
        mkdir -p test-bin

        # Copy bl script to test environment
        cp scripts/bl test-bin/bl
        chmod +x test-bin/bl

        # Create a dummy test command
        cat > $HOME/.bl/commands/test-cmd << 'EOF'
    #!/usr/bin/env bash
    echo "test-cmd executed with args: $@"
    exit 0
    EOF
        chmod +x $HOME/.bl/commands/test-cmd

        # Create another test command that fails
        cat > $HOME/.bl/commands/fail-cmd << 'EOF'
    #!/usr/bin/env bash
    echo "fail-cmd executed"
    exit 1
    EOF
        chmod +x $HOME/.bl/commands/fail-cmd

        echo "=== Testing bl command dispatcher ==="

        # Test 1: bl --help should work
        echo "Test 1: bl --help"
        output=$(bl --help 2>&1 || echo "COMMAND_FAILED")

        if echo "$output" | grep -q "bl - Baleen's custom command system"; then
          echo "✓ bl --help works"
        else
          echo "✗ bl --help failed"
          exit 1
        fi

        # Test 2: bl list should show available commands
        echo "Test 2: bl list"
        if bl list | grep -q "test-cmd"; then
          echo "✓ bl list shows test-cmd"
        else
          echo "✗ bl list doesn't show test-cmd"
          exit 1
        fi

        # Test 3: bl test-cmd should execute the command
        echo "Test 3: bl test-cmd with arguments"
        output=$(bl test-cmd arg1 arg2 2>&1)
        if echo "$output" | grep -q "test-cmd executed with args: arg1 arg2"; then
          echo "✓ bl test-cmd executes correctly with arguments"
        else
          echo "✗ bl test-cmd failed. Output: $output"
          exit 1
        fi

        # Test 4: bl nonexistent should fail gracefully
        echo "Test 4: bl nonexistent"
        output=$(bl nonexistent 2>&1 || true)
        echo "DEBUG: bl nonexistent output: $output"

        if echo "$output" | grep -q "Command 'nonexistent' not found"; then
          echo "✓ bl nonexistent fails gracefully"
        else
          echo "✗ bl nonexistent doesn't fail properly"
          echo "Expected to find: 'Command 'nonexistent' not found'"
          echo "Got: $output"
          exit 1
        fi

        # Test 5: bl fail-cmd should propagate exit code
        echo "Test 5: bl fail-cmd"
        if ! bl fail-cmd >/dev/null 2>&1; then
          echo "✓ bl fail-cmd propagates exit code"
        else
          echo "✗ bl fail-cmd doesn't propagate exit code"
          exit 1
        fi

        # Test 6: bl without arguments should show help
        echo "Test 6: bl without arguments"
        output=$(bl 2>&1 || true)
        echo "DEBUG: bl output: $output"

        if echo "$output" | grep -q "Usage: bl"; then
          echo "✓ bl without arguments shows usage"
        else
          echo "✗ bl without arguments doesn't show usage"
          echo "Expected to find: 'Usage: bl'"
          echo "Got: $output"
          exit 1
        fi

        # Test 7: Test with missing bl directory
        echo "Test 7: bl with missing directory"
        rm -rf $HOME/.bl
        output=$(bl test-cmd 2>&1 || true)
        echo "DEBUG: bl test-cmd with missing dir output: $output"

        if echo "$output" | grep -q "bl command system not installed"; then
          echo "✓ bl handles missing directory correctly"
        else
          echo "✗ bl doesn't handle missing directory properly"
          echo "Expected to find: 'bl command system not installed'"
          echo "Got: $output"
          exit 1
        fi

        echo "=== All bl command dispatcher tests passed! ==="
  '';

  installPhase = ''
    mkdir -p $out
    echo "bl-commands tests completed successfully" > $out/test-result
  '';
}
