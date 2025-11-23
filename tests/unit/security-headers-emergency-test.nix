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

let
  helpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };
in
helpers.testSuite "emergency-security-headers" [
  # Test 1: Security headers module importability
  (helpers.assertTestWithDetails "security-headers-module-imports-successfully"
    (builtins.isFunction (import ../modules/security-headers.nix))
    "Emergency security headers module should be importable and function properly"
    true
    (builtins.isFunction (import ../modules/security-headers.nix))
  )

  # Test 2: VM configuration includes emergency security
  (helpers.assertTestWithDetails "vm-shared-includes-emergency-security"
    (let
      vmConfig = import ../machines/nixos/vm-shared.nix { inherit config pkgs lib; };
    in
    vmConfig ? security.emergency.enable && vmConfig.security.emergency.enable == true)
    "VM shared configuration should enable emergency security module"
    true
    (let
      vmConfig = import ../machines/nixos/vm-shared.nix { config = {}; inherit pkgs lib; };
    in
    vmConfig ? security.emergency.enable)
  )

  # Test 3: Security headers configuration exists
  (helpers.assertTestWithDetails "security-headers-config-created"
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [ ../modules/security-headers.nix ];
          security.emergency.enable = true;
        };
        system.stateVersion = "24.11";
      };
    in
    eval.config ? environment.etc."security-headers.conf")
    "Security headers configuration file should be created"
    true
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [ ../modules/security-headers.nix ];
          security.emergency.enable = true;
        };
        system.stateVersion = "24.11";
      };
    in
    eval.config.environment.etc."security-headers.conf" ? text)
  )

  # Test 4: Essential security headers are present
  (helpers.assertTestWithDetails "essential-security-headers-present"
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [ ../modules/security-headers.nix ];
          security.emergency.enable = true;
        };
        system.stateVersion = "24.11";
      };
      headersContent = eval.config.environment.etc."security-headers.conf".text;
    in
    # Check for critical security headers
    (builtins.match ".*X-Frame-Options.*DENY.*" headersContent != null) &&
    (builtins.match ".*X-Content-Type-Options.*nosniff.*" headersContent != null) &&
    (builtins.match ".*X-XSS-Protection.*mode=block.*" headersContent != null) &&
    (builtins.match ".*Content-Security-Policy.*" headersContent != null))
    "Essential security headers (XSS protection, CSP, frame options) must be present"
    "All critical security headers for XSS protection should be configured"
    "Missing one or more critical security headers"
  )

  # Test 5: Security validation script created
  (helpers.assertTestWithDetails "security-validation-script-created"
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [ ../modules/security-headers.nix ];
          security.emergency.enable = true;
        };
        system.stateVersion = "24.11";
      };
    in
    eval.config ? system.activationScripts.emergencySecurityHeaders)
    "Security validation activation script should be created"
    true
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [ ../modules/security-headers.nix ];
          security.emergency.enable = true;
        };
        system.stateVersion = "24.11";
      };
    in
    eval.config.system.activationScripts.emergencySecurityHeaders ? text)
  )

  # Test 6: Firewall security hardening enabled
  (helpers.assertTestWithDetails "firewall-security-hardening-enabled"
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [ ../modules/security-headers.nix ];
          security.emergency.enable = true;
        };
        system.stateVersion = "24.11";
      };
    in
    eval.config.networking.firewall.enable == true)
    "Firewall should be enabled for security hardening"
    true
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [ ../modules/security-headers.nix ];
          security.emergency.enable = true;
        };
        system.stateVersion = "24.11";
      };
    in
    eval.config.networking.firewall.enable)
  )

  # Test 7: Security monitoring service configured
  (helpers.assertTestWithDetails "security-monitoring-service-configured"
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [ ../modules/security-headers.nix ];
          security.emergency.enable = true;
        };
        system.stateVersion = "24.11";
      };
    in
    eval.config.systemd.services ? emergency-security-monitor)
    "Emergency security monitoring service should be configured"
    true
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [ ../modules/security-headers.nix ];
          security.emergency.enable = true;
        };
        system.stateVersion = "24.11";
      };
    in
    eval.config.systemd.services.emergency-security-monitor.enable)
  )

  # Test 8: Emergency deployment validation
  (helpers.assertTestWithDetails "emergency-deployment-validation"
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [
            ../modules/security-headers.nix
            ../machines/nixos/vm-shared.nix
          ];
          system.stateVersion = "24.11";
        };
      };
    in
    eval.config ? security.emergency.enable && eval.config.security.emergency.enable == true)
    "Emergency security configuration should be properly enabled in VM"
    "Security hardening should be active for emergency deployment"
    (let
      eval = pkgs.nixos {
        configuration = {
          imports = [
            ../modules/security-headers.nix
            ../machines/nixos/vm-shared.nix
          ];
          system.stateVersion = "24.11";
        };
      };
    in
    if eval.config ? security.emergency.enable then
      if eval.config.security.emergency.enable then "ENABLED"
      else "DISABLED"
    else "NOT_CONFIGURED"))
  ]
