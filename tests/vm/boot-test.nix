# Simple VM Boot Test
#
# Tests that the NixOS VM can boot to multi-user target
# and basic functionality works. Uses NixOS's built-in
# nixosTest framework for simplicity and reliability.

{ pkgs, ... }:

let
  # Import the VM configuration (basic machine settings only)
  vmConfig = import ../../machines/nixos-vm.nix;

in
(pkgs.nixosTest {
  name = "vm-boot-test";

  nodes = {
    # Test VM node - simplified configuration for VM testing
    vm = { config, ... }: {
      imports = [
        vmConfig
      ];

      # Override VM-specific settings for testing
      virtualisation.graphics = false;
      virtualisation.memorySize = 1024; # Minimal memory for test
      virtualisation.diskSize = 2048;  # Minimal disk for test

      # Basic system packages for testing
      environment.systemPackages = with pkgs; [
        git
        vim
        curl
        wget
      ];

      # Enable SSH for testing
      services.openssh.enable = true;
      services.openssh.permitRootLogin = "yes";

      # Simple networking for VM - use default DHCP
      networking.useDHCP = true;

      # Add test user
      users.users.testuser = {
        isNormalUser = true;
        password = "test123";
        extraGroups = [ "wheel" ];
      };

      # Enable basic shell
      users.users.root.shell = pkgs.bashInteractive;
      users.users.testuser.shell = pkgs.bashInteractive;
      programs.bash.enable = true;
    };
  };

  testScript = ''
    # Start the VM
    vm.start()

    # Wait for VM to boot and reach multi-user target
    vm.wait_for_unit("multi-user.target")
    print("✓ VM reached multi-user target")

    # Test that user can login
    vm.succeed("su - testuser -c 'whoami'")
    print("✓ User login works")

    # Test basic commands
    vm.succeed("echo 'Hello from VM' > /tmp/test.txt")
    vm.succeed("cat /tmp/test.txt | grep 'Hello from VM'")
    print("✓ Basic file operations work")

    # Test that basic programs are available
    vm.succeed("which git")
    vm.succeed("which vim")
    print("✓ Basic programs available")

    # Test that user home directory exists
    vm.succeed("test -d /home/testuser")
    print("✓ User home directory exists")

    # Test network connectivity (should work with systemd-networkd)
    vm.succeed("ping -c 1 8.8.8.8")
    print("✓ Network connectivity works")

    # Test that we can create and modify files
    vm.succeed("echo 'test content' > /home/testuser/test_file.txt")
    vm.succeed("grep -q 'test content' /home/testuser/test_file.txt")
    print("✓ File creation and modification works")

    # Test basic shell functionality
    vm.succeed("bash -c 'echo \"Shell test: \$((2+2))\"' | grep 'Shell test: 4'")
    print("✓ Shell functionality works")

    print("🎉 All VM boot tests passed!")
  '';
})