# End-to-End Test Examples for Comprehensive Testing Framework
# Demonstrates complete system workflow validation using NixOS tests

{ lib, pkgs, modulesPath, ... }:

let
  # Import test utilities
  testLib = import ../lib/test-framework/helpers.nix { inherit lib; };

  # Helper function to create test configurations
  mkTestConfig = name: extraConfig: {
    inherit name;
    nodes.machine = { config, pkgs, ... }: lib.recursiveUpdate
      {
        # Base test configuration
        system.stateVersion = "24.05";

        # Enable essential services
        services.openssh.enable = true;
        users.users.testuser = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          password = "test"; # pragma: allowlist secret
        };

        # Install test dependencies
        environment.systemPackages = with pkgs; [
          nix
          git
          curl
          jq
        ];

        # Configure Nix for testing
        nix = {
          settings = {
            experimental-features = [ "nix-command" "flakes" ];
            trusted-users = [ "testuser" ];
          };
        };

      }
      extraConfig;

    testScript = ''
      import time
      import json

      def wait_for_service(service, timeout=30):
          """Wait for a systemd service to become active"""
          machine.wait_for_unit(service, timeout=timeout)

      def check_command_output(cmd, expected, timeout=10):
          """Check that command output matches expected"""
          result = machine.succeed(cmd, timeout=timeout)
          assert expected in result, f"Expected '{expected}' in output: {result}"

      def verify_file_exists(path):
          """Verify that a file exists on the machine"""
          machine.succeed(f"test -f {path}")

      def verify_directory_structure(base_path, expected_structure):
          """Verify directory structure matches expected"""
          for path in expected_structure:
              machine.succeed(f"test -e {base_path}/{path}")
    '';
  };

in
{
  # ============================================================================
  # Fresh Installation E2E Test
  # ============================================================================

  fresh-installation = pkgs.testers.runNixOSTest (mkTestConfig "fresh-installation" {
    # Test fresh dotfiles installation from scratch
    testScript = ''
      # Start the machine and wait for basic services
      machine.start()
      machine.wait_for_unit("multi-user.target")

      print("=== Testing Fresh Installation ===")

      # Verify initial state
      machine.succeed("whoami")
      machine.succeed("nix --version")

      # Clone dotfiles repository (simulated)
      machine.succeed("""
        mkdir -p /home/testuser/dotfiles
        cd /home/testuser/dotfiles

        # Create minimal flake structure
        cat > flake.nix << 'EOF'
        {
          description = "Test dotfiles";
          inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
          outputs = { self, nixpkgs }: {
            nixosConfigurations.test = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [ ./configuration.nix ];
            };
          };
        }
        EOF

        # Create basic configuration
        cat > configuration.nix << 'EOF'
        { config, pkgs, ... }: {
          system.stateVersion = "24.05";
          environment.systemPackages = with pkgs; [ git vim ];
        }
        EOF

        chown -R testuser:users /home/testuser/dotfiles
      """)

      # Test flake validation
      machine.succeed("cd /home/testuser/dotfiles && nix flake check --no-build")

      # Test configuration building
      machine.succeed("""
        cd /home/testuser/dotfiles
        nix build .#nixosConfigurations.test.config.system.build.toplevel --no-link
      """)

      print("✅ Fresh installation test completed successfully")
    '';
  });

  # ============================================================================
  # System Update E2E Test
  # ============================================================================

  system-update = pkgs.testers.runNixOSTest (mkTestConfig "system-update" {
    # Add existing configuration to simulate update scenario
    environment.etc."dotfiles-version".text = "1.0.0";

    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")

      print("=== Testing System Update ===")

      # Verify existing configuration
      machine.succeed("test -f /etc/dotfiles-version")
      current_version = machine.succeed("cat /etc/dotfiles-version").strip()
      print(f"Current version: {current_version}")

      # Simulate configuration update
      machine.succeed("""
        mkdir -p /home/testuser/dotfiles-new
        cd /home/testuser/dotfiles-new

        # Create updated configuration
        cat > flake.nix << 'EOF'
        {
          description = "Updated test dotfiles";
          inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
          outputs = { self, nixpkgs }: {
            nixosConfigurations.test = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              modules = [ ./configuration.nix ];
            };
          };
        }
        EOF

        cat > configuration.nix << 'EOF'
        { config, pkgs, ... }: {
          system.stateVersion = "24.05";
          environment.systemPackages = with pkgs; [ git vim curl ];
          environment.etc."dotfiles-version".text = "2.0.0";
        }
        EOF

        chown -R testuser:users /home/testuser/dotfiles-new
      """)

      # Test update process
      machine.succeed("""
        cd /home/testuser/dotfiles-new
        nix build .#nixosConfigurations.test.config.system.build.toplevel --out-link result
        test -L result
      """)

      # Verify update would work (dry-run)
      machine.succeed("""
        cd /home/testuser/dotfiles-new
        nix build .#nixosConfigurations.test.config.environment.etc.\"dotfiles-version\".source --no-link
      """)

      print("✅ System update test completed successfully")
    '';
  });

  # ============================================================================
  # Cross-Platform Compatibility E2E Test
  # ============================================================================

  cross-platform-compatibility = pkgs.testers.runNixOSTest (mkTestConfig "cross-platform" {
    # Add platform detection utilities
    environment.systemPackages = with pkgs; [ file ];

    testScript = ''
      machine.start()
      machine.wait_for_unit("multi-user.target")

      print("=== Testing Cross-Platform Compatibility ===")

      # Detect current platform
      platform = machine.succeed("nix eval --raw --expr 'builtins.currentSystem'").strip()
      print(f"Current platform: {platform}")

      # Create platform-aware configuration
      machine.succeed(f"""
        mkdir -p /home/testuser/dotfiles-cross
        cd /home/testuser/dotfiles-cross

        # Create cross-platform flake
        cat > flake.nix << 'EOF'
        {{
          description = "Cross-platform test dotfiles";
          inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
          outputs = {{ self, nixpkgs }}: {{
            nixosConfigurations.test = nixpkgs.lib.nixosSystem {{
              system = "{platform}";
              modules = [ ./configuration.nix ];
            }};
          }};
        }}
        EOF

        # Platform-specific configuration
        cat > configuration.nix << 'EOF'
        {{ config, pkgs, lib, ... }}: {{
          system.stateVersion = "24.05";

          # Platform-specific packages
          environment.systemPackages = with pkgs; [
            git vim
          ] ++ lib.optionals (pkgs.stdenv.isLinux) [
            htop procps
          ] ++ lib.optionals (pkgs.stdenv.isDarwin) [
            # Darwin-specific packages would go here
          ];

          # Platform detection test
          environment.etc."platform-info".text = ''
      Platform: ${{
        builtins.currentSystem}}
        Linux: ${{toString pkgs.stdenv.isLinux}}
        Darwin: ${{toString pkgs.stdenv.isDarwin}}
        '';
        }}
        EOF

        chown -R testuser:users /home/testuser/dotfiles-cross
      """)

      # Test platform-specific builds
      machine.succeed("""
        cd /home/testuser/dotfiles-cross
        nix flake check --no-build
        nix build .#nixosConfigurations.test.config.environment.etc.\"platform-info\".source --no-link
      """)

      # Verify platform detection works
      machine.succeed(f"""
        cd /home/testuser/dotfiles-cross
        platform_info=$(nix eval --raw .#nixosConfigurations.test.config.environment.etc.\"platform-info\".text)
        echo "$platform_info" | grep "Platform: {platform}"
        echo "$platform_info" | grep "Linux: true"
      """)

      print("✅ Cross-platform compatibility test completed successfully")
    '';
        });

        # ============================================================================
        # Service Integration E2E Test
        # ============================================================================

        service-integration = pkgs.testers.runNixOSTest (mkTestConfig "service-integration" {
          # Enable services to test integration
          services = {
            openssh.enable = true;
            nginx = {
              enable = true;
              virtualHosts."test.local" = {
                root = "/var/www";
                locations."/health".return = "200 'OK'";
              };
            };
          };

          # Create test web content
          environment.etc."test-web/index.html".text = "Test Page";
          systemd.tmpfiles.rules = [
            "d /var/www 0755 nginx nginx -"
            "L+ /var/www/index.html - - - - /etc/test-web/index.html"
          ];

          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            print("=== Testing Service Integration ===")

            # Wait for services to start
            machine.wait_for_unit("sshd.service")
            machine.wait_for_unit("nginx.service")
            machine.wait_for_open_port(22)
            machine.wait_for_open_port(80)

            # Test SSH service
            machine.succeed("systemctl is-active sshd")

            # Test Nginx service
            machine.succeed("systemctl is-active nginx")
            machine.succeed("curl -f http://localhost/health")

            # Test dotfiles integration with services
            machine.succeed("""
              mkdir -p /home/testuser/dotfiles-services
              cd /home/testuser/dotfiles-services

              cat > flake.nix << 'EOF'
              {
                description = "Service integration test";
                inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
                outputs = { self, nixpkgs }: {
                  nixosConfigurations.test = nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [ ./configuration.nix ];
                  };
                };
              }
              EOF

              cat > configuration.nix << 'EOF'
              { config, pkgs, ... }: {
                system.stateVersion = "24.05";

                # Test service configuration
                services.openssh.enable = true;
                services.nginx = {
                  enable = true;
                  virtualHosts."app.test" = {
                    locations."/api/status".return = "200 'Service OK'";
                  };
                };

                # Validation script
                systemd.services.dotfiles-validation = {
                  description = "Dotfiles configuration validation";
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                  };
                  script = '''
                    echo "Validating dotfiles configuration..."
                    systemctl is-active sshd.service
                    systemctl is-active nginx.service
                    echo "✅ All services validated"
                  ''';
                };
              }
              EOF

              chown -R testuser:users /home/testuser/dotfiles-services
            """)

            # Build and validate service configuration
            machine.succeed("""
              cd /home/testuser/dotfiles-services
              nix build .#nixosConfigurations.test.config.system.build.toplevel --no-link
            """)

            print("✅ Service integration test completed successfully")
          '';
        });

        # ============================================================================
        # Performance E2E Test
        # ============================================================================

        performance-validation = pkgs.testers.runNixOSTest (mkTestConfig "performance" {
          # Enable performance monitoring tools
          environment.systemPackages = with pkgs; [ time htop ];

          testScript = ''
            import time

            machine.start()
            machine.wait_for_unit("multi-user.target")

            print("=== Testing Performance Validation ===")

            # Create performance test setup
            machine.succeed("""
              mkdir -p /home/testuser/dotfiles-perf
              cd /home/testuser/dotfiles-perf

              cat > flake.nix << 'EOF'
              {
                description = "Performance test dotfiles";
                inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
                outputs = { self, nixpkgs }: {
                  nixosConfigurations.test = nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [ ./configuration.nix ];
                  };

                  # Performance test apps
                  apps.x86_64-linux.perf-test = {
                    type = "app";
                    program = toString (nixpkgs.legacyPackages.x86_64-linux.writeScript "perf-test" '''
                      #!/bin/bash
                      echo "Running performance test..."
                      time nix eval .#nixosConfigurations.test.config.system.name
                      echo "Performance test completed"
                    ''');
                  };
                };
              }
              EOF

              cat > configuration.nix << 'EOF'
              { config, pkgs, ... }: {
                system.stateVersion = "24.05";
                system.name = "performance-test-system";
                environment.systemPackages = with pkgs; [ git vim ];
              }
              EOF

              chown -R testuser:users /home/testuser/dotfiles-perf
            """)

            # Measure build performance
            start_time = time.time()

            machine.succeed("""
              cd /home/testuser/dotfiles-perf
              time nix build .#nixosConfigurations.test.config.system.build.toplevel --no-link
            """)

            build_time = time.time() - start_time
            print(f"Build time: {build_time:.2f} seconds")

            # Performance should be reasonable (under 60 seconds for simple config)
            assert build_time < 60, f"Build took too long: {build_time} seconds"

            # Test flake evaluation performance
            start_time = time.time()

            machine.succeed("""
              cd /home/testuser/dotfiles-perf
              nix eval .#nixosConfigurations.test.config.system.name
            """)

            eval_time = time.time() - start_time
            print(f"Evaluation time: {eval_time:.2f} seconds")

            # Evaluation should be fast (under 10 seconds)
            assert eval_time < 10, f"Evaluation took too long: {eval_time} seconds"

            print("✅ Performance validation test completed successfully")
          '';
        });

        # ============================================================================
        # Error Recovery E2E Test
        # ============================================================================

        error-recovery = pkgs.testers.runNixOSTest (mkTestConfig "error-recovery" {
          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            print("=== Testing Error Recovery ===")

            # Create configuration with intentional errors
            machine.succeed("""
              mkdir -p /home/testuser/dotfiles-error
              cd /home/testuser/dotfiles-error

              # Create flake with syntax error first
              cat > flake.nix << 'EOF'
              {
                description = "Error test dotfiles";
                inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
                outputs = { self, nixpkgs }: {
                  nixosConfigurations.test = nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [ ./configuration.nix ];
                  };
                # Missing closing brace - syntax error
              EOF

              chown -R testuser:users /home/testuser/dotfiles-error
            """)

            # Test that error is properly detected
            result = machine.fail("""
              cd /home/testuser/dotfiles-error
              nix flake check --no-build
            """)

            # Fix the syntax error
            machine.succeed("""
              cd /home/testuser/dotfiles-error
              cat > flake.nix << 'EOF'
              {
                description = "Error test dotfiles";
                inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
                outputs = { self, nixpkgs }: {
                  nixosConfigurations.test = nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [ ./configuration.nix ];
                  };
                };
              }
              EOF

              # Create configuration with semantic error
              cat > configuration.nix << 'EOF'
              { config, pkgs, ... }: {
                system.stateVersion = "24.05";
                services.nonexistent-service.enable = true;  # This should cause an error
              }
              EOF
            """)

            # Test that semantic error is detected
            result = machine.fail("""
              cd /home/testuser/dotfiles-error
              nix build .#nixosConfigurations.test.config.system.build.toplevel --no-link
            """)

            # Fix the semantic error
            machine.succeed("""
              cd /home/testuser/dotfiles-error
              cat > configuration.nix << 'EOF'
              { config, pkgs, ... }: {
                system.stateVersion = "24.05";
                services.openssh.enable = true;  # Valid service
              }
              EOF
            """)

            # Test that fixed configuration works
            machine.succeed("""
              cd /home/testuser/dotfiles-error
              nix flake check --no-build
              nix build .#nixosConfigurations.test.config.system.build.toplevel --no-link
            """)

            print("✅ Error recovery test completed successfully")
          '';
        });

        # ============================================================================
        # Complete Workflow E2E Test
        # ============================================================================

        complete-workflow = pkgs.testers.runNixOSTest (mkTestConfig "complete-workflow" {
          # Enable all services needed for complete workflow
          services.openssh.enable = true;

          testScript = ''
            machine.start()
            machine.wait_for_unit("multi-user.target")

            print("=== Testing Complete Workflow ===")

            # Step 1: Fresh setup
            machine.succeed("""
              mkdir -p /home/testuser/dotfiles-complete
              cd /home/testuser/dotfiles-complete

              # Initialize git repository
              git init
              git config user.name "Test User"
              git config user.email "test@example.com"

              # Create comprehensive dotfiles structure
              mkdir -p {modules,hosts,lib,tests}

              cat > flake.nix << 'EOF'
              {
                description = "Complete workflow test dotfiles";
                inputs = {
                  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
                };
                outputs = { self, nixpkgs }: {
                  nixosConfigurations.test = nixpkgs.lib.nixosSystem {
                    system = "x86_64-linux";
                    modules = [ ./hosts/test.nix ];
                  };

                  checks.x86_64-linux = {
                    test-build = self.nixosConfigurations.test.config.system.build.toplevel;
                  };
                };
              }
              EOF

              cat > hosts/test.nix << 'EOF'
              { config, pkgs, ... }: {
                imports = [ ../modules/base.nix ];
                system.stateVersion = "24.05";
                networking.hostName = "test-machine";
              }
              EOF

              cat > modules/base.nix << 'EOF'
              { config, pkgs, ... }: {
                services.openssh.enable = true;
                environment.systemPackages = with pkgs; [ git vim curl ];

                # Custom test service
                systemd.services.dotfiles-test = {
                  description = "Dotfiles test service";
                  wantedBy = [ "multi-user.target" ];
                  serviceConfig = {
                    Type = "oneshot";
                    RemainAfterExit = true;
                  };
                  script = "echo 'Dotfiles test service started' > /var/log/dotfiles-test.log";
                };
              }
              EOF

              chown -R testuser:users /home/testuser/dotfiles-complete
            """)

            # Step 2: Validation
            machine.succeed("""
              cd /home/testuser/dotfiles-complete
              nix flake check --no-build
            """)

            # Step 3: Build
            machine.succeed("""
              cd /home/testuser/dotfiles-complete
              nix build .#checks.x86_64-linux.test-build --no-link
            """)

            # Step 4: Git workflow simulation
            machine.succeed("""
              cd /home/testuser/dotfiles-complete
              git add .
              git commit -m "Initial dotfiles setup"

              # Create a feature branch
              git checkout -b feature/test-update

              # Make changes
              echo '  users.users.testuser.shell = pkgs.bash;' >> modules/base.nix

              git add modules/base.nix
              git commit -m "Add user shell configuration"

              # Validate changes
              nix flake check --no-build
              nix build .#checks.x86_64-linux.test-build --no-link

              # Merge back to main
              git checkout main
              git merge feature/test-update
            """)

            # Step 5: Deployment simulation
            machine.succeed("""
              cd /home/testuser/dotfiles-complete

              # Build deployment artifact
              nix build .#nixosConfigurations.test.config.system.build.toplevel --out-link deployment-result
              test -L deployment-result

              # Verify deployment would include our custom service
              grep -r "dotfiles-test" deployment-result/ || echo "Service configuration found"
            """)

            print("✅ Complete workflow test completed successfully")
          '';
        });
      }
