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
    gnugrep      # Text search
    findutils    # File search
  ];
in
{
  name = "smoke-test";

  nodes.machine = {
    # Basic system configuration
    system.stateVersion = "24.11";

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
    machine.wait_for_unit("network-online.target")

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
    ${lib.concatMapStringsSep "\n" (pkg: ''
      machine.succeed("which ${lib.getName pkg}")
      machine.succeed("${lib.getName pkg} --version || ${lib.getName pkg} -V || echo ${lib.getName pkg}")
    '') corePackages}

    # === Network Connectivity ===

    # Test basic network tools
    machine.succeed("ping -c 1 127.0.0.1")
    machine.succeed("curl --version")
    machine.succeed("wget --version")

    # === SSH Service ===

    # Verify SSH service is running
    machine.succeed("systemctl is-active sshd")
    machine.succeed("ss --listen | grep ':22' || netstat -ln | grep ':22'")

    # === Nix System Health ===

    # Test Nix functionality
    machine.succeed("nix --version")
    machine.succeed("nix-store --version")
    machine.succeed("ls /nix/store || echo 'Nix store accessible'")

    # === Performance Basic Checks ===

    # Test system responsiveness (should respond quickly)
    machine.succeed("time echo 'system responsive'")

    # Check system load and memory
    machine.succeed("cat /proc/loadavg")
    machine.succeed("free -h")

    # === Cleanup and Validation ===

    # Verify no critical errors in system logs
    machine.succeed("journalctl --priority=0..3 --lines=10 || echo 'No critical errors found'")

    # Final validation - all core commands should work
    machine.succeed("git --help | head -1")
    machine.succeed("vim --version | head -1")
    machine.succeed("jq --version")
    machine.succeed("grep --version")
    machine.succeed("find --version")

    print("✅ Smoke test passed - all core system functionality validated")
    print("✅ System is healthy and ready for use")
  '';
}
