{ pkgs, flake ? null, src ? ../.. }:

pkgs.stdenv.mkDerivation {
  name = "bl-setup-dev-test";
  src = ../.;

  buildInputs = with pkgs; [ bash coreutils nix ];

  buildPhase = ''
    # Create test environment
    export HOME=$PWD/test-home
    export PATH=$PWD/test-bin:$PATH
    mkdir -p $HOME/.bl/commands
    mkdir -p test-bin

    # Copy setup-dev to bl commands
    cp scripts/setup-dev $HOME/.bl/commands/setup-dev
    chmod +x $HOME/.bl/commands/setup-dev

    # Copy bl script
    cp scripts/bl test-bin/bl
    chmod +x test-bin/bl

    echo "=== Testing bl setup-dev command ==="

    # Test 1: setup-dev --help should work
    echo "Test 1: bl setup-dev --help"
    if bl setup-dev --help | grep -q "Initialize a new Nix project"; then
      echo "✓ bl setup-dev --help works"
    else
      echo "✗ bl setup-dev --help failed"
      exit 1
    fi

    # Test 2: setup-dev should create project files in current directory
    echo "Test 2: bl setup-dev in current directory"
    cd $HOME
    mkdir project1
    cd project1

    bl setup-dev >/dev/null 2>&1 || true  # Allow it to fail due to nix not being fully available

    if [[ -f "flake.nix" && -f ".envrc" && -f ".gitignore" ]]; then
      echo "✓ bl setup-dev creates project files"
    else
      echo "✗ bl setup-dev doesn't create all required files"
      echo "  flake.nix: $(test -f flake.nix && echo exists || echo missing)"
      echo "  .envrc: $(test -f .envrc && echo exists || echo missing)"
      echo "  .gitignore: $(test -f .gitignore && echo exists || echo missing)"
      exit 1
    fi

    # Test 3: Verify flake.nix content
    echo "Test 3: flake.nix content validation"
    if grep -q "nixpkgs.url" flake.nix && grep -q "devShells.default" flake.nix; then
      echo "✓ flake.nix has correct structure"
    else
      echo "✗ flake.nix doesn't have correct structure"
      exit 1
    fi

    # Test 4: Verify .envrc content
    echo "Test 4: .envrc content validation"
    if grep -q "use flake" .envrc; then
      echo "✓ .envrc has correct content"
    else
      echo "✗ .envrc doesn't have correct content"
      exit 1
    fi

    # Test 5: Verify .gitignore content
    echo "Test 5: .gitignore content validation"
    if grep -q "result" .gitignore && grep -q ".direnv/" .gitignore; then
      echo "✓ .gitignore has Nix patterns"
    else
      echo "✗ .gitignore doesn't have Nix patterns"
      exit 1
    fi

    # Test 6: setup-dev with project directory argument
    echo "Test 6: bl setup-dev with directory argument"
    cd $HOME
    bl setup-dev project2 >/dev/null 2>&1 || true

    if [[ -d "project2" && -f "project2/flake.nix" && -f "project2/.envrc" ]]; then
      echo "✓ bl setup-dev creates new directory and files"
    else
      echo "✗ bl setup-dev doesn't create directory or files"
      exit 1
    fi

    # Test 7: setup-dev should not overwrite existing files
    echo "Test 7: bl setup-dev doesn't overwrite existing files"
    cd $HOME/project1
    echo "# Custom flake" > flake.nix
    bl setup-dev >/dev/null 2>&1 || true

    if grep -q "# Custom flake" flake.nix; then
      echo "✓ bl setup-dev doesn't overwrite existing flake.nix"
    else
      echo "✗ bl setup-dev overwrote existing flake.nix"
      exit 1
    fi

    # Test 8: Test executable permissions
    echo "Test 8: File permissions"
    cd $HOME/project2
    if [[ -x ".envrc" ]]; then
      echo "✓ .envrc is executable"
    else
      echo "✗ .envrc is not executable"
      exit 1
    fi

    echo "=== All bl setup-dev tests passed! ==="
  '';

  installPhase = ''
    mkdir -p $out
    echo "bl-setup-dev tests completed successfully" > $out/test-result
  '';
}
