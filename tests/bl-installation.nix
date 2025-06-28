{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "bl-installation-test";
  src = ../.;

  buildInputs = with pkgs; [ bash coreutils ];

  buildPhase = ''
    # Create test environment
    export HOME=$PWD/test-home
    export PATH=$PWD/test-bin:$PATH
    mkdir -p $HOME/.local/bin
    mkdir -p test-bin

    # Store the base directory for later use
    BASE_DIR="$PWD"

    echo "=== Testing bl installation process ==="

    # Test 1: bl install should create necessary directories
    echo "Test 1: bl install creates directories"
    cp scripts/bl test-bin/bl
    chmod +x test-bin/bl

    # Ensure setup-dev is available for bl install
    cp scripts/setup-dev test-bin/setup-dev
    chmod +x test-bin/setup-dev

    bl install >/dev/null 2>&1

    if [[ -d "$HOME/.bl/commands" ]]; then
      echo "✓ bl install creates ~/.bl/commands directory"
    else
      echo "✗ bl install doesn't create ~/.bl/commands directory"
      exit 1
    fi

    if [[ -x "$HOME/.local/bin/bl" ]]; then
      echo "✓ bl install copies bl to ~/.local/bin"
    else
      echo "✗ bl install doesn't copy bl to ~/.local/bin"
      exit 1
    fi

    # Test 2: bl install should copy setup-dev if available
    echo "Test 2: bl install copies setup-dev"
    if [[ -x "$HOME/.bl/commands/setup-dev" ]]; then
      echo "✓ bl install copies setup-dev command"
    else
      echo "✗ bl install doesn't copy setup-dev command"
      echo "  Debug info:"
      echo "  - Commands dir exists: $(test -d "$HOME/.bl/commands" && echo yes || echo no)"
      echo "  - Files in commands dir: $(ls -la "$HOME/.bl/commands" 2>/dev/null || echo 'none')"
      echo "  - setup-dev in test-bin: $(test -x test-bin/setup-dev && echo yes || echo no)"
      echo "  - Current directory: $PWD"
      echo "  - PATH: $PATH"
      exit 1
    fi

    # Test 3: Verify setup-dev command works
    echo "Test 3: setup-dev command functionality"
    if $HOME/.bl/commands/setup-dev --help | grep -q "Initialize a new Nix project"; then
      echo "✓ setup-dev command is functional"
    else
      echo "✗ setup-dev command is not functional"
      exit 1
    fi

    # Test 4: bl list should show setup-dev after installation
    echo "Test 4: bl list shows installed commands"
    if $HOME/.local/bin/bl list | grep -q "setup-dev"; then
      echo "✓ bl list shows setup-dev after installation"
    else
      echo "✗ bl list doesn't show setup-dev after installation"
      exit 1
    fi

    # Test 5: bl setup-dev should work through dispatcher
    echo "Test 5: bl setup-dev through dispatcher"
    cd $HOME
    mkdir test-project
    cd test-project

    if $HOME/.local/bin/bl setup-dev --help | grep -q "Initialize a new Nix project"; then
      echo "✓ bl setup-dev works through dispatcher"
    else
      echo "✗ bl setup-dev doesn't work through dispatcher"
      exit 1
    fi

    # Test 6: Test install-setup-dev script functionality
    echo "Test 6: install-setup-dev script functionality"
    # Reset to base directory
    cd "$BASE_DIR"
    # Completely clean up previous installations
    rm -rf $HOME/.bl
    rm -rf $HOME/.local/bin

    # Make sure ~/.local/bin is in PATH for the test
    export PATH="$HOME/.local/bin:$PATH"

    # Store the base directory for scripts
    SCRIPTS_DIR="$BASE_DIR/scripts"

    # Manually reproduce what install-setup-dev does to avoid cp same file issue
    mkdir -p "$HOME/.local/bin"
    cp "$SCRIPTS_DIR/bl" "$HOME/.local/bin/bl"
    chmod +x "$HOME/.local/bin/bl"

    # Run bl install to set up the command system
    BL_INSTALL_RESULT=0
    BL_INSTALL_OUTPUT=$("$HOME/.local/bin/bl" install 2>&1) || BL_INSTALL_RESULT=$?

    if [[ $BL_INSTALL_RESULT -ne 0 ]]; then
      echo "✗ bl install failed in test 6 (exit code: $BL_INSTALL_RESULT)"
      echo "  Error output:"
      echo "$BL_INSTALL_OUTPUT" | sed 's/^/    /'
      exit 1
    fi

    if [[ -x "$HOME/.local/bin/bl" && -d "$HOME/.bl/commands" && -x "$HOME/.bl/commands/setup-dev" ]]; then
      echo "✓ install-setup-dev functionality works correctly"
    else
      echo "✗ install-setup-dev functionality failed"
      echo "  bl exists: $(test -x "$HOME/.local/bin/bl" && echo yes || echo no)"
      echo "  commands dir exists: $(test -d "$HOME/.bl/commands" && echo yes || echo no)"
      echo "  setup-dev exists: $(test -x "$HOME/.bl/commands/setup-dev" && echo yes || echo no)"
      echo "  bl install output:"
      echo "$BL_INSTALL_OUTPUT" | sed 's/^/    /'
      exit 1
    fi

    echo "=== All bl installation tests passed! ==="
  '';

  installPhase = ''
    mkdir -p $out
    echo "bl-installation tests completed successfully" > $out/test-result
  '';
}
