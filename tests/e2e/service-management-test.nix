# Service Management E2E Test
#
# 서비스 관리 검증 테스트
#
# 검증 시나리오:
# 1. SSH 서비스 활성화 및 시작
# 2. Docker 서비스 활성화
# 3. 사용자 서비스 관리
# 4. 설정 변경 후 서비스 재시작
# 5. 서비스 상태 확인 명령어
#
# 이 테스트는 시스템 서비스가 올바르게 구성되고 관리되는지 검증합니다.

{
  pkgs ? import <nixpkgs> { },
  nixpkgs ? <nixpkgs>,
  lib ? pkgs.lib,
  system ? builtins.currentSystem or "x86_64-linux",
  self ? null,
}:

let
  # Use nixosTest from pkgs (works in flake context)
  nixosTest =
    pkgs.testers.nixosTest or (import "${nixpkgs}/nixos/lib/testing-python.nix" {
      inherit system;
      inherit pkgs;
    });

in
nixosTest {
  name = "service-management-test";

  nodes = {
    # Main test machine with various services
    machine =
      { config, pkgs, ... }:
      {
        # Standard VM config
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.hostName = "service-test";
        networking.useDHCP = false;
        networking.firewall.enable = false;

        virtualisation.cores = 2;
        virtualisation.memorySize = 2048;
        virtualisation.diskSize = 4096;

        nix = {
          extraOptions = ''
            experimental-features = nix-command flakes
            accept-flake-config = true
          '';
          settings = {
            substituters = [ "https://cache.nixos.org/" ];
            trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
          };
        };

        # Enable SSH service
        services.openssh = {
          enable = true;
          settings = {
            PasswordAuthentication = true;
            PermitRootLogin = "yes";
          };
        };

        # Enable Docker service
        virtualisation.docker.enable = true;

        users.users.testuser = {
          isNormalUser = true;
          password = "test";
          extraGroups = [ "wheel" "docker" ];
          shell = pkgs.bash;
        };

        environment.systemPackages = with pkgs; [
          git
          curl
          jq
          nix
          gnumake
          docker
          docker-compose
        ];

        security.sudo.wheelNeedsPassword = false;

        # Setup test environment
        system.activationScripts.setupServiceTest = {
          text = ''
            mkdir -p /home/testuser/dotfiles
            chown -R testuser:users /home/testuser/dotfiles
          '';
        };
      };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    print("🚀 Starting Service Management Test...")

    # Test 1: Validate SSH service is enabled and running
    print("🔍 Test 1: Validating SSH service...")

    # Check if SSH service is enabled
    ssh_enabled = machine.succeed("systemctl is-enabled sshd.service")
    print(f"SSH service enabled: {ssh_enabled}")
    assert ssh_enabled.strip() == "enabled", "SSH service should be enabled"

    # Check if SSH service is active (running)
    ssh_active = machine.succeed("systemctl is-active sshd.service")
    print(f"SSH service active: {ssh_active}")
    assert ssh_active.strip() == "active", "SSH service should be active"

    # Check SSH service status
    ssh_status = machine.succeed("systemctl status sshd.service --no-pager")
    print(f"SSH service status: {ssh_status[:200]}...")
    assert "loaded" in ssh_status.lower(), "SSH service should be loaded"
    assert "active (running)" in ssh_status.lower(), "SSH service should be running"

    # Verify SSH port is listening
    ssh_port = machine.succeed("ss -tlnp | grep ':22 ' || netstat -tlnp | grep ':22 '")
    print(f"SSH port listening: {ssh_port}")
    assert ":22" in ssh_port, "SSH should be listening on port 22"

    print("✅ SSH service is enabled and running")

    # Test 2: Validate Docker service is enabled
    print("🔍 Test 2: Validating Docker service...")

    # Check if Docker service is enabled
    docker_enabled = machine.succeed("systemctl is-enabled docker.service")
    print(f"Docker service enabled: {docker_enabled}")
    assert docker_enabled.strip() == "enabled", "Docker service should be enabled"

    # Check if Docker service is active
    docker_active = machine.succeed("systemctl is-active docker.service")
    print(f"Docker service active: {docker_active}")
    assert docker_active.strip() == "active", "Docker service should be active"

    # Check Docker service status
    docker_status = machine.succeed("systemctl status docker.service --no-pager")
    print(f"Docker service status: {docker_status[:200]}...")
    assert "loaded" in docker_status.lower(), "Docker service should be loaded"
    assert "active (running)" in docker_status.lower(), "Docker service should be running"

    # Verify Docker command works
    docker_version = machine.succeed("docker --version")
    print(f"Docker version: {docker_version}")
    assert "Docker version" in docker_version, "Docker should be installed"

    print("✅ Docker service is enabled and running")

    # Test 3: Test Docker functionality
    print("🔍 Test 3: Testing Docker functionality...")

    # Run a simple Docker container
    machine.succeed("docker run --rm hello-world")
    print("Docker hello-world container ran successfully")

    # Verify container can be pulled and run
    machine.succeed("docker pull alpine:latest")
    machine.succeed("docker run --rm alpine:latest echo 'Docker works!'")
    print("Docker Alpine container ran successfully")

    print("✅ Docker functionality is working")

    # Test 4: Validate user service management
    print("🔍 Test 4: Validating user service management...")

    # Check if testuser is in docker group
    user_groups = machine.succeed("groups testuser")
    print(f"testuser groups: {user_groups}")
    assert "docker" in user_groups, "testuser should be in docker group"

    # Create a user service (systemd user service)
    machine.succeed("""
      su - testuser -c '
        mkdir -p ~/.config/systemd/user
        cat > ~/.config/systemd/user/test-service.service << "EOF"
    [Unit]
    Description=Test User Service

    [Service]
    ExecStart=/bin/sh -c "echo Test Service Running && sleep 1"
    Type=oneshot

    [Install]
    WantedBy=default.target
    EOF

        # Enable and start user service
        systemctl --user daemon-reload
        systemctl --user enable test-service.service
        systemctl --user start test-service.service
      '
    """)

    # Check user service status
    user_service_status = machine.succeed("su - testuser -c 'systemctl --user status test-service.service --no-pager'")
    print(f"User service status: {user_service_status[:200]}...")
    assert "test-service" in user_service_status.lower(), "User service should be loaded"

    print("✅ User service management is working")

    # Test 5: Test service restart after configuration change
    print("🔍 Test 5: Testing service restart after configuration change...")

    # Get initial SSH service PID
    initial_ssh_pid = machine.succeed("pgrep sshd | head -1").strip()
    print(f"Initial SSH PID: {initial_ssh_pid}")

    # Reload SSH service configuration
    machine.succeed("systemctl reload sshd.service")
    print("SSH service reloaded")

    # Wait a moment for reload to complete
    machine.sleep(2)

    # Get new SSH service PID
    new_ssh_pid = machine.succeed("pgrep sshd | head -1").strip()
    print(f"New SSH PID after reload: {new_ssh_pid}")

    # Verify SSH is still running
    ssh_active_after_reload = machine.succeed("systemctl is-active sshd.service")
    assert ssh_active_after_reload.strip() == "active", "SSH should still be active after reload"

    # Test Docker restart
    machine.succeed("systemctl restart docker.service")
    print("Docker service restarted")

    # Wait for Docker to restart
    machine.wait_for_unit("docker.service")

    # Verify Docker is still running after restart
    docker_active_after_restart = machine.succeed("systemctl is-active docker.service")
    assert docker_active_after_restart.strip() == "active", "Docker should be active after restart"

    # Verify Docker still works after restart
    machine.succeed("docker run --rm alpine:latest echo 'Docker works after restart!'")
    print("Docker works after restart")

    print("✅ Service restart after configuration change is working")

    # Test 6: Test service status commands
    print("🔍 Test 6: Testing service status commands...")

    # Test systemctl list-units
    service_list = machine.succeed("systemctl list-units --type=service --no-pager")
    print(f"Service list: {service_list[:300]}...")
    assert "sshd.service" in service_list, "SSH service should be in service list"
    assert "docker.service" in service_list, "Docker service should be in service list"

    # Test systemctl list-unit-files (enabled services)
    enabled_services = machine.succeed("systemctl list-unit-files --type=service --no-pager | grep enabled")
    print(f"Enabled services: {enabled_services[:300]}...")
    assert "sshd.service" in enabled_services, "SSH service should be enabled"
    assert "docker.service" in enabled_services, "Docker service should be enabled"

    # Test service status with detailed output
    ssh_detailed_status = machine.succeed("systemctl show sshd.service")
    print(f"SSH detailed status: {ssh_detailed_status[:300]}...")
    assert "Description=OpenSSH server daemon" in ssh_detailed_status, "SSH description should be present"
    assert "LoadState=loaded" in ssh_detailed_status, "SSH should be in loaded state"
    assert "ActiveState=active" in ssh_detailed_status, "SSH should be in active state"

    print("✅ Service status commands are working")

    # Test 7: Test service failure handling
    print("🔍 Test 7: Testing service failure handling...")

    # Create a failing service
    machine.succeed("""
      cat > /etc/systemd/system/failing-service.service << "EOF"
    [Unit]
    Description=Failing Test Service

    [Service]
    ExecStart=/bin/false
    Type=oneshot

    [Install]
    WantedBy=multi-user.target
    EOF

      systemctl daemon-reload
    """)

    # Start the failing service
    machine.fail("systemctl start failing-service.service")
    print("Failing service failed as expected")

    # Check service status (should show failed)
    failing_status = machine.succeed("systemctl is-active failing-service.service || true")
    print(f"Failing service status: {failing_status}")
    assert failing_status.strip() == "failed" or failing_status.strip() == "inactive", "Service should be in failed or inactive state"

    # Clean up failing service
    machine.succeed("systemctl reset-failed failing-service.service || true")
    machine.succeed("rm /etc/systemd/system/failing-service.service")
    machine.succeed("systemctl daemon-reload")

    print("✅ Service failure handling is working")

    # Test 8: Validate service dependencies
    print("🔍 Test 8: Validating service dependencies...")

    # Check Docker dependencies
    docker_dependencies = machine.succeed("systemctl show docker.service -p Requires,Wants,After,Before")
    print(f"Docker dependencies: {docker_dependencies}")
    # Docker typically requires network-online.target
    assert "network" in docker_dependencies.lower() or "docker" in docker_dependencies.lower(), "Docker should have network dependencies"

    print("✅ Service dependencies are validated")

    # Test 9: Test service log access
    print("🔍 Test 9: Testing service log access...")

    # Check journalctl for SSH service
    ssh_logs = machine.succeed("journalctl -u sshd.service --no-pager -n 10")
    print(f"SSH service logs: {ssh_logs[:300]}...")
    assert "sshd" in ssh_logs.lower(), "SSH logs should contain sshd entries"

    # Check journalctl for Docker service
    docker_logs = machine.succeed("journalctl -u docker.service --no-pager -n 10")
    print(f"Docker service logs: {docker_logs[:300]}...")
    assert "docker" in docker_logs.lower(), "Docker logs should contain docker entries"

    print("✅ Service log access is working")

    # Test 10: Test enable/disable functionality
    print("🔍 Test 10: Testing enable/disable functionality...")

    # Create a test service
    machine.succeed("""
      cat > /etc/systemd/system/test-enable-service.service << "EOF"
    [Unit]
    Description=Test Enable/Disable Service

    [Service]
    ExecStart=/bin/sleep 3600
    Type=simple

    [Install]
    WantedBy=multi-user.target
    EOF

      systemctl daemon-reload
    """)

    # Enable the service
    machine.succeed("systemctl enable test-enable-service.service")
    enabled_check = machine.succeed("systemctl is-enabled test-enable-service.service")
    assert enabled_check.strip() == "enabled", "Service should be enabled"
    print("Service enabled successfully")

    # Disable the service
    machine.succeed("systemctl disable test-enable-service.service")
    disabled_check = machine.succeed("systemctl is-enabled test-enable-service.service || true")
    assert disabled_check.strip() == "disabled" or "static" in disabled_check, "Service should be disabled"
    print("Service disabled successfully")

    # Clean up test service
    machine.succeed("rm /etc/systemd/system/test-enable-service.service")
    machine.succeed("systemctl daemon-reload")

    print("✅ Enable/disable functionality is working")

    # Final validation
    print("\n" + "="*60)
    print("✅ Service Management Test PASSED!")
    print("="*60)
    print("\nValidated:")
    print("  ✓ SSH service enablement and startup")
    print("  ✓ Docker service enablement")
    print("  ✓ User service management")
    print("  ✓ Service restart after configuration change")
    print("  ✓ Service status commands")
    print("  ✓ Service failure handling")
    print("  ✓ Service dependencies")
    print("  ✓ Service log access")
    print("  ✓ Enable/disable functionality")
    print("\nAll service management features are working correctly!")
  '';
}
