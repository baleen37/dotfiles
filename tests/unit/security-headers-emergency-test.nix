# Emergency Security Headers Test - CRITICAL FOR PRODUCTION SAFETY
#
# This test validates that emergency security headers are properly configured
# to prevent XSS attacks and other critical vulnerabilities.
# IMMEDIATE VALIDATION REQUIRED FOR PRODUCTION DEPLOYMENT.

{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

{
  # Test 1: Security headers module is importable
  security-headers-module-imports-successfully = pkgs.runCommand "security-headers-module-imports-successfully" {
    buildInputs = [ pkgs.nix ];
  } ''
    echo "✅ Testing security headers module importability"
    if nix-instantiate --eval --expr 'builtins.isFunction (import ${../modules/security-headers.nix})'; then
      echo "✅ Security headers module imports successfully"
      touch $out
    else
      echo "❌ Security headers module failed to import"
      exit 1
    fi
  ''

  # Test 2: VM configuration includes emergency security
  vm-shared-includes-emergency-security = pkgs.runCommand "vm-shared-includes-emergency-security" {
    buildInputs = [ pkgs.nix ];
  } ''
    echo "✅ Testing VM emergency security configuration"
    if nix-instantiate --eval --expr '
      let
        pkgs = import ${inputs.nixpkgs.outPath} { system = "${system}"; };
        vmConfig = import ${../machines/nixos/vm-shared.nix} { config = {}; inherit pkgs; lib = pkgs.lib; };
      in vmConfig ? security.emergency.enable && vmConfig.security.emergency.enable == true
    '; then
      echo "✅ VM configuration includes emergency security"
      touch $out
    else
      echo "❌ VM configuration missing emergency security"
      exit 1
    fi
  ''

  # Test 3: Security headers configuration contains essential headers
  essential-security-headers-present = pkgs.runCommand "essential-security-headers-present" {
    buildInputs = [ pkgs.nix ];
  } ''
    echo "✅ Testing essential security headers"
    if nix-instantiate --eval --expr '
      let
        pkgs = import ${inputs.nixpkgs.outPath} { system = "${system}"; };
        eval = pkgs.nixos {
          configuration = {
            imports = [ ${../modules/security-headers.nix} ];
            security.emergency.enable = true;
          };
          system.stateVersion = "24.11";
        };
        headersContent = eval.config.environment.etc."security-headers.conf".text;
      in
        (builtins.match ".*X-Frame-Options.*DENY.*" headersContent != null) &&
        (builtins.match ".*X-Content-Type-Options.*nosniff.*" headersContent != null) &&
        (builtins.match ".*Content-Security-Policy.*" headersContent != null)
    '; then
      echo "✅ Essential security headers are present"
      touch $out
    else
      echo "❌ Essential security headers missing"
      exit 1
    fi
  ''

  # Test 4: Emergency deployment validation
  emergency-deployment-validation = pkgs.runCommand "emergency-deployment-validation" {
    buildInputs = [ pkgs.nix ];
  } ''
    echo "✅ Testing emergency deployment validation"
    if nix-instantiate --eval --expr '
      let
        pkgs = import ${inputs.nixpkgs.outPath} { system = "${system}"; };
        eval = pkgs.nixos {
          configuration = {
            imports = [
              ${../modules/security-headers.nix}
              ${../machines/nixos/vm-shared.nix}
            ];
            system.stateVersion = "24.11";
          };
      };
      in eval.config ? security.emergency.enable && eval.config.security.emergency.enable == true
    '; then
      echo "✅ Emergency deployment validation successful"
      touch $out
    else
      echo "❌ Emergency deployment validation failed"
      exit 1
    fi
  ''
}
