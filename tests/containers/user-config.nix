# User configuration container test
{ pkgs, lib, inputs, self }:

let
  # Import test utilities for environment-independent testing
  testUtils = import ../lib/test-utils.nix { inherit pkgs lib; };
  userName = testUtils.testUserName;
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

    # User setup for testing - use static test user
    users.users.${userName} = testUtils.mkTestUser {
      shell = pkgs.zsh;
      extraGroups = [ "wheel" ];  # Allow sudo for testing
    };

    # Enable Home Manager
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${userName} =
      testUtils.mkHomeManagerConfig { inherit userName; } // {
        # Core system utilities for testing
        home.packages = with pkgs; [
          git
          zsh
          vim
          curl
          ripgrep
        ];

        # Basic git configuration
        programs.git = {
          enable = true;
          userName = "Test User";
          userEmail = "test@example.com";
        };

        # Basic zsh configuration
        programs.zsh = {
          enable = true;
          enableCompletion = true;
          enableAutosuggestions = true;
          history.size = 10000;
          initExtra = ''
            export PATH=$HOME/.local/bin:$PATH
          '';
        };
      };

    services.openssh.enable = true;
  };

  testScript = ''
    start_all()

    # Wait for system to be ready
    machine.wait_for_unit("multi-user.target")

    # Use the static test user name
    userName = "${userName}"

    # Verify user home directory exists
    machine.succeed(f"test -d /home/{userName}")

    # Test user configuration files exist
    machine.succeed(f"test -f /home/{userName}/.zshrc")
    machine.succeed(f"test -f /home/{userName}/.gitconfig")

    # Verify essential packages are available
    machine.succeed("which git")
    machine.succeed("which zsh")

    # Test shell configuration
    machine.succeed(f"grep 'export PATH=' /home/{userName}/.zshrc")

    print("✅ User configuration test passed")
  '';
}
