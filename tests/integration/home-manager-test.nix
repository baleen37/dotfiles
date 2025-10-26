# tests/integration/home-manager-test.nix
#
# Home Manager Integration Tests
#
# Tests the integration of all extracted tool configurations into unified home-manager.nix
# Validates imports, structure, and basic configuration attributes
#
# Tool configurations tested:
#   - git.nix: Git version control configuration
#   - vim.nix: Vim editor with plugins
#   - zsh.nix: Zsh shell with Powerlevel10k theme
#   - tmux.nix: Terminal multiplexer configuration
#   - claude-code.nix: Claude Code AI assistant
#
# Integration aspects verified:
#   - Module imports load without errors
#   - Home Manager configuration structure is valid
#   - User configuration (username, home directory) is correct
#   - Package list is populated with expected tools
#   - XDG base directory specification is enabled
#   - Cross-platform home directory resolution works

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  nixtest ? null,
}:

let
  # Use provided NixTest framework and helpers (or fallback to local imports)
  nixtestFinal =
    if nixtest != null then
      nixtest
    else
      (import ../unit/nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Import home-manager configuration for testing
  homeManagerModule = import ../../users/baleen/home-manager.nix {
    inherit pkgs lib;
    inputs = { }; # Mock inputs for testing
  };

  # Mock Home Manager configuration for testing
  mockHomeManagerConfig = {
    home = {
      username = "baleen";
      homeDirectory = if lib.strings.hasSuffix "darwin" system then "/Users/baleen" else "/home/baleen";
      stateVersion = "24.11";
    };
    programs = { };
    services = { };
    xdg = { };
  };

  # Helper to safely evaluate module
  safeEvaluateModule =
    module: extraConfig:
    let
      result = builtins.tryEval (
        lib.evalModules {
          modules = [
            module
            extraConfig
            mockHomeManagerConfig
          ];
        }
      );
    in
    if result.success then result.value else null;

in
nixtestFinal.suite "Home Manager Integration Tests" {

  homeManagerModuleLoading = nixtestFinal.test "Home Manager module loads without errors" (
    let
      result = safeEvaluateModule homeManagerModule { };
    in
    nixtestFinal.assertions.assertTrue (result != null)
  );

  homeManagerHasImports = nixtestFinal.test "Home Manager has required imports" (
    let
      result = safeEvaluateModule homeManagerModule { };
      hasImports =
        if result != null then
          builtins.hasAttr "imports" result.config || builtins.hasAttr "imports" homeManagerModule
        else
          false;
    in
    nixtestFinal.assertions.assertTrue hasImports
  );

  homeManagerHasHomeConfig = nixtestFinal.test "Home Manager has home configuration" (
    let
      result = safeEvaluateModule homeManagerModule { };
      hasHomeConfig = if result != null then builtins.hasAttr "home" result.config else false;
    in
    nixtestFinal.assertions.assertTrue hasHomeConfig
  );

  homeManagerUsernameCorrect = nixtestFinal.test "Home Manager username is baleen" (
    let
      result = safeEvaluateModule homeManagerModule { };
      usernameMatches =
        if result != null && builtins.hasAttr "home" result.config then
          result.config.home.username == "baleen"
        else
          false;
    in
    nixtestFinal.assertions.assertTrue usernameMatches
  );

  homeManagerPackagesPopulated = nixtestFinal.test "Home Manager packages are populated" (
    let
      result = safeEvaluateModule homeManagerModule { };
      hasPackages =
        if result != null && builtins.hasAttr "home" result.config then
          builtins.length result.config.home.packages > 0
        else
          false;
    in
    nixtestFinal.assertions.assertTrue hasPackages
  );

  homeManagerXDGEnabled = nixtestFinal.test "Home Manager XDG is enabled" (
    let
      result = safeEvaluateModule homeManagerModule { };
      xdgEnabled =
        if result != null then
          (builtins.hasAttr "xdg" result.config && result.config.xdg.enable == true)
          || (builtins.hasAttr "xdg" homeManagerModule && homeManagerModule.xdg.enable == true)
        else
          false;
    in
    nixtestFinal.assertions.assertTrue xdgEnabled
  );

  homeManagerHomeManagerEnabled = nixtestFinal.test "Home Manager is enabled" (
    let
      result = safeEvaluateModule homeManagerModule { };
      hmEnabled =
        if result != null && builtins.hasAttr "programs" result.config then
          result.config.programs.home-manager.enable == true
        else
          false;
    in
    nixtestFinal.assertions.assertTrue hmEnabled
  );

  homeManagerCrossPlatformHomeDir =
    nixtestFinal.test "Home Manager resolves home directory cross-platform"
      (
        let
          result = safeEvaluateModule homeManagerModule { };
          homeDirCorrect =
            if result != null && builtins.hasAttr "home" result.config then
              let
                expectedHome = if lib.strings.hasSuffix "darwin" system then "/Users/baleen" else "/home/baleen";
              in
              result.config.home.homeDirectory == expectedHome
            else
              false;
        in
        nixtestFinal.assertions.assertTrue homeDirCorrect
      );

  homeManagerStateVersionCorrect = nixtestFinal.test "Home Manager state version is correct" (
    let
      result = safeEvaluateModule homeManagerModule { };
      stateVersionCorrect =
        if result != null && builtins.hasAttr "home" result.config then
          result.config.home.stateVersion == "24.11"
        else
          false;
    in
    nixtestFinal.assertions.assertTrue stateVersionCorrect
  );
}
