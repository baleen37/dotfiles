# User configuration container test
{ pkgs, lib, inputs, ... }:

let
  user =
    let
      envUser = builtins.getEnv "USER";
    in
    if envUser != "" then envUser else "baleen";
in {
  name = "user-config-test";

  nodes.machine = {
    imports = [
      # Import home-manager module for NixOS
      inputs.home-manager.nixosModules.home-manager
    ];

    # Basic system setup
    system.stateVersion = "24.11";

    # Enable Zsh shell
    programs.zsh.enable = true;

    # User setup for testing
    users.users.${user} = {
      isNormalUser = true;
      home = "/home/${user}";
      shell = pkgs.zsh;
    };

    # Enable Home Manager
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${user} = {
      home = {
        username = user;
        homeDirectory = "/home/${user}";
        stateVersion = "24.11";

        # Core system utilities for testing
        packages = with pkgs; [
          git
          zsh
          vim
          curl
          ripgrep
        ];
      };

      # Import key user configurations for testing
      imports = [
        ../../users/shared/git.nix
        ../../users/shared/zsh.nix
      ];
    };

    services.openssh.enable = true;
  };

  testScript = ''
    start_all()

    # Wait for system to be ready
    machine.wait_for_unit("multi-user.target")

    # Verify user home directory exists
    machine.succeed("test -d /home/${user}")

    # Test user configuration files exist
    machine.succeed("test -f /home/${user}/.zshrc")
    machine.succeed("test -f /home/${user}/.gitconfig")

    # Verify essential packages are available
    machine.succeed("which git")
    machine.succeed("which zsh")

    # Test shell configuration
    machine.succeed("grep 'export PATH=' /home/${user}/.zshrc")
  '';
}
