# Simplified real project workflow test
# Core functionality validation without over-engineering
{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  system ? builtins.currentSystem,
}:

let
  nixosTest = pkgs.testers.nixosTest or (import "${<nixpkgs>}/nixos/lib/testing-python.nix" {
    inherit system pkgs;
  });
in

nixosTest {
  name = "real-project-workflow-test";

  nodes.machine = { config, pkgs, ... }: {
    # Basic VM configuration
    virtualisation.cores = 2;
    virtualisation.memorySize = 2048;
    virtualisation.diskSize = 4096;

    # Essential development tools
    environment.systemPackages = with pkgs; [
      git
      vim
      zsh
      tmux
      curl
      wget
    ];

    # Basic git configuration
    environment.variables.GIT_AUTHOR_NAME = "Test User";
    environment.variables.GIT_AUTHOR_EMAIL = "test@example.com";

    # Enable basic services
    services.openssh.enable = true;
    networking.firewall.enable = false;
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("echo 'Basic system ready'")

    # Test 1: Basic development tools availability
    machine.succeed("git --version")
    machine.succeed("vim --version | head -1")
    machine.succeed("zsh --version")
    machine.succeed("tmux -V")

    # Test 2: Simple project workflow
    machine.succeed("mkdir -p /tmp/test-project && cd /tmp/test-project")
    machine.succeed("git init /tmp/test-project")
    machine.succeed("echo '# Test Project' > /tmp/test-project/README.md")
    machine.succeed("cd /tmp/test-project && git add README.md")
    machine.succeed("cd /tmp/test-project && git commit -m 'Initial commit'")

    # Test 3: File editing workflow
    machine.succeed("echo 'print(\"Hello World\")' > /tmp/test-project/test.py")

    # Test 4: Basic shell functionality
    machine.succeed("echo 'test' | grep -q test")

    print("✅ Real project workflow test completed successfully")
  '';
}
