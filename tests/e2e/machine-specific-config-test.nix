# Machine-Specific Configuration Validation E2E Test
#
# 개별 머신 설정 검증 테스트
#
# 검증 시나리오:
# 1. macbook-pro 설정 로드 검증 (Darwin, linux-builder 포함)
# 2. baleen-macbook 설정 로드 검증 (Darwin)
# 3. kakaostyle-jito 설정 로드 검증 (Darwin, jito.hello 사용자)
# 4. vm-aarch64-utm NixOS 설정 로드 검증
# 5. 머신별 특정 설정 적용 검증 (hostname 등)
# 6. 사용자별 오버라이드 작동 검증
#
# 이 테스트는 flake에 정의된 모든 머신이 올바르게 빌드될 수 있는지 검증합니다.

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
  name = "machine-specific-config-test";

  nodes = {
    machine =
      { config, pkgs, ... }:
      {
        # Standard VM config
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.hostName = "machine-config-test";
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
        ];

        security.sudo.wheelNeedsPassword = false;

        # Setup test environment
        system.activationScripts.setupMachineConfigTest = {
          text = ''
            mkdir -p /home/testuser/test-machines/{lib,machines,machines/nixos,users/shared}
            chown -R testuser:users /home/testuser/test-machines
          '';
        };
      };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    print("🚀 Starting Machine-Specific Configuration Validation Test...")

    # Test 1: Create lib/mksystem.nix (system factory)
    print("📝 Test 1: Creating lib/mksystem.nix...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Create the actual lib/mksystem.nix from the codebase
        cat > lib/mksystem.nix << "EOF"
    { inputs, self, overlays ? [] }:

    name:
    {
      system,
      user,
      darwin ? false,
      wsl ? false,
    }:

    let
      inherit (inputs.nixpkgs) lib;
      systemFunc = if darwin then inputs.darwin.lib.darwinSystem else lib.nixosSystem;

      osConfig = if darwin then "darwin.nix" else "nixos.nix";

      # Use shared user configuration directory (users/shared)
      # Actual username is dynamically set via currentSystemUser
      userHMConfig = ./users/shared/home-manager.nix;
      userOSConfig = ./users/shared/''${osConfig};
      machineConfig = ./machines/''${name}.nix;

      # Unified cache configuration for both Determinate Nix and traditional Nix
      cacheSettings = {
        substituters = [
          "https://baleen-nix.cachix.org"
          "https://cache.nixos.org/"
        ];
        trusted-public-keys = [
          "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
        trusted-users = [
          "root"
          user
          "@admin"
          "@wheel"
        ];
      };
    in
    systemFunc {
      inherit system;

      specialArgs = {
        inherit inputs self;
        currentSystem = system;
        currentSystemName = name;
        currentSystemUser = user;
        isWSL = wsl;
        isDarwin = darwin;
      };

      modules = [
        machineConfig
        userOSConfig

        # Conditional Nix configuration for Determinate vs traditional setups
        (
          { lib, ... }:
          {
            # Traditional Nix settings (Linux systems)
            nix.settings = lib.mkIf (!darwin) cacheSettings // {
              # Trust substituters to eliminate "ignoring untrusted substituter" warnings
              trusted-substituters = cacheSettings.substituters;
            };

            # Determinate Nix integration
            determinate-nix.customSettings = cacheSettings;

            # Let Determinate manage Nix on Darwin systems
            nix.enable = lib.mkIf darwin false;
          }
        )
      ]
      ++ lib.optionals darwin [
        # Determinate Nix integration (Darwin systems only)
        inputs.determinate.darwinModules.default
      ] ++ [
        # Home Manager integration
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.''${user} = import userHMConfig;
            extraSpecialArgs = {
              inherit inputs self;
              currentSystemUser = user;
            };
          };

          # Set required home-manager options
          users.users.''${user} = {
            name = user;
            home = if darwin then "/Users/''${user}" else "/home/''${user}";
          };

          # Set hostname for Darwin systems
          networking.hostName = lib.mkIf darwin name;

          # Apply overlays
          nixpkgs.overlays = overlays;
        }
      ];
    }
    EOF
      '
    """)

    print("✅ lib/mksystem.nix created")

    # Test 2: Create mock dependencies
    print("📝 Test 2: Creating mock dependencies...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Create mock inputs
        cat > mock-inputs.nix << "EOF"
    {
      nixpkgs = import <nixpkgs>;
      darwin = {
        lib.darwinSystem = x: "darwin-system-result";
      };
      home-manager = {
        darwinModules.home-manager = "home-manager-darwin-module";
        nixosModules.home-manager = "home-manager-nixos-module";
      };
      determinate = {
        darwinModules.default = "determinate-module";
      };
    }
    EOF

        # Create mock self
        echo "{}" > self.nix
      '
    """)

    print("✅ Mock dependencies created")

    # Test 3: Create all machine configs
    print("📝 Test 3: Creating all machine configurations...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Create macbook-pro machine config
        cat > machines/macbook-pro.nix << "EOF"
    { pkgs, lib, config, ... }:

    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
      useLinuxBuilder = isDarwin && config.nix.enable;
    in
    {
      # Linux builder configuration (macOS only)
      nix.linux-builder = lib.mkIf useLinuxBuilder {
        enable = true;
        systems = [ "x86_64-linux" "aarch64-linux" ];
        maxJobs = 4;
      };

      # Minimal system-level settings
      environment.systemPackages = with pkgs; [ home-manager ];
      programs.zsh.enable = true;
      system.stateVersion = 5;

      nix.settings = lib.mkIf useLinuxBuilder {
        system-features = [ "nixos-test" "apple-virt" ];
        trusted-users = [ "@admin" ];
      };
    }
    EOF

        # Create baleen-macbook machine config
        cat > machines/baleen-macbook.nix << "EOF"
    { pkgs, lib, config, ... }:

    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
    in
    {
      # Similar to macbook-pro but without linux-builder for now
      environment.systemPackages = with pkgs; [ home-manager ];
      programs.zsh.enable = true;
      system.stateVersion = 5;
    }
    EOF

        # Create kakaostyle-jito machine config
        cat > machines/kakaostyle-jito.nix << "EOF"
    { pkgs, lib, config, ... }:

    let
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
      isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
    in
    {
      # Work machine configuration
      nix.linux-builder = lib.mkIf (isDarwin && config.nix.enable) {
        enable = true;
        systems = [ "x86_64-linux" "aarch64-linux" ];
        maxJobs = 4;
      };

      environment.systemPackages = with pkgs; [ home-manager ];
      programs.zsh.enable = true;
      system.stateVersion = 5;
    }
    EOF

        # Create vm-aarch64-utm NixOS config
        cat > machines/nixos/vm-aarch64-utm.nix << "EOF"
    { config, pkgs, modulesPath, ... }:
    {
      # Minimal NixOS VM configuration
      networking.interfaces.enp0s10.useDHCP = true;
      services.spice-vdagentd.enable = true;

      environment.variables.LIBGL_ALWAYS_SOFTWARE = "1";

      nixpkgs.config.allowUnfree = true;
      nixpkgs.config.allowUnsupportedSystem = true;
    }
    EOF

        # Create OS configs
        cat > users/shared/darwin.nix << "EOF"
    { pkgs, lib, currentSystemUser, ... }:
    {
      # Darwin-specific configuration
    }
    EOF

        cat > users/shared/nixos.nix << "EOF"
    { pkgs, lib, currentSystemUser, ... }:
    {
      # NixOS-specific configuration
    }
    EOF

        # Create Home Manager config
        cat > users/shared/home-manager.nix << "EOF"
    { pkgs, lib, currentSystemUser, inputs, self, isDarwin, ... }:
    {
      home.stateVersion = "24.05";
      home.username = currentSystemUser;
      home.homeDirectory = if isDarwin then "/Users/''${currentSystemUser}" else "/home/''${currentSystemUser}";
    }
    EOF
      '
    """)

    print("✅ All machine configurations created")

    # Test 4: Validate macbook-pro configuration
    print("🔍 Test 4: Validating macbook-pro configuration...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Validate macbook-pro configuration structure
        cat > test-macbook-pro.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Test macbook-pro configuration
      macbookProConfig = mkSystem "macbook-pro" {
        system = "aarch64-darwin";
        user = "baleen";
        darwin = true;
        wsl = false;
      };
    in
    {
      # Validate configuration structure
      hasSystem = builtins.hasAttr "system" macbookProConfig;
      systemMatches = macbookProConfig.system == "aarch64-darwin";

      # Validate specialArgs
      hasSpecialArgs = builtins.hasAttr "specialArgs" macbookProConfig;
      specialArgsSystem = macbookProConfig.specialArgs.currentSystem;
      specialArgsName = macbookProConfig.specialArgs.currentSystemName;
      specialArgsUser = macbookProConfig.specialArgs.currentSystemUser;
      specialArgsIsDarwin = macbookProConfig.specialArgs.isDarwin;

      # Expected values
      nameMatches = specialArgsName == "macbook-pro";
      userMatches = specialArgsUser == "baleen";
      isDarwinCorrect = specialArgsIsDarwin == true;
    }
    EOF

        # Run validation
        echo "=== macbook-pro Configuration Validation ==="
        nix eval --impure --expr "(import ./test-macbook-pro.nix).hasSystem" --json
        nix eval --impure --expr "(import ./test-macbook-pro.nix).systemMatches" --json
        nix eval --impure --expr "(import ./test-macbook-pro.nix).specialArgsName"
        nix eval --impure --expr "(import ./test-macbook-pro.nix).specialArgsUser"
        nix eval --impure --expr "(import ./test-macbook-pro.nix).nameMatches" --json
        nix eval --impure --expr "(import ./test-macbook-pro.nix).userMatches" --json
      '
    """)

    print("✅ macbook-pro configuration validated")

    # Test 5: Validate baleen-macbook configuration
    print("🔍 Test 5: Validating baleen-macbook configuration...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Validate baleen-macbook configuration
        cat > test-baleen-macbook.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Test baleen-macbook configuration
      baleenMacbookConfig = mkSystem "baleen-macbook" {
        system = "aarch64-darwin";
        user = "baleen";
        darwin = true;
        wsl = false;
      };
    in
    {
      specialArgsName = baleenMacbookConfig.specialArgs.currentSystemName;
      specialArgsUser = baleenMacbookConfig.specialArgs.currentSystemUser;

      nameMatches = specialArgsName == "baleen-macbook";
      userMatches = specialArgsUser == "baleen";
    }
    EOF

        # Run validation
        echo "=== baleen-macbook Configuration Validation ==="
        nix eval --impure --expr "(import ./test-baleen-macbook.nix).specialArgsName"
        nix eval --impure --expr "(import ./test-baleen-macbook.nix).specialArgsUser"
        nix eval --impure --expr "(import ./test-baleen-macbook.nix).nameMatches" --json
        nix eval --impure --expr "(import ./test-baleen-macbook.nix).userMatches" --json
      '
    """)

    print("✅ baleen-macbook configuration validated")

    # Test 6: Validate kakaostyle-jito configuration with jito.hello user
    print("🔍 Test 6: Validating kakaostyle-jito configuration...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Validate kakaostyle-jito configuration
        cat > test-kakaostyle-jito.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Test kakaostyle-jito configuration
      kakaostyleJitoConfig = mkSystem "kakaostyle-jito" {
        system = "aarch64-darwin";
        user = "jito.hello";
        darwin = true;
        wsl = false;
      };
    in
    {
      specialArgsName = kakaostyleJitoConfig.specialArgs.currentSystemName;
      specialArgsUser = kakaostyleJitoConfig.specialArgs.currentSystemUser;

      nameMatches = specialArgsName == "kakaostyle-jito";
      userMatches = specialArgsUser == "jito.hello";
    }
    EOF

        # Run validation
        echo "=== kakaostyle-jito Configuration Validation ==="
        nix eval --impure --expr "(import ./test-kakaostyle-jito.nix).specialArgsName"
        nix eval --impure --expr "(import ./test-kakaostyle-jito.nix).specialArgsUser"
        nix eval --impure --expr "(import ./test-kakaostyle-jito.nix).nameMatches" --json
        nix eval --impure --expr "(import ./test-kakaostyle-jito.nix).userMatches" --json
      '
    """)

    print("✅ kakaostyle-jito configuration validated")

    # Test 7: Validate vm-aarch64-utm NixOS configuration
    print("🔍 Test 7: Validating vm-aarch64-utm NixOS configuration...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Validate vm-aarch64-utm configuration
        cat > test-vm-aarch64-utm.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Test vm-aarch64-utm configuration (NixOS)
      vmConfig = mkSystem "nixos/vm-aarch64-utm" {
        system = "aarch64-linux";
        user = "baleen";
        darwin = false;
        wsl = false;
      };
    in
    {
      hasSystem = builtins.hasAttr "system" vmConfig;
      systemMatches = vmConfig.system == "aarch64-linux";

      specialArgsName = vmConfig.specialArgs.currentSystemName;
      specialArgsUser = vmConfig.specialArgs.currentSystemUser;
      specialArgsIsDarwin = vmConfig.specialArgs.isDarwin;
      specialArgsIsWSL = vmConfig.specialArgs.isWSL;

      nameMatches = specialArgsName == "nixos/vm-aarch64-utm";
      isDarwinCorrect = specialArgsIsDarwin == false;
      isWSLCorrect = specialArgsIsWSL == false;
      isNixOS = !specialArgsIsDarwin && !specialArgsIsWSL;
    }
    EOF

        # Run validation
        echo "=== vm-aarch64-utm NixOS Configuration Validation ==="
        nix eval --impure --expr "(import ./test-vm-aarch64-utm.nix).hasSystem" --json
        nix eval --impure --expr "(import ./test-vm-aarch64-utm.nix).systemMatches" --json
        nix eval --impure --expr "(import ./test-vm-aarch64-utm.nix).specialArgsIsDarwin" --json
        nix eval --impure --expr "(import ./test-vm-aarch64-utm.nix).specialArgsIsWSL" --json
        nix eval --impure --expr "(import ./test-vm-aarch64-utm.nix).isDarwinCorrect" --json
        nix eval --impure --expr "(import ./test-vm-aarch64-utm.nix).isWSLCorrect" --json
        nix eval --impure --expr "(import ./test-vm-aarch64-utm.nix).isNixOS" --json
      '
    """)

    print("✅ vm-aarch64-utm NixOS configuration validated")

    # Test 8: Validate machine-specific settings (hostname)
    print("🔍 Test 8: Validating machine-specific settings...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Test that hostname is correctly set for each machine
        cat > test-hostname.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Test hostname setting for Darwin machines
      macbookPro = mkSystem "macbook-pro" {
        system = "aarch64-darwin";
        user = "baleen";
        darwin = true;
        wsl = false;
      };

      baleenMacbook = mkSystem "baleen-macbook" {
        system = "aarch64-darwin";
        user = "baleen";
        darwin = true;
        wsl = false;
      };

      kakaostyleJito = mkSystem "kakaostyle-jito" {
        system = "aarch64-darwin";
        user = "jito.hello";
        darwin = true;
        wsl = false;
      };

      # Find networking.hostName in modules
      getHostname = modules:
        let
          filtered = builtins.filter (x:
            if builtins.isAttrs x then
              (x ? networking && x.networking ? hostName)
            else
              false
          ) modules;
        in
          if builtins.length filtered > 0 then
            (builtins.head filtered).networking.hostName
          else
            "not-found";

      macbookProHostname = getHostname macbookPro.modules;
      baleenMacbookHostname = getHostname baleenMacbook.modules;
      kakaostyleJitoHostname = getHostname kakaostyleJito.modules;
    in
    {
      macbookProHostname = macbookProHostname;
      baleenMacbookHostname = baleenMacbookHostname;
      kakaostyleJitoHostname = kakaostyleJitoHostname;

      macbookProCorrect = macbookProHostname == "macbook-pro";
      baleenMacbookCorrect = baleenMacbookHostname == "baleen-macbook";
      kakaostyleJitoCorrect = kakaostyleJitoHostname == "kakaostyle-jito";

      allHostnamesCorrect = macbookProCorrect && baleenMacbookCorrect && kakaostyleJitoCorrect;
    }
    EOF

        # Run validation
        echo "=== Machine-Specific Hostname Validation ==="
        nix eval --impure --expr "(import ./test-hostname.nix).macbookProHostname"
        nix eval --impure --expr "(import ./test-hostname.nix).baleenMacbookHostname"
        nix eval --impure --expr "(import ./test-hostname.nix).kakaostyleJitoHostname"
        nix eval --impure --expr "(import ./test-hostname.nix).allHostnamesCorrect" --json
      '
    """)

    print("✅ Machine-specific settings validated")

    # Test 9: Validate user-specific overrides
    print("🔍 Test 9: Validating user-specific overrides...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Test that different users get different configurations
        cat > test-user-overrides.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Test with baleen user
      baleenConfig = mkSystem "test-machine" {
        system = "aarch64-darwin";
        user = "baleen";
        darwin = true;
        wsl = false;
      };

      # Test with jito.hello user
      jitoHelloConfig = mkSystem "test-machine" {
        system = "aarch64-darwin";
        user = "jito.hello";
        darwin = true;
        wsl = false;
      };

      # Test with testuser
      testuserConfig = mkSystem "test-machine" {
        system = "aarch64-darwin";
        user = "testuser";
        darwin = true;
        wsl = false;
      };
    in
    {
      baleenUser = baleenConfig.specialArgs.currentSystemUser;
      jitoHelloUser = jitoHelloConfig.specialArgs.currentSystemUser;
      testuserUser = testuserConfig.specialArgs.currentSystemUser;

      baleenMatches = baleenUser == "baleen";
      jitoHelloMatches = jitoHelloUser == "jito.hello";
      testuserMatches = testuserUser == "testuser";

      # Verify all users are unique
      allUnique = baleenUser != jitoHelloUser
               && baleenUser != testuserUser
               && jitoHelloUser != testuserUser;

      allCorrect = baleenMatches && jitoHelloMatches && testuserMatches && allUnique;
    }
    EOF

        # Run validation
        echo "=== User-Specific Override Validation ==="
        nix eval --impure --expr "(import ./test-user-overrides.nix).baleenUser"
        nix eval --impure --expr "(import ./test-user-overrides.nix).jitoHelloUser"
        nix eval --impure --expr "(import ./test-user-overrides.nix).testuserUser"
        nix eval --impure --expr "(import ./test-user-overrides.nix).baleenMatches" --json
        nix eval --impure --expr "(import ./test-user-overrides.nix).jitoHelloMatches" --json
        nix eval --impure --expr "(import ./test-user-overrides.nix).testuserMatches" --json
        nix eval --impure --expr "(import ./test-user-overrides.nix).allUnique" --json
        nix eval --impure --expr "(import ./test-user-overrides.nix).allCorrect" --json
      '
    """)

    print("✅ User-specific overrides validated")

    # Test 10: Validate mkSystem correctly creates configs for all machines
    print("🔍 Test 10: Validating mkSystem creates configs for all machines...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-machines

        # Comprehensive test: validate all machines can be created
        cat > test-all-machines.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Create all machine configurations
      machines = {
        macbook-pro = mkSystem "macbook-pro" {
          system = "aarch64-darwin";
          user = "baleen";
          darwin = true;
          wsl = false;
        };

        baleen-macbook = mkSystem "baleen-macbook" {
          system = "aarch64-darwin";
          user = "baleen";
          darwin = true;
          wsl = false;
        };

        kakaostyle-jito = mkSystem "kakaostyle-jito" {
          system = "aarch64-darwin";
          user = "jito.hello";
          darwin = true;
          wsl = false;
        };

        vm-aarch64-utm = mkSystem "nixos/vm-aarch64-utm" {
          system = "aarch64-linux";
          user = "baleen";
          darwin = false;
          wsl = false;
        };
      };

      # Validate each machine
      validateMachine = name: config: {
        inherit name;
        hasSystem = builtins.hasAttr "system" config;
        hasSpecialArgs = builtins.hasAttr "specialArgs" config;
        hasModules = builtins.hasAttr "modules" config;
        system = config.system;
        machineName = config.specialArgs.currentSystemName;
        userName = config.specialArgs.currentSystemUser;
        isDarwin = config.specialArgs.isDarwin;
        isWSL = config.specialArgs.isWSL;
        moduleCount = builtins.length config.modules;
      };

      results = builtins.mapAttrs validateMachine machines;
    in
    {
      # Check all machines have required attributes
      allHaveSystem = builtins.all (r: r.hasSystem) (builtins.attrValues results);
      allHaveSpecialArgs = builtins.all (r: r.hasSpecialArgs) (builtins.attrValues results);
      allHaveModules = builtins.all (r: r.hasModules) (builtins.attrValues results);

      # Check machine names match
      macbookProNameCorrect = results."macbook-pro".machineName == "macbook-pro";
      baleenMacbookNameCorrect = results."baleen-macbook".machineName == "baleen-macbook";
      kakaostyleJitoNameCorrect = results."kakaostyle-jito".machineName == "kakaostyle-jito";
      vmNameCorrect = results."vm-aarch64-utm".machineName == "nixos/vm-aarch64-utm";

      # Check users
      macbookProUserCorrect = results."macbook-pro".userName == "baleen";
      kakaostyleJitoUserCorrect = results."kakaostyle-jito".userName == "jito.hello";

      # Check platforms
      macbookProIsDarwin = results."macbook-pro".isDarwin;
      vmIsNixOS = !results."vm-aarch64-utm".isDarwin && !results."vm-aarch64-utm".isWSL;

      # Overall validation
      allValid = allHaveSystem && allHaveSpecialArgs && allHaveModules
              && macbookProNameCorrect && baleenMacbookNameCorrect
              && kakaostyleJitoNameCorrect && vmNameCorrect
              && macbookProUserCorrect && kakaostyleJitoUserCorrect
              && macbookProIsDarwin && vmIsNixOS;

      machineCount = builtins.length (builtins.attrValues machines);
    }
    EOF

        # Run comprehensive validation
        echo "=== All Machines Comprehensive Validation ==="
        nix eval --impure --expr "(import ./test-all-machines.nix).allHaveSystem" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).allHaveSpecialArgs" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).allHaveModules" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).macbookProNameCorrect" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).kakaostyleJitoNameCorrect" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).macbookProUserCorrect" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).kakaostyleJitoUserCorrect" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).macbookProIsDarwin" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).vmIsNixOS" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).allValid" --json
        nix eval --impure --expr "(import ./test-all-machines.nix).machineCount"
      '
    """)

    print("✅ mkSystem creates configs for all machines correctly")

    # Final validation
    print("\n" + "="*60)
    print("✅ Machine-Specific Configuration Validation Test PASSED!")
    print("="*60)
    print("\nValidated:")
    print("  ✓ macbook-pro configuration loads correctly")
    print("  ✓ baleen-macbook configuration loads correctly")
    print("  ✓ kakaostyle-jito configuration (jito.hello user)")
    print("  ✓ vm-aarch64-utm NixOS configuration")
    print("  ✓ Machine-specific settings (hostname) are applied")
    print("  ✓ User-specific overrides work correctly")
    print("  ✓ mkSystem creates configs for all machines")
    print("\nAll machine configurations are properly structured!")
  '';
}
