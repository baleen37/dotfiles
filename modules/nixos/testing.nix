# NixOS-Specific Testing Module
# Linux/NixOS-specific testing configuration and tools

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.testing;

in
{
  options.testing = {
    nixos = {
      enableVMTests = mkEnableOption "VM-based testing support";
      enableSystemdTests = mkEnableOption "systemd service testing";
      enableContainerTests = mkEnableOption "container testing support";
    };
  };

  config = mkIf cfg.enable {
    # NixOS-specific testing packages
    environment.systemPackages =
      with pkgs;
      [
        # Core testing tools
        bats
        jq

        # System testing utilities
        systemd
        util-linux

        # VM testing tools (if enabled)
      ]
      ++ optionals cfg.nixos.enableVMTests [
        qemu
        OVMF
      ]
      ++ optionals cfg.nixos.enableContainerTests [
        docker
        podman
        buildah
      ];

    # Enable systemd user services for testing
    systemd.user.services = mkIf cfg.nixos.enableSystemdTests {
      test-framework = {
        description = "NixOS Testing Framework Service";
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.coreutils}/bin/echo 'Testing framework initialized'";
        };
        wantedBy = [ "default.target" ];
      };
    };

    # Add NixOS-specific testing functions
    _module.args.nixosTesting = {
      # NixOS test environment setup
      nixosTestEnvironment =
        {
          enableVMTests ? false,
          enableContainers ? false,
          ...
        }:
        {
          platform = builtins.currentSystem;
          nixosVersion = config.system.nixos.version or "unknown";
          systemdSupported = true;
          vmTestsSupported = enableVMTests;
          containerSupported = enableContainers;

          paths = {
            systemd = "/run/systemd";
            nixStore = "/nix/store";
            tmpDir = "/tmp";
            homeDir = "/home";
            etcDir = "/etc";
          };

          tools = {
            "nixos-rebuild" = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
            systemctl = "${pkgs.systemd}/bin/systemctl";
            journalctl = "${pkgs.systemd}/bin/journalctl";
            "nix-store" = "${pkgs.nix}/bin/nix-store";
          }
          // optionalAttrs enableVMTests {
            qemu = "${pkgs.qemu}/bin/qemu-system-x86_64";
            "qemu-img" = "${pkgs.qemu}/bin/qemu-img";
          }
          // optionalAttrs enableContainers {
            docker = "${pkgs.docker}/bin/docker";
            podman = "${pkgs.podman}/bin/podman";
          };

          capabilities = [
            "nixos-rebuild"
            "systemd-services"
            "journal-logging"
            "nix-store-management"
          ]
          ++ optionals enableVMTests [
            "vm-testing"
            "qemu-virtualization"
          ]
          ++ optionals enableContainers [
            "container-runtime"
            "oci-containers"
          ];
        };

      # Setup systemd service tests
      setupServiceTests =
        { services, ... }:
        let
          testServices = map (service: {
            name = "systemd-service-${service}";
            service = service;
            tests = [
              {
                name = "service-exists";
                command = "systemctl cat ${service}";
                validation = "service unit file exists";
              }
              {
                name = "service-status";
                command = "systemctl is-enabled ${service}";
                validation = "enabled|disabled|static";
              }
              {
                name = "service-active";
                command = "systemctl is-active ${service}";
                validation = "active|inactive|failed";
              }
            ];
          }) services;
        in
        {
          tests = testServices;
          serviceManager = "systemd";
          commands = {
            start = service: "systemctl start ${service}";
            stop = service: "systemctl stop ${service}";
            restart = service: "systemctl restart ${service}";
            status = service: "systemctl status ${service}";
          };
        };

      # Test NixOS configuration
      testNixOSConfiguration =
        {
          flakeRef ? ".",
          configuration ? "nixos",
          ...
        }:
        {
          name = "nixos-config-test";
          steps = [
            {
              name = "build-configuration";
              command = "nix build ${flakeRef}#nixosConfigurations.${configuration}.config.system.build.toplevel";
              timeout = 600; # 10 minutes for system builds
            }
            {
              name = "check-configuration";
              command = "nixos-rebuild dry-build --flake ${flakeRef}#${configuration}";
              timeout = 300;
            }
            {
              name = "test-configuration";
              command = "nixos-rebuild test --flake ${flakeRef}#${configuration}";
              timeout = 120;
            }
          ];

          validation = {
            systemGeneration = "ls -la /run/current-system";
            nixosVersion = "nixos-version";
            configurationExists = "test -L /run/current-system";
          };
        };

      # VM-based integration testing
      testWithVM =
        {
          name,
          nodes ? { },
          testScript,
          ...
        }:
        let
          vmTest = pkgs.testers.runNixOSTest {
            inherit name testScript;
            nodes = nodes // {
              # Default test machine if no nodes specified
              machine = mkIf (nodes == { }) {
                imports = [ config ];
                virtualisation.memorySize = 2048;
              };
            };
          };
        in
        {
          inherit name;
          vmTest = vmTest;
          testPath = "${vmTest}";

          run = {
            command = "nix build ${vmTest}";
            validation = "VM test passes without errors";
          };
        };

      # Container testing
      testWithContainers =
        {
          image,
          containerName,
          tests ? [ ],
          ...
        }:
        {
          name = "container-test-${containerName}";
          image = image;
          container = containerName;

          lifecycle = {
            setup = [
              "docker pull ${image}"
              "docker run -d --name ${containerName} ${image}"
            ];

            tests = map (test: {
              inherit (test) name;
              command = "docker exec ${containerName} ${test.command}";
              validation = test.validation or "command succeeds";
            }) tests;

            cleanup = [
              "docker stop ${containerName}"
              "docker rm ${containerName}"
            ];
          };
        };

      # Test system journals and logging
      testSystemLogging =
        {
          services ? [ ],
          ...
        }:
        let
          logTests = map (service: {
            name = "logging-${service}";
            tests = [
              {
                name = "service-has-logs";
                command = "journalctl -u ${service} --no-pager | head -10";
                validation = "log entries exist";
              }
              {
                name = "no-critical-errors";
                command = "journalctl -u ${service} -p err --no-pager";
                validation = "no critical errors in logs";
              }
            ];
          }) services;
        in
        {
          tests = logTests;
          logManager = "journald";

          globalLogTests = [
            {
              name = "system-boot-logs";
              command = "journalctl -b --no-pager | head -20";
              validation = "system boot logs available";
            }
            {
              name = "log-rotation";
              command = "journalctl --disk-usage";
              validation = "log rotation working";
            }
          ];
        };

      # Test network configuration
      testNetworkConfiguration =
        {
          interfaces ? [ ],
          ...
        }:
        let
          interfaceTests = map (iface: {
            name = "network-interface-${iface}";
            tests = [
              {
                name = "interface-exists";
                command = "ip link show ${iface}";
                validation = "interface configured";
              }
              {
                name = "interface-up";
                command = "ip link show ${iface} | grep UP";
                validation = "interface is up";
              }
            ];
          }) interfaces;
        in
        {
          tests = interfaceTests;

          generalNetworkTests = [
            {
              name = "dns-resolution";
              command = "nslookup google.com";
              validation = "DNS resolution working";
            }
            {
              name = "internet-connectivity";
              command = "ping -c 1 8.8.8.8";
              validation = "internet connectivity";
            }
          ];
        };

      # Test file system and storage
      testFileSystem =
        {
          mountPoints ? [ "/" ],
          ...
        }:
        let
          fsTests = map (mount: {
            name = "filesystem-${builtins.replaceStrings [ "/" ] [ "-" ] mount}";
            mountPoint = mount;
            tests = [
              {
                name = "mount-exists";
                command = "mount | grep '${mount}'";
                validation = "mount point exists";
              }
              {
                name = "disk-space";
                command = "df -h ${mount}";
                validation = "sufficient disk space";
              }
              {
                name = "read-write-test";
                command = "touch ${mount}/test-file && rm ${mount}/test-file";
                validation = "read-write access";
              }
            ];
          }) mountPoints;
        in
        {
          tests = fsTests;

          storageTests = [
            {
              name = "nix-store-integrity";
              command = "nix-store --verify --check-contents";
              validation = "Nix store integrity";
            }
            {
              name = "tmp-cleanup";
              command = "ls -la /tmp";
              validation = "tmp directory manageable";
            }
          ];
        };

      # Performance testing for NixOS
      testNixOSPerformance =
        { ... }:
        {
          name = "nixos-performance-test";
          metrics = [
            {
              name = "system-build-time";
              command = "time nixos-rebuild test --flake .#nixos";
              threshold = 600; # 10 minutes
            }
            {
              name = "memory-usage";
              command = "free -h";
              validation = "memory usage within limits";
            }
            {
              name = "cpu-load";
              command = "uptime";
              validation = "reasonable CPU load";
            }
            {
              name = "systemd-startup-time";
              command = "systemd-analyze";
              validation = "reasonable startup time";
            }
          ];
        };

      # Cross-platform compatibility helpers
      generateNixOSMatrix =
        {
          architectures ? [
            "x86_64"
            "aarch64"
          ],
          ...
        }:
        {
          os = [
            "ubuntu-latest"
            "ubuntu-20.04"
            "ubuntu-22.04"
          ];
          architecture = architectures;
          include = map (arch: {
            os = "ubuntu-latest";
            platform = "${arch}-linux";
            nixSystem = "${arch}-linux";
          }) architectures;
        };

      # Security testing
      testNixOSSecurity =
        { ... }:
        {
          name = "nixos-security-test";
          tests = [
            {
              name = "firewall-status";
              command = "systemctl is-active firewall";
              validation = "firewall active";
            }
            {
              name = "selinux-status";
              command = "getenforce || echo 'SELinux not enabled'";
              validation = "security policy status";
            }
            {
              name = "user-permissions";
              command = "id -u";
              validation = "running as non-root when appropriate";
            }
            {
              name = "nix-daemon-security";
              command = "systemctl show nix-daemon | grep User";
              validation = "nix-daemon running securely";
            }
          ];
        };
    };

    # NixOS-specific module validation
    assertions = [
      {
        assertion = pkgs.stdenv.isLinux;
        message = "NixOS testing module can only be used on Linux systems";
      }
    ];
  };
}
