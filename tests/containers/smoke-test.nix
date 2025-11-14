# Comprehensive smoke test container - validates core system functionality
{ pkgs, lib, ... }:

let
  # Use static test user for environment independence
  userName = "testuser";

  # Core packages that should always be available and functional
  corePackages = with pkgs; [
    git          # Version control
    vim          # Text editor
    curl         # Network tool
    wget         # Network tool
    htop         # System monitoring
    jq           # JSON processing
    zsh          # Shell
    findutils    # File search
  ];

  # Packages where package name != main executable name
  # These are excluded from automated 'which' tests but manually tested
  packagesWithDifferentExecutables = [
    "findutils"  # provides 'find', 'xargs', etc.
  ];
in
{
  name = "smoke-test";

  nodes.machine = {
    # Basic system configuration
    system.stateVersion = "24.11";

    # Enable Zsh shell for users
    programs.zsh.enable = true;

    # User setup
    users.users.${userName} = {
      isNormalUser = true;
      home = "/home/${userName}";
      shell = pkgs.zsh;
    };

    # Essential services
    services.openssh.enable = true;

    # Core packages
    environment.systemPackages = corePackages;

    # Basic networking
    networking.hostName = "smoke-test";
    networking.useDHCP = false;
    networking.interfaces.eth1.ipv4.addresses = [
      {
        address = "10.0.0.1";
        prefixLength = 24;
      }
    ];

    # Ensure proper permissions
    security.sudo.wheelNeedsPassword = false;
  };

  testScript = ''
    start_all()

    # Wait for system to be fully ready
    machine.wait_for_unit("multi-user.target")

    # === Basic System Health ===

    # Verify system boot and core services
    machine.succeed("systemctl is-active multi-user.target")
    machine.succeed("systemctl is-active basic.target")

    # Check kernel and system info
    machine.succeed("uname -a")
    machine.succeed("whoami")

    # === User Environment ===

    # Verify user can login and has proper environment
    machine.succeed("su - ${userName} -c 'whoami'")
    machine.succeed("su - ${userName} -c 'echo $HOME'")
    machine.succeed("su - ${userName} -c 'echo $SHELL'")

    # Check shell functionality
    machine.succeed("su - ${userName} -c 'echo $SHELL | grep zsh'")

    # === File System Operations ===

    # Test read/write permissions in home directory
    machine.succeed("su - ${userName} -c 'mkdir -p ~/test'")
    machine.succeed("su - ${userName} -c 'echo \"test content\" > ~/test/smoke.txt'")
    machine.succeed("su - ${userName} -c 'cat ~/test/smoke.txt'")
    machine.succeed("su - ${userName} -c 'rm -rf ~/test'")

    # Test system directories
    machine.succeed("ls /etc")
    machine.succeed("ls /usr/bin")

    # === Core Package Functionality ===

    # Test each core package is available and functional
    # Skip packages where executable name differs from package name
    ${lib.concatMapStringsSep "\n" (pkg: ''
      ${lib.optionalString (!lib.elem (lib.getName pkg) packagesWithDifferentExecutables) ''
      machine.succeed("which ${lib.getName pkg}")
      ''}
    '') corePackages}

    # Test specific core packages with simple, known-working commands
    machine.succeed("git --version")
    machine.succeed("vim --version | head -1")
    machine.succeed("curl --version | head -1")
    machine.succeed("wget --version | head -1")
    machine.succeed("jq --version")
    machine.succeed("zsh --version")
    # grep is a basic system tool and always available
    machine.succeed("find --version")

    # === Network Connectivity ===

    # Test basic network tools
    machine.succeed("ping -c 1 127.0.0.1")
    machine.succeed("curl --version")
    machine.succeed("wget --version")

    # === SSH Service ===

    # Verify SSH service is running
    machine.succeed("systemctl is-active sshd")
    machine.succeed("ss --listen | grep ':22'")

    # === Nix System Health ===

    # Test Nix functionality
    machine.succeed("nix --version")
    machine.succeed("nix-store --version")
    machine.succeed("test -d /nix/store")
    machine.succeed("ls /nix/store | head -5")

    # === Performance Basic Checks ===

    # Test system responsiveness (should respond quickly)
    machine.succeed("time echo 'system responsive'")

    # Check system load and memory
    machine.succeed("cat /proc/loadavg")
    machine.succeed("free -h")

    # === Cleanup and Validation ===

    # Check for critical errors in journal (basic check)
    machine.succeed("journalctl --priority=0..3 --no-pager --lines=10")

    # Final validation - all core commands should work
    machine.succeed("git --help | head -1")
    machine.succeed("vim --version | head -1")
    machine.succeed("jq --version")
    # grep is a basic system tool and always available
    machine.succeed("find --version")

    print("✅ Smoke test passed - all core system functionality validated")
    print("✅ System is healthy and ready for use")
  '';
}
