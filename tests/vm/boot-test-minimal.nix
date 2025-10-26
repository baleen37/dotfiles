# Minimal VM Boot Test
#
# Tests that a basic NixOS VM can boot to multi-user target
# and basic functionality works. Uses minimal configuration
# to avoid NetworkManager and complex dependencies.

{ pkgs, ... }:

(pkgs.nixosTest {
  name = "vm-boot-test-minimal";

  nodes = {
    # Test VM node - minimal configuration for VM testing
    vm = { config, ... }: {
      # Basic VM settings
      virtualisation.graphics = false;
      virtualisation.memorySize = 1024; # Minimal memory for test
      virtualisation.diskSize = 2048;  # Minimal disk for test

      # Basic system packages for testing
      environment.systemPackages = with pkgs; [
        git
        vim
        curl
        wget
        bashInteractive
      ];

      # Enable SSH for testing
      services.openssh.enable = true;
      services.openssh.permitRootLogin = "yes";

      # Simple networking for VM (not NetworkManager)
      networking.useDHCP = false;
      networking.useNetworkd = true;
      systemd.networks."10-eth0" = {
        matchConfig.Name = "eth0";
        networkConfig.DHCP = "yes";
      };

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

      # Set hostname (like in the actual VM config)
      networking.hostName = "nixos-vm-test";

      # Basic boot configuration
      boot.loader.grub.devices = [ "/dev/vda" ];

      # Minimal filesystem configuration
      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      # System settings
      system.stateVersion = "24.05";
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

    # Test that hostname is set correctly
    vm.succeed("hostname | grep 'nixos-vm-test'")
    print("✓ Hostname is set correctly")

    print("🎉 All VM boot tests passed!")
  '';
})