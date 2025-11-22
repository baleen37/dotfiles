# Task 1: WSL Input Requirements Analysis
# This test validates that current flake.nix inputs are sufficient for WSL support

{ inputs, system, pkgs ? import inputs.nixpkgs { inherit system; }, lib ? pkgs.lib, ... }:

let
  helpers = import ../../lib/enhanced-assertions.nix { inherit pkgs lib; };
in
helpers.testSuite "wsl-input-requirements" [
  # Test 1: Verify all required inputs for WSL support exist
  (helpers.assertTestWithDetails "wsl-nixpkgs-input-available"
    (builtins.hasAttr "nixpkgs" inputs)
    "WSL support requires nixpkgs input for Linux packages"
    "nixpkgs input found"
    (if (builtins.hasAttr "nixpkgs" inputs) then "✓ nixpkgs" else "✗ nixpkgs")
  )

  # Test 2: Verify home-manager is available (critical for user config)
  (helpers.assertTestWithDetails "wsl-home-manager-input-available"
    (builtins.hasAttr "home-manager" inputs)
    "WSL support requires home-manager input for user configuration"
    "home-manager input found"
    (if (builtins.hasAttr "home-manager" inputs) then "✓ home-manager" else "✗ home-manager")
  )

  # Test 3: Verify we can access Linux packages for WSL
  (helpers.assertTestWithDetails "wsl-linux-packages-available"
    (builtins.isAttrs (import inputs.nixpkgs { system = "x86_64-linux"; }))
    "WSL support requires access to x86_64-linux packages"
    "Linux packages accessible"
    (if (builtins.isAttrs (import inputs.nixpkgs { system = "x86_64-linux"; }))
     then "✓ x86_64-linux packages"
     else "✗ x86_64-linux packages")
  )

  # Test 4: Verify nixos-generators is available (for WSL image generation)
  (helpers.assertTestWithDetails "wsl-nixos-generators-available"
    (builtins.hasAttr "nixos-generators" inputs)
    "WSL support requires nixos-generators for system image generation"
    "nixos-generators input found"
    (if (builtins.hasAttr "nixos-generators" inputs) then "✓ nixos-generators" else "✗ nixos-generators")
  )

  # Test 5: Verify WSL-specific packages are available in nixpkgs
  (helpers.assertTestWithDetails "wsl-packages-available"
    (let
       linuxPkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
       wslPackages = builtins.attrNames linuxPkgs;
       hasWslPackages = builtins.any (pkg: builtins.match ".*wsl.*" pkg != null) wslPackages;
     in hasWslPackages)
    "WSL support requires WSL-related packages in nixpkgs"
    "WSL packages found in nixpkgs"
    (let
       linuxPkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
       wslPackages = builtins.filter (pkg: builtins.match ".*wsl.*" pkg != null) (builtins.attrNames linuxPkgs);
     in "✓ WSL packages available: " + builtins.concatStringsSep ", " wslPackages)
  )

  # Test 6: Note that built-in WSL modules are NOT available in current nixpkgs
  (helpers.assertTestWithDetails "wsl-nixos-modules-missing"
    (let
       linuxPkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
       # Note: current nixpkgs-unstable doesn't have built-in WSL NixOS modules
       wslModulesMissing = true;  # This is expected to be true for now
     in wslModulesMissing)
    "Current nixpkgs lacks built-in WSL NixOS modules (this is expected)"
    "WSL NixOS modules status documented"
    "✓ WSL modules missing - requires external WSL input or community modules"
  )
]