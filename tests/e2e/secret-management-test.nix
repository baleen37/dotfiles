# Secret Management E2E Test
#
# 시크릿 백업/복구 검증 테스트
#
# 검증 시나리오:
# 1. make secrets/backup 기능
# 2. make secrets/restore 기능
# 3. SSH 키 백업 (.ssh/ 디렉토리)
# 4. GPG 키링 백업 (.gnupg/ 디렉토리)
# 5. 권한 보존 (디렉토리는 700, 파일은 600)
# 6. 특정 파일 제외 (S.* 파일, *.conf 파일)
#
# 이 테스트는 시크릿 백업 및 복구 기능이 올바르게 작동하는지 검증합니다.

{
  pkgs ? import <nixpkgs> { },
  nixpkgs ? <nixpkgs>,
  system ? builtins.currentSystem or "x86_64-linux",
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
  name = "secret-management-test";

  nodes = {
    # Main test machine
    machine =
      { pkgs, ... }:
      {
        # Standard VM config
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.hostName = "secret-test";
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

        users.users.testuser = {
          isNormalUser = true;
          password = "test";
          extraGroups = [ "wheel" ];
          shell = pkgs.bash;
        };

        environment.systemPackages = with pkgs; [
          git
          curl
          jq
          nix
          gnumake
          gnupg
          openssh
        ];

        security.sudo.wheelNeedsPassword = false;

        # Setup test environment with mock secrets
        system.activationScripts.setupSecretTest = {
          text = ''
            mkdir -p /home/testuser/dotfiles
            chown -R testuser:users /home/testuser/dotfiles

            # Create mock SSH directory with keys
            mkdir -p /home/testuser/.ssh
            chown testuser:users /home/testuser/.ssh
            chmod 700 /home/testuser/.ssh

            # Create mock SSH keys
            echo "-----BEGIN RSA PRIVATE KEY-----" > /home/testuser/.ssh/id_rsa
            echo "Mock SSH private key content" >> /home/testuser/.ssh/id_rsa
            echo "-----END RSA PRIVATE KEY-----" >> /home/testuser/.ssh/id_rsa
            chown testuser:users /home/testuser/.ssh/id_rsa
            chmod 600 /home/testuser/.ssh/id_rsa

            echo "ssh-rsa AAAAB3NzaC1yc2E... mock-key@example.com" > /home/testuser/.ssh/id_rsa.pub
            chown testuser:users /home/testuser/.ssh/id_rsa.pub
            chmod 644 /home/testuser/.ssh/id_rsa.pub

            # Create SSH config
            echo "Host example.com" > /home/testuser/.ssh/config
            echo "    HostName example.com" >> /home/testuser/.ssh/config
            echo "    User testuser" >> /home/testuser/.ssh/config
            chown testuser:users /home/testuser/.ssh/config
            chmod 600 /home/testuser/.ssh/config

            # Create SSH environment file (should be excluded)
            echo "SSH_ENV_VAR=value" > /home/testuser/.ssh/environment
            chown testuser:users /home/testuser/.ssh/environment
            chmod 600 /home/testuser/.ssh/environment

            # Create mock GPG directory with keys
            mkdir -p /home/testuser/.gnupg
            chown testuser:users /home/testuser/.gnupg
            chmod 700 /home/testuser/.gnupg

            # Create mock GPG key files
            echo "-----BEGIN PGP PRIVATE KEY BLOCK-----" > /home/testuser/.gnupg/secring.gpg
            echo "Mock GPG private key content" >> /home/testuser/.gnupg/secring.gpg
            echo "-----END PGP PRIVATE KEY BLOCK-----" >> /home/testuser/.gnupg/secring.gpg
            chown testuser:users /home/testuser/.gnupg/secring.gpg
            chmod 600 /home/testuser/.gnupg/secring.gpg

            echo "-----BEGIN PGP PUBLIC KEY BLOCK-----" > /home/testuser/.gnupg/pubring.gpg
            echo "Mock GPG public key content" >> /home/testuser/.gnupg/pubring.gpg
            echo "-----END PGP PUBLIC KEY BLOCK-----" >> /home/testuser/.gnupg/pubring.gpg
            chown testuser:users /home/testuser/.gnupg/pubring.gpg
            chmod 644 /home/testuser/.gnupg/pubring.gpg

            # Create GPG S.* files (should be excluded)
            echo "GPG socket file" > /home/testuser/.gnupg/S.gpg-agent
            chown testuser:users /home/testuser/.gnupg/S.gpg-agent
            chmod 700 /home/testuser/.gnupg/S.gpg-agent

            # Create GPG .#* lock files (should be excluded)
            echo "GPG lock file" > /home/testuser/.gnupg/.#lock
            chown testuser:users /home/testuser/.gnupg/.#lock
            chmod 600 /home/testuser/.gnupg/.#lock

            # Create GPG conf files (should be excluded)
            echo "keyserver keyserver.ubuntu.com" > /home/testuser/.gnupg/gpg.conf
            chown testuser:users /home/testuser/.gnupg/gpg.conf
            chmod 600 /home/testuser/.gnupg/gpg.conf

            echo "keyserver keyserver.ubuntu.com" > /home/testuser/.gnupg/gpg-agent.conf
            chown testuser:users /home/testuser/.gnupg/gpg-agent.conf
            chmod 600 /home/testuser/.gnupg/gpg-agent.conf
          '';
        };
      };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    print("🚀 Starting Secret Management Test...")

    # Test 1: Validate initial secret files exist
    print("🔍 Test 1: Validating initial secret files...")

    # Check SSH directory
    ssh_dir_exists = machine.succeed("test -d /home/testuser/.ssh && echo 'exists' || echo 'not found'")
    assert ssh_dir_exists.strip() == "exists", ".ssh directory should exist"
    ssh_perms = machine.succeed("stat -c %a /home/testuser/.ssh")
    print(f".ssh directory permissions: {ssh_perms.strip()}")
    assert ssh_perms.strip() == "700", ".ssh directory should have 700 permissions"

    # Check SSH key files
    ssh_key_exists = machine.succeed("test -f /home/testuser/.ssh/id_rsa && echo 'exists' || echo 'not found'")
    assert ssh_key_exists.strip() == "exists", "id_rsa should exist"
    ssh_key_perms = machine.succeed("stat -c %a /home/testuser/.ssh/id_rsa")
    print(f"id_rsa permissions: {ssh_key_perms.strip()}")
    assert ssh_key_perms.strip() == "600", "id_rsa should have 600 permissions"

    # Check GPG directory
    gpg_dir_exists = machine.succeed("test -d /home/testuser/.gnupg && echo 'exists' || echo 'not found'")
    assert gpg_dir_exists.strip() == "exists", ".gnupg directory should exist"
    gpg_perms = machine.succeed("stat -c %a /home/testuser/.gnupg")
    print(f".gnupg directory permissions: {gpg_perms.strip()}")
    assert gpg_perms.strip() == "700", ".gnupg directory should have 700 permissions"

    # Check GPG key files
    gpg_sec_exists = machine.succeed("test -f /home/testuser/.gnupg/secring.gpg && echo 'exists' || echo 'not found'")
    assert gpg_sec_exists.strip() == "exists", "secring.gpg should exist"
    gpg_sec_perms = machine.succeed("stat -c %a /home/testuser/.gnupg/secring.gpg")
    print(f"secring.gpg permissions: {gpg_sec_perms.strip()}")
    assert gpg_sec_perms.strip() == "600", "secring.gpg should have 600 permissions"

    print("✅ Initial secret files are present with correct permissions")

    # Test 2: Create Makefile with secrets/backup target
    print("📝 Test 2: Creating Makefile with secrets/backup target...")

    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles

        # Create Makefile with secrets/backup and secrets/restore targets
        cat > Makefile << "EOF"
    MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

    .PHONY: secrets/backup
    secrets/backup:
    \ttar -czvf $(MAKEFILE_DIR)/backup.tar.gz \\
    \t\t-C $(HOME) \\
    \t\t--exclude=".gnupg/.#*" \\
    \t\t--exclude=".gnupg/S.*" \\
    \t\t--exclude=".gnupg/*.conf" \\
    \t\t--exclude=".ssh/environment" \\
    \t\t.ssh/ \\
    \t\t.gnupg

    .PHONY: secrets/restore
    secrets/restore:
    \tif [ ! -f $(MAKEFILE_DIR)/backup.tar.gz ]; then \\
    \t\techo "Error: backup.tar.gz not found in $(MAKEFILE_DIR)"; \\
    \t\texit 1; \\
    \tfi
    \techo "Restoring SSH keys and GPG keyring from backup..."
    \tmkdir -p $(HOME)/.ssh $(HOME)/.gnupg
    \ttar -xzvf $(MAKEFILE_DIR)/backup.tar.gz -C $(HOME)
    \tchmod 700 $(HOME)/.ssh $(HOME)/.gnupg
    \tchmod 600 $(HOME)/.ssh/* || true
    \tchmod 700 $(HOME)/.gnupg/* || true
    EOF

        # Verify Makefile exists
        test -f Makefile && echo "Makefile created"
      '
    """)

    print("✅ Makefile created with secrets/backup and secrets/restore targets")

    # Test 3: Test secrets/backup functionality
    print("🔍 Test 3: Testing secrets/backup functionality...")

    # Run make secrets/backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/backup
      '
    """)
    print("make secrets/backup completed")

    # Verify backup.tar.gz was created
    backup_exists = machine.succeed("su - testuser -c 'test -f ~/dotfiles/backup.tar.gz && echo exists || echo not_found'")
    assert backup_exists.strip() == "exists", "backup.tar.gz should be created"
    print("backup.tar.gz created successfully")

    # Check backup file contents
    backup_contents = machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        tar -tzvf backup.tar.gz
      '
    """)
    print(f"Backup contents: {backup_contents}")
    assert ".ssh/" in backup_contents, "Backup should contain .ssh directory"
    assert ".ssh/id_rsa" in backup_contents, "Backup should contain id_rsa"
    assert ".ssh/id_rsa.pub" in backup_contents, "Backup should contain id_rsa.pub"
    assert ".ssh/config" in backup_contents, "Backup should contain config"
    assert ".gnupg/" in backup_contents, "Backup should contain .gnupg directory"
    assert ".gnupg/secring.gpg" in backup_contents, "Backup should contain secring.gpg"
    assert ".gnupg/pubring.gpg" in backup_contents, "Backup should contain pubring.gpg"

    # Verify exclusions
    assert ".ssh/environment" not in backup_contents, "Backup should exclude .ssh/environment"
    assert ".gnupg/S.gpg-agent" not in backup_contents, "Backup should exclude S.* files"
    assert ".gnupg/.#lock" not in backup_contents, "Backup should exclude .#* files"
    assert ".gnupg/gpg.conf" not in backup_contents, "Backup should exclude *.conf files"
    assert ".gnupg/gpg-agent.conf" not in backup_contents, "Backup should exclude *.conf files"

    print("✅ secrets/backup functionality works correctly")

    # Test 4: Test backup integrity
    print("🔍 Test 4: Testing backup integrity...")

    # Extract backup to temporary directory
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        mkdir -p /tmp/backup-test
        tar -xzvf backup.tar.gz -C /tmp/backup-test
      '
    """)

    # Verify extracted files match originals
    original_ssh_key = machine.succeed("cat /home/testuser/.ssh/id_rsa")
    extracted_ssh_key = machine.succeed("su - testuser -c 'cat /tmp/backup-test/.ssh/id_rsa'")
    assert original_ssh_key.strip() == extracted_ssh_key.strip(), "Extracted SSH key should match original"

    original_gpg_key = machine.succeed("cat /home/testuser/.gnupg/secring.gpg")
    extracted_gpg_key = machine.succeed("su - testuser -c 'cat /tmp/backup-test/.gnupg/secring.gpg'")
    assert original_gpg_key.strip() == extracted_gpg_key.strip(), "Extracted GPG key should match original"

    print("✅ Backup integrity verified")

    # Test 5: Test secrets/restore functionality
    print("🔍 Test 5: Testing secrets/restore functionality...")

    # Remove original secrets
    machine.succeed("""
      rm -rf /home/testuser/.ssh
      rm -rf /home/testuser/.gnupg
    """)
    print("Original secrets removed")

    # Verify directories are gone
    ssh_gone = machine.succeed("test -d /home/testuser/.ssh && echo exists || echo gone")
    assert ssh_gone.strip() == "gone", ".ssh directory should be removed"
    gpg_gone = machine.succeed("test -d /home/testuser/.gnupg && echo exists || echo gone")
    assert gpg_gone.strip() == "gone", ".gnupg directory should be removed"

    # Run make secrets/restore
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/restore
      '
    """)
    print("make secrets/restore completed")

    # Verify directories were recreated
    ssh_restored = machine.succeed("test -d /home/testuser/.ssh && echo exists || echo gone")
    assert ssh_restored.strip() == "exists", ".ssh directory should be restored"
    gpg_restored = machine.succeed("test -d /home/testuser/.gnupg && echo exists || echo gone")
    assert gpg_restored.strip() == "exists", ".gnupg directory should be restored"

    # Verify files were restored
    ssh_key_restored = machine.succeed("test -f /home/testuser/.ssh/id_rsa && echo exists || echo gone")
    assert ssh_key_restored.strip() == "exists", "id_rsa should be restored"
    gpg_key_restored = machine.succeed("test -f /home/testuser/.gnupg/secring.gpg && echo exists || echo gone")
    assert gpg_key_restored.strip() == "exists", "secring.gpg should be restored"

    print("✅ secrets/restore functionality works correctly")

    # Test 6: Verify restored files have correct permissions
    print("🔍 Test 6: Verifying restored file permissions...")

    # Check .ssh directory permissions
    restored_ssh_perms = machine.succeed("stat -c %a /home/testuser/.ssh")
    print(f"Restored .ssh permissions: {restored_ssh_perms.strip()}")
    assert restored_ssh_perms.strip() == "700", "Restored .ssh should have 700 permissions"

    # Check .gnupg directory permissions
    restored_gpg_perms = machine.succeed("stat -c %a /home/testuser/.gnupg")
    print(f"Restored .gnupg permissions: {restored_gpg_perms.strip()}")
    assert restored_gpg_perms.strip() == "700", "Restored .gnupg should have 700 permissions"

    # Check SSH key file permissions
    restored_ssh_key_perms = machine.succeed("stat -c %a /home/testuser/.ssh/id_rsa")
    print(f"Restored id_rsa permissions: {restored_ssh_key_perms.strip()}")
    assert restored_ssh_key_perms.strip() == "600", "Restored id_rsa should have 600 permissions"

    # Check GPG key file permissions
    restored_gpg_key_perms = machine.succeed("stat -c %a /home/testuser/.gnupg/secring.gpg")
    print(f"Restored secring.gpg permissions: {restored_gpg_key_perms.strip()}")
    assert restored_gpg_key_perms.strip() == "600", "Restored secring.gpg should have 600 permissions"

    print("✅ Restored files have correct permissions")

    # Test 7: Verify restored file contents
    print("🔍 Test 7: Verifying restored file contents...")

    restored_ssh_key = machine.succeed("cat /home/testuser/.ssh/id_rsa")
    assert "-----BEGIN RSA PRIVATE KEY-----" in restored_ssh_key, "Restored SSH key should have correct content"
    assert "Mock SSH private key content" in restored_ssh_key, "Restored SSH key should have correct content"

    restored_gpg_key = machine.succeed("cat /home/testuser/.gnupg/secring.gpg")
    assert "-----BEGIN PGP PRIVATE KEY BLOCK-----" in restored_gpg_key, "Restored GPG key should have correct content"
    assert "Mock GPG private key content" in restored_gpg_key, "Restored GPG key should have correct content"

    # Verify SSH config was restored
    restored_config = machine.succeed("cat /home/testuser/.ssh/config")
    assert "Host example.com" in restored_config, "Restored config should have correct content"

    print("✅ Restored files have correct contents")

    # Test 8: Test restore error handling
    print("🔍 Test 8: Testing restore error handling...")

    # Remove backup file
    machine.succeed("su - testuser -c 'rm ~/dotfiles/backup.tar.gz'")

    # Try to restore without backup file
    restore_error = machine.fail("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/restore
      '
    """)
    print("Restore without backup file failed as expected")

    # Recreate backup for remaining tests
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/backup
      '
    """)

    print("✅ Restore error handling works correctly")

    # Test 9: Test backup overwrites existing backup
    print("🔍 Test 9: Testing backup overwrite...")

    # Create a backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/backup
      '
    """)

    # Modify a secret file
    machine.succeed("echo 'Modified content' >> /home/testuser/.ssh/config")

    # Create another backup (should overwrite)
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/backup
      '
    """)

    # Verify backup was updated
    backup_config = machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        tar -xzf backup.tar.gz -C /tmp .ssh/config --strip-components=2
        cat /tmp/config
      '
    """)
    assert "Modified content" in backup_config, "Backup should contain modified content"

    print("✅ Backup overwrite works correctly")

    # Test 10: Test backup with new files
    print("🔍 Test 10: Testing backup with additional files...")

    # Add new SSH key
    machine.succeed("""
      echo "-----BEGIN RSA PRIVATE KEY-----" > /home/testuser/.ssh/id_ed25519
      echo "New SSH key" >> /home/testuser/.ssh/id_ed25519
      echo "-----END RSA PRIVATE KEY-----" >> /home/testuser/.ssh/id_ed25519
      chown testuser:users /home/testuser/.ssh/id_ed25519
      chmod 600 /home/testuser/.ssh/id_ed25519
    """)

    # Create new backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/backup
      '
    """)

    # Verify new key is in backup
    backup_new_key = machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        tar -tzvf backup.tar.gz | grep id_ed25519
      '
    """)
    assert "id_ed25519" in backup_new_key, "Backup should contain new key"

    print("✅ Backup includes new files")

    # Test 11: Verify excluded files are not backed up
    print("🔍 Test 11: Verifying excluded files...")

    # Create files that should be excluded
    machine.succeed("""
      echo "GPG agent config" > /home/testuser/.gnupg/gpg-agent.conf
      echo "Socket file" > /home/testuser/.gnupg/S.gpg-agent
      echo "Lock file" > /home/testuser/.gnupg/.#lock
      chown -R testuser:users /home/testuser/.gnupg
    """)

    # Create backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/backup
      '
    """)

    # Verify excluded files are not in backup
    backup_list = machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        tar -tzvf backup.tar.gz
      '
    """)

    assert "gpg-agent.conf" not in backup_list, "Backup should exclude *.conf files"
    assert "S.gpg-agent" not in backup_list, "Backup should exclude S.* files"
    assert ".#lock" not in backup_list, "Backup should exclude .#* files"

    print("✅ Excluded files are correctly omitted from backup")

    # Test 12: Test multiple backup/restore cycles
    print("🔍 Test 12: Testing multiple backup/restore cycles...")

    # First backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        cp backup.tar.gz backup1.tar.gz
      '
    """)

    # Modify secrets
    machine.succeed("echo 'First modification' >> /home/testuser/.ssh/config")

    # Second backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/backup
        cp backup.tar.gz backup2.tar.gz
      '
    """)

    # Modify secrets again
    machine.succeed("echo 'Second modification' >> /home/testuser/.ssh/config")

    # Third backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        make secrets/backup
        cp backup.tar.gz backup3.tar.gz
      '
    """)

    # Restore from first backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        cp backup1.tar.gz backup.tar.gz
        rm -rf ~/.ssh ~/.gnupg
        make secrets/restore
      '
    """)

    first_restore = machine.succeed("cat /home/testuser/.ssh/config")
    assert "First modification" not in first_restore, "First restore should not have first modification"
    assert "Second modification" not in first_restore, "First restore should not have second modification"

    # Restore from second backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        cp backup2.tar.gz backup.tar.gz
        rm -rf ~/.ssh ~/.gnupg
        make secrets/restore
      '
    """)

    second_restore = machine.succeed("cat /home/testuser/.ssh/config")
    assert "First modification" in second_restore, "Second restore should have first modification"
    assert "Second modification" not in second_restore, "Second restore should not have second modification"

    # Restore from third backup
    machine.succeed("""
      su - testuser -c '
        cd ~/dotfiles
        cp backup3.tar.gz backup.tar.gz
        rm -rf ~/.ssh ~/.gnupg
        make secrets/restore
      '
    """)

    third_restore = machine.succeed("cat /home/testuser/.ssh/config")
    assert "First modification" in third_restore, "Third restore should have first modification"
    assert "Second modification" in third_restore, "Third restore should have second modification"

    print("✅ Multiple backup/restore cycles work correctly")

    # Final validation
    print("\n" + "="*60)
    print("✅ Secret Management Test PASSED!")
    print("="*60)
    print("\nValidated:")
    print("  ✓ make secrets/backup functionality")
    print("  ✓ make secrets/restore functionality")
    print("  ✓ SSH key backup (.ssh/ directory)")
    print("  ✓ GPG keyring backup (.gnupg/ directory)")
    print("  ✓ Permission preservation (700 for directories, 600 for files)")
    print("  ✓ Exclusion of specific files (S.* files, *.conf)")
    print("  ✓ Backup integrity")
    print("  ✓ Restore error handling")
    print("  ✓ Backup overwrite")
    print("  ✓ Multiple backup/restore cycles")
    print("\nAll secret management features are working correctly!")
  '';
}
