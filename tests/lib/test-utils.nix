# Test utilities for environment-independent testing
{ pkgs, lib, ... }:

let
  # Detect if we're in CI environment
  isCI = builtins.getEnv "GITHUB_ACTIONS" == "true";

  # Static test users for container tests
  testUsers = {
    main = "testuser";
    secondary = "testuser2";
    service = "testservice";
  };

  # Choose user based on environment
  # In CI: use static test users
  # In local: optionally use real user for debugging
  testUserName =
    if isCI then
      testUsers.main
    else
      let
        envUser = builtins.getEnv "TEST_USER";
      in
      if envUser != "" then envUser else testUsers.main;

in
{
  inherit isCI testUsers testUserName;

  # Helper to create test user configuration
  mkTestUser =
    {
      name ? testUserName,
      extraGroups ? [ ],
      ...
    }:
    {
      isNormalUser = true;
      home = "/home/${name}";
      inherit extraGroups;
    };

  # Helper for Home Manager configuration
  mkHomeManagerConfig =
    {
      userName ? testUserName,
      ...
    }:
    {
      home = {
        username = userName;
        homeDirectory = "/home/${userName}";
        stateVersion = "24.11";
      };
    };
}
