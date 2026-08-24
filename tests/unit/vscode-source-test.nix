# VS Code must come from Homebrew on Darwin, not from the nix store.
#
# macOS stamps `com.apple.macl` onto an app bundle that gets launched from its
# own path. When that path is a nix store path, `nix-collect-garbage` can no
# longer chmod or delete it and the whole GC run fails with
# "Operation not permitted". Homebrew installs into /Applications, which GC
# never touches.
{
  inputs,
  system,
  self,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Evaluate users/shared/packages/dev.nix on its own, the same way
  # security-packages-test.nix does, to read the package list it contributes.
  homeOptionsModule = {
    options.home.packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
  };

  devPackages =
    (lib.evalModules {
      modules = [
        homeOptionsModule
        (import ../../users/shared/packages/dev.nix)
        { _module.args = { inherit pkgs; }; }
        { config.modules.packages.dev.enable = true; }
      ];
    }).config.home.packages;

  devPackageNames = map (pkg: pkg.pname or pkg.name or "") devPackages;
  hasNixVscode = builtins.any (name: name == "vscode") devPackageNames;

  darwinSystemPackages =
    self.darwinConfigurations.kakaostyle-jito.config.home-manager.users."jito.hello".home.packages;
  darwinSystemPackageNames = map (pkg: pkg.pname or pkg.name or "") darwinSystemPackages;
  standaloneHomePackages = self.homeConfigurations."jito.hello".config.home.packages;
  standaloneHomePackageNames = map (pkg: pkg.pname or pkg.name or "") standaloneHomePackages;
  hasDarwinSystemVscode = builtins.any (name: name == "vscode") darwinSystemPackageNames;
  hasStandaloneHomeVscode = builtins.any (name: name == "vscode") standaloneHomePackageNames;
  standaloneActivation =
    self.homeConfigurations."jito.hello".config.home.activation.vscodeLaunchServices;

  # nix-darwin normalises `homebrew.casks` entries into attrsets, so compare names.
  caskNames = map (cask: cask.name) self.darwinConfigurations.kakaostyle-jito.config.homebrew.casks;
in
{
  platforms = [ "darwin" ];
  value = {
    vscode-not-from-nix-store =
      helpers.assertTest "vscode not from nix store" (!hasNixVscode)
        "VS Code must not be in home.packages on Darwin: launching it from a store path stamps com.apple.macl and breaks nix-collect-garbage";

    vscode-from-homebrew-cask =
      helpers.assertTest "vscode from homebrew cask" (builtins.elem "visual-studio-code" caskNames)
        "VS Code should be installed via the visual-studio-code Homebrew cask on Darwin";

    vscode-not-in-darwin-system-home-packages =
      helpers.assertTest "vscode not in Darwin system Home Manager packages" (!hasDarwinSystemVscode)
        "Darwin system Home Manager must not add VS Code from the nix store";

    vscode-not-in-standalone-home-packages =
      helpers.assertTest "vscode not in standalone Home Manager packages" (!hasStandaloneHomeVscode)
        "standalone make switch-home Home Manager must not add VS Code from the nix store";

    vscode-launchservices-standalone-activation =
      helpers.assertTest "VS Code LaunchServices repair in standalone activation"
        (
          lib.hasInfix "vscode-launchservices.sh" standaloneActivation.data
          && lib.hasInfix "repair" standaloneActivation.data
        )
        "standalone Home Manager activation must run the shared VS Code LaunchServices repair adapter";
  };
}
