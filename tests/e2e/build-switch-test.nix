# Build Switch E2E Test
#
# make switch 명령의 정상 작동을 검증하는 테스트
#
# 검증 시나리오:
# 1. 실제 Makefile을 포함한 dotfiles 환경 구성
# 2. make switch 실행
# 3. nixos-rebuild가 호출되고 성공하는지 검증
#

{
  pkgs ? import <nixpkgs> { },
  nixpkgs ? <nixpkgs>,
  lib ? pkgs.lib,
  system ? builtins.currentSystem,
  self ? null,
}:

let
  # Use nixosTest from pkgs (works in flake context)
  nixosTest =
    pkgs.testers.nixosTest or (import "${nixpkgs}/nixos/lib/testing-python.nix" {
      inherit system;
      inherit pkgs;
    });

  # Real Makefile content to embed
  realMakefile = ''
    # Connectivity info for Linux VM
    NIXADDR ?= unset
    NIXPORT ?= 22
    NIXUSER ?= root

    # Get the path to this Makefile and directory
    MAKEFILE_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

    # The name of the nixosConfiguration in the flake
    NIXNAME ?= $(shell hostname -s 2>/dev/null || hostname | cut -d. -f1)

    # SSH options that are used. These aren't meant to be overridden but are
    # reused a lot so we just store them up here.
    SSH_OPTIONS=-o PubkeyAuthentication=no -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

    # Nix command with experimental features
    # For CI environments, use full path to nix binary when available
    NIX_PATH := $(shell which nix 2>/dev/null || echo "nix")
    NIX := $(NIX_PATH) --extra-experimental-features nix-command --extra-experimental-features flakes

    # For sudo commands, we need the full path or preserved PATH
    # Use -H flag to set HOME to target user's home directory and avoid warnings
    SUDO_NIX := sudo -H env PATH=$$PATH $(NIX_PATH) --extra-experimental-features nix-command --extra-experimental-features flakes

    # We need to do some OS switching below.
    UNAME := $(shell uname)

    build-switch: switch

    switch:
    ifeq ($(UNAME), Darwin)
    	NIXPKGS_ALLOW_UNFREE=1 $(SUDO_NIX) run nix-darwin -- switch --flake ".#$(NIXNAME)"
    else
    	NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 $(SUDO_NIX) run "nixpkgs#nixos-rebuild" -- switch --flake ".#''${NIXNAME}"
    endif

    test:
    	@echo "Running dual-mode tests..."
    	@export USER=$''${USER:-$(whoami)} && \
    	if [ "$(UNAME)" = "Darwin" ]; then \
    		echo "macOS detected: Running validation mode (container tests require Linux)"; \
    		echo "Validating all test configurations without execution..."; \
    		NIXPKGS_ALLOW_UNFREE=1 $(NIX) flake check --no-build --impure --accept-flake-config --show-trace; \
    		echo "Validating E2E scenario tests..."; \
    		$(NIX) eval --impure --expr '(import ./tests/e2e/default.nix { self = ./.; }).real-world-only' >/dev/null && echo "E2E tests validated"; \
    		echo "Validation completed - Full container tests will run in CI"; \
    	else \
    		echo "Linux detected: Running full container test execution..."; \
    		NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 $(NIX) flake check --impure --accept-flake-config --show-trace; \
    	fi

    test-integration:
    	@echo "Running integration tests..."
    ifeq ($(UNAME), Darwin)
    	NIXPKGS_ALLOW_UNFREE=1 $(NIX) eval '.#checks.aarch64-darwin.smoke' --impure --accept-flake-config
    else
    	NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 $(NIX) eval '.#checks.x86_64-linux.smoke' --impure --accept-flake-config
    endif

    test-all: test test-integration
    	@echo "All tests completed successfully"

    # Optional: Attempt cross-platform container testing (experimental)
    # Note: This requires additional setup and may not work on all systems
    test-containers:
    	@echo "Attempting container test execution (experimental)..."
    	@export USER=$''${USER:-$(whoami)} && \
    	if [ "$(UNAME)" = "Darwin" ]; then \
    		echo "Cross-compilation detected - this may require additional setup"; \
    		echo "Consider running tests in a Linux VM or CI for reliable results"; \
    		echo "Attempting individual container test build..."; \
    		if NIXPKGS_ALLOW_UNFREE=1 $(NIX) build '.#checks.aarch64-darwin.basic' --impure --accept-flake-config --print-build-logs 2>/dev/null; then \
    			echo "Container test executed successfully"; \
    		else \
    			echo "Container test failed - this is expected on macOS without linux-builder"; \
    			echo "Use 'make test' for validation mode or run tests in Linux environment"; \
    			exit 1; \
    		fi; \
    	else \
    		echo "Linux environment - running full container tests..."; \
    		NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 $(NIX) build '.#checks.$(shell uname -m | sed 's/x86_64/x86_64/;s/arm64/aarch64/').basic' --impure --accept-flake-config --print-build-logs; \
    	fi

    # This builds the given configuration and pushes the results to the
    # cache. This does not alter the current running system. This requires
    # cachix authentication to be configured out of band.
    cache:
    ifeq ($(UNAME), Darwin)
    	nix build '.#darwinConfigurations.$(NIXNAME).system' --json \
    		| jq -r '.[].outputs | to_entries[].value' \
    		| cachix push baleen-nix
    else
    	nix build '.#nixosConfigurations.$(NIXNAME).config.system.build.toplevel' --json \
    		| jq -r '.[].outputs | to_entries[].value' \
    		| cachix push baleen-nix
    endif

    # Backup secrets so that we can transer them to new machines via
    # sneakernet or other means.
    .PHONY: secrets/backup
    secrets/backup:
    	tar -czvf $(MAKEFILE_DIR)/backup.tar.gz \
    		-C $(HOME) \
    		--exclude='.gnupg/.#*' \
    		--exclude='.gnupg/S.*' \
    		--exclude='.gnupg/*.conf' \
    		--exclude='.ssh/environment' \
    		.ssh/ \
    		.gnupg

    .PHONY: secrets/restore
    secrets/restore:
    	if [ ! -f $(MAKEFILE_DIR)/backup.tar.gz ]; then \
    		echo "Error: backup.tar.gz not found in $(MAKEFILE_DIR)"; \
    		exit 1; \
    	fi
    	echo "Restoring SSH keys and GPG keyring from backup..."
    	mkdir -p $(HOME)/.ssh $(HOME)/.gnupg
    	tar -xzvf $(MAKEFILE_DIR)/backup.tar.gz -C $(HOME)
    	chmod 700 $(HOME)/.ssh $(HOME)/.gnupg
    	chmod 600 $(HOME)/.ssh/* || true
    	chmod 700 $(HOME)/.gnupg/* || true

    # bootstrap a brand new VM. The VM should have NixOS ISO on the CD drive
    # and just set the password of the root user to "root". This will install
    # NixOS. After installing NixOS, you must reboot and set the root password
    # for the next step.
    #
    # NOTE(mitchellh): I'm sure there is a way to do this and bootstrap all
    # in one step but when I tried to merge them I got errors. One day.
    vm/bootstrap0:
    	ssh $(SSH_OPTIONS) -p$(NIXPORT) root@$(NIXADDR) " \
    		parted /dev/sda -- mklabel gpt; \
    		parted /dev/sda -- mkpart primary 512MB -8GB; \
    		parted /dev/sda -- mkpart primary linux-swap -8GB 100\%; \
    		parted /dev/sda -- mkpart ESP fat32 1MB 512MB; \
    		parted /dev/sda -- set 3 esp on; \
    		sleep 1; \
    		mkfs.ext4 -L nixos /dev/sda1; \
    		mkswap -L swap /dev/sda2; \
    		mkfs.fat -F 32 -n boot /dev/sda3; \
    		sleep 1; \
    		mount /dev/disk/by-label/nixos /mnt; \
    		mkdir -p /mnt/boot; \
    		mount /dev/disk/by-label/boot /mnt/boot; \
    		nixos-generate-config --root /mnt; \
    		sed --in-place '/system\.stateVersion = .*/a \
    			nix.package = pkgs.nixVersions.latest;\n \
    			nix.extraOptions = \"experimental-features = nix-command flakes\";\n \
    			nix.settings.substituters = [\"https://mitchellh-nixos-config.cachix.org\"];\n \
    			nix.settings.trusted-public-keys = [\"mitchellh-nixos-config.cachix.org-1:bjEbXJyLrL1HZZHBbO4QALnI5faYZppzkU4D2s0G8RQ=\"];\n \
      			services.openssh.enable = true;\n \
    			services.openssh.settings.PasswordAuthentication = true;\n \
    			services.openssh.settings.PermitRootLogin = \"yes\";\n \
    			users.users.root.initialPassword = \"root\";\n \
    		' /mnt/etc/nixos/configuration.nix; \
    		nixos-install --no-root-passwd && reboot; \
    	"

    # after bootstrap0, run this to finalize. After this, do everything else
    # in the VM unless secrets change.
    vm/bootstrap:
    	NIXUSER=root $(MAKE) vm/copy
    	NIXUSER=root $(MAKE) vm/switch
    	$(MAKE) vm/secrets
    	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
    		sudo reboot; \
    	"

    # copy our secrets into the VM
    vm/secrets:
    	# GPG keyring
    	rsync -av -e 'ssh $(SSH_OPTIONS)' \
    		--exclude='.#*' \
    		--exclude='S.*' \
    		--exclude='*.conf' \
    		$(HOME)/.gnupg/ $(NIXUSER)@$(NIXADDR):~/.gnupg
    	# SSH keys
    	rsync -av -e 'ssh $(SSH_OPTIONS)' \
    		--exclude='environment' \
    		$(HOME)/.ssh/ $(NIXUSER)@$(NIXADDR):~/.ssh

    # copy the Nix configurations into the VM.
    vm/copy:
    	rsync -av -e 'ssh $(SSH_OPTIONS) -p$(NIXPORT)' \
    		--exclude='vendor/' \
    		--exclude='.git/' \
    		--exclude='.git-crypt/' \
    		--exclude='.jj/' \
    		--exclude='iso/' \
    		--rsync-path="sudo rsync" \
    		$(MAKEFILE_DIR)/ $(NIXUSER)@$(NIXADDR):/nix-config

    # run the nixos-rebuild switch command. This does NOT copy files so you
    # have to run vm/copy before.
    vm/switch:
    	ssh $(SSH_OPTIONS) -p$(NIXPORT) $(NIXUSER)@$(NIXADDR) " \
    		sudo env PATH=$$PATH NIXPKGS_ALLOW_UNFREE=1 NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM=1 nix --extra-experimental-features nix-command --extra-experimental-features flakes run \"nixpkgs#nixos-rebuild\" -- switch --flake \"/nix-config#''${NIXNAME}\" \
    	"

    # Build a WSL installer
    .PHONY: wsl
    wsl:
    	 nix build ".#nixosConfigurations.wsl.config.system.build.installer"

    # Phony targets
    .PHONY: switch test test-integration test-all test-containers cache vm/bootstrap0 vm/bootstrap vm/copy vm/switch vm/secrets secrets/backup secrets/restore
  '';

in
nixosTest {
  name = "build-switch-test";

  nodes.machine =
    { config, pkgs, ... }:
    {
      # Standard VM config
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      networking.hostName = "test-machine";
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
        nixos-rebuild # Needed for the actual switch command to work eventually
      ];

      security.sudo.wheelNeedsPassword = false;

      # Setup mock repo
      system.activationScripts.setupRepo = {
        text = ''
          mkdir -p /home/testuser/dotfiles/{users/shared,machines,lib,tests}
          chown -R testuser:users /home/testuser/dotfiles
        '';
      };
    };

  testScript = ''
        start_all()
        machine.wait_for_unit("multi-user.target")

        print("🚀 Starting Build Switch Test...")

        # Create flake.nix and other necessary files in the VM
        machine.succeed("""
          su - testuser -c '
            cd ~/dotfiles

            # Write real Makefile
            cat > Makefile << "EOF"
    ${realMakefile}
    EOF

            # Write flake.nix
            cat > flake.nix << "FLAKE_EOF"
    {
      description = "Test Flake";
      inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
      };

      outputs = { self, nixpkgs, home-manager, ... }: {
        nixosConfigurations."test-machine" = nixpkgs.lib.nixosSystem {
          system = "${system}";
          modules = [
            home-manager.nixosModules.home-manager
            ({ pkgs, ... }: {
              system.stateVersion = "24.05";
              boot.loader.systemd-boot.enable = true;
              fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; }; # Dummy FS config to satisfy checks

              # Minimal configuration to prove switch works
              environment.etc."proof-of-switch".text = "Success";

              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.testuser = {
                 home.stateVersion = "24.05";
                 programs.git.enable = true;
              };
            })
          ];
        };
      };
    }
    FLAKE_EOF

            # Git init (flake needs git)
            git init
            git add .
            git config user.email "test@example.com"
            git config user.name "Test User"
            git commit -m "Initial commit"
          '
        """)

        # Run make switch
        print("🔄 Running make switch...")
        result = machine.succeed("su - testuser -c 'cd ~/dotfiles && export USER=testuser && make switch'")
        print(result)

        # Verify that the switch happened
        # We check if the file created by the new configuration exists
        machine.succeed("test -f /etc/proof-of-switch")
        machine.succeed("grep 'Success' /etc/proof-of-switch")

        print("✅ make switch test passed!")
  '';
}
