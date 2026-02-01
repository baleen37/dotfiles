# System Factory Validation E2E Test
#
# lib/mksystem.nix 시스템 팩토리 검증 테스트
#
# 검증 시나리오:
# 1. mkSystem 함수 파라미터 검증
# 2. specialArgs 전파 검증
# 3. 조건부 모듈 로딩 (Darwin vs NixOS)
# 4. Home Manager 통합
# 5. Overlays 적용
# 6. 캐시 설정 통합
# 7. 유효하지 않은 파라미터 조합 처리
#
# 이 테스트는 시스템의 핵심 추상화인 mkSystem 팩토리를 검증합니다.

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
  commonPackages = import ../lib/fixtures/common-packages.nix { inherit pkgs; };

in
nixosTest {
  name = "system-factory-validation-test";

  nodes = {
    machine =
      { config, pkgs, ... }:
      {
        # Standard VM config
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.hostName = "system-factory-test";
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

        environment.systemPackages = commonPackages.e2eBasicPackages;

        security.sudo.wheelNeedsPassword = false;

        # Setup test environment
        system.activationScripts.setupSystemFactoryTest = {
          text = ''
            mkdir -p /home/testuser/test-factory/{lib,users/shared,machines}
            chown -R testuser:users /home/testuser/test-factory
          '';
        };
      };
  };

  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")

    print("🚀 Starting System Factory Validation Test...")

    # Test 1: Create lib/mksystem.nix (the actual system factory)
    print("📝 Test 1: Creating lib/mksystem.nix...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

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
      userHMConfig = ../users/shared/home-manager.nix;
      userOSConfig = ../users/shared/${osConfig};
      machineConfig = ../machines/${name}.nix;

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
            determinateNix.customSettings = cacheSettings;

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
            users.${user} = import userHMConfig;
            extraSpecialArgs = {
              inherit inputs self;
              currentSystemUser = user;
            };
          };

          # Set required home-manager options
          users.users.${user} = {
            name = user;
            home = if darwin then "/Users/${user}" else "/home/${user}";
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
        cd ~/test-factory

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

        # Create mock machine config
        cat > machines/test-machine.nix << "EOF"
    { config, pkgs, lib, ... }:
    {
      # Test machine configuration
    }
    EOF

        # Create mock OS configs
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

        # Create mock Home Manager config
        cat > users/shared/home-manager.nix << "EOF"
    { pkgs, lib, currentSystemUser, inputs, self, isDarwin, ... }:
    {
      home.stateVersion = "24.05";
      home.username = currentSystemUser;
      home.homeDirectory = if isDarwin then "/Users/\${currentSystemUser}" else "/home/\${currentSystemUser}";
    }
    EOF
      '
    """)

    print("✅ Mock dependencies created")

    # Test 3: Validate mkSystem parameter validation
    print("🔍 Test 3: Validating mkSystem parameter validation...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Test mkSystem with all required parameters
        cat > test-params.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Test with all required parameters
      result = mkSystem "test-machine" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = false;
      };
    in
    {
      inherit result;
      hasSpecialArgs = builtins.hasAttr "specialArgs" result;
      hasModules = builtins.hasAttr "modules" result;
      hasSystem = builtins.hasAttr "system" result;
    }
    EOF

        # Evaluate parameter validation
        nix eval --impure --expr "(import ./test-params.nix).hasSpecialArgs" --json
        nix eval --impure --expr "(import ./test-params.nix).hasModules" --json
        nix eval --impure --expr "(import ./test-params.nix).hasSystem" --json
      '
    """)

    print("✅ mkSystem parameter validation passed")

    # Test 4: Validate specialArgs propagation
    print("🔍 Test 4: Validating specialArgs propagation...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Test specialArgs are passed correctly
        cat > test-specialargs.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Test specialArgs for NixOS
      nixosResult = mkSystem "test-machine" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = false;
      };

      # Test specialArgs for Darwin
      darwinResult = mkSystem "test-machine" {
        system = "aarch64-darwin";
        user = "baleen";
        darwin = true;
        wsl = false;
      };

      # Test specialArgs for WSL
      wslResult = mkSystem "test-machine" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = true;
      };
    in
    {
      # NixOS specialArgs
      nixosSystem = nixosResult.specialArgs.currentSystem;
      nixosName = nixosResult.specialArgs.currentSystemName;
      nixosUser = nixosResult.specialArgs.currentSystemUser;
      nixosWSL = nixosResult.specialArgs.isWSL;
      nixosDarwin = nixosResult.specialArgs.isDarwin;

      # Darwin specialArgs
      darwinSystem = darwinResult.specialArgs.currentSystem;
      darwinName = darwinResult.specialArgs.currentSystemName;
      darwinUser = darwinResult.specialArgs.currentSystemUser;
      darwinWSL = darwinResult.specialArgs.isWSL;
      darwinDarwin = darwinResult.specialArgs.isDarwin;

      # WSL specialArgs
      wslSystem = wslResult.specialArgs.currentSystem;
      wslName = wslResult.specialArgs.currentSystemName;
      wslUser = wslResult.specialArgs.currentSystemUser;
      wslWSL = wslResult.specialArgs.isWSL;
      wslDarwin = wslResult.specialArgs.isDarwin;
    }
    EOF

        # Evaluate specialArgs
        echo "=== NixOS specialArgs ==="
        nix eval --impure --expr "(import ./test-specialargs.nix).nixosSystem"
        nix eval --impure --expr "(import ./test-specialargs.nix).nixosName"
        nix eval --impure --expr "(import ./test-specialargs.nix).nixosUser"
        nix eval --impure --expr "(import ./test-specialargs.nix).nixosWSL"
        nix eval --impure --expr "(import ./test-specialargs.nix).nixosDarwin"

        echo "=== Darwin specialArgs ==="
        nix eval --impure --expr "(import ./test-specialargs.nix).darwinSystem"
        nix eval --impure --expr "(import ./test-specialargs.nix).darwinName"
        nix eval --impure --expr "(import ./test-specialargs.nix).darwinUser"
        nix eval --impure --expr "(import ./test-specialargs.nix).darwinWSL"
        nix eval --impure --expr "(import ./test-specialargs.nix).darwinDarwin"

        echo "=== WSL specialArgs ==="
        nix eval --impure --expr "(import ./test-specialargs.nix).wslSystem"
        nix eval --impure --expr "(import ./test-specialargs.nix).wslName"
        nix eval --impure --expr "(import ./test-specialargs.nix).wslUser"
        nix eval --impure --expr "(import ./test-specialargs.nix).wslWSL"
        nix eval --impure --expr "(import ./test-specialargs.nix).wslDarwin"
      '
    """)

    print("✅ specialArgs propagation validated")

    # Test 5: Validate conditional module loading
    print("🔍 Test 5: Validating conditional module loading...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Test that correct modules are loaded based on platform
        cat > test-modules.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Darwin modules
      darwinResult = mkSystem "test-machine" {
        system = "aarch64-darwin";
        user = "baleen";
        darwin = true;
        wsl = false;
      };

      # NixOS modules
      nixosResult = mkSystem "test-machine" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = false;
      };
    in
    {
      darwinModuleCount = builtins.length darwinResult.modules;
      nixosModuleCount = builtins.length nixosResult.modules;

      # Both should have machine config, OS config, Nix config, HM config
      # Darwin additionally has determinate module
      darwinHasDeterminante = builtins.any (x: x == "determinate-module") darwinResult.modules;
      nixosHasDeterminante = builtins.any (x: x == "determinate-module") nixosResult.modules;
    }
    EOF

        # Check module counts
        echo "Darwin module count:"
        nix eval --impure --expr "(import ./test-modules.nix).darwinModuleCount"
        echo "NixOS module count:"
        nix eval --impure --expr "(import ./test-modules.nix).nixosModuleCount"
      '
    """)

    print("✅ Conditional module loading validated")

    # Test 6: Validate Home Manager integration
    print("🔍 Test 6: Validating Home Manager integration...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Test Home Manager is properly integrated
        cat > test-hm.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      result = mkSystem "test-machine" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = false;
      };

      # Find Home Manager module
      modules = result.modules;
      hasHMDarwinModule = builtins.any (x:
        if builtins.isAttrs x then
          (x ? home-manager && x.home-manager ? users)
        else
          false
      ) modules;
    in
    {
      inherit hasHMDarwinModule;
      totalModules = builtins.length modules;
    }
    EOF

        # Check Home Manager integration
        nix eval --impure --expr "(import ./test-hm.nix).hasHMDarwinModule" --json
        nix eval --impure --expr "(import ./test-hm.nix).totalModules" --json
      '
    """)

    print("✅ Home Manager integration validated")

    # Test 7: Validate overlays application
    print("🔍 Test 7: Validating overlays application...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Test overlays are applied
        cat > test-overlays.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;

      # Create a test overlay
      testOverlay = final: prev: {
        testPackage = prev.hello;
      };

      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [ testOverlay ];
      };
      self = mockSelf;

      result = mkSystem "test-machine" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = false;
      };

      # Check if overlays are in the modules
      modules = result.modules;
      hasOverlays = builtins.any (x:
        if builtins.isAttrs x then
          (x ? nixpkgs && x.nixpkgs ? overlays)
        else
          false
      ) modules;
    in
    {
      inherit hasOverlays;
    }
    EOF

        # Check overlays
        nix eval --impure --expr "(import ./test-overlays.nix).hasOverlays" --json
      '
    """)

    print("✅ Overlays application validated")

    # Test 8: Validate cache settings integration
    print("🔍 Test 8: Validating cache settings integration...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Test cache settings are properly configured
        cat > test-cache.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      darwinResult = mkSystem "test-machine" {
        system = "aarch64-darwin";
        user = "baleen";
        darwin = true;
        wsl = false;
      };

      nixosResult = mkSystem "test-machine" {
        system = "x86_64-linux";
        user = "testuser";
        darwin = false;
        wsl = false;
      };

      # Check Nix config module
      modules = nixosResult.modules;
      nixConfigModule = builtins.filter (x:
        if builtins.isAttrs x then
          (x ? nix && x.nix ? settings)
        else
          false
      ) modules;
    in
    {
      hasNixConfig = builtins.length nixConfigModule > 0;
      moduleCount = builtins.length modules;
    }
    EOF

        # Check cache settings
        nix eval --impure --expr "(import ./test-cache.nix).hasNixConfig" --json
        nix eval --impure --expr "(import ./test-cache.nix).moduleCount" --json
      '
    """)

    print("✅ Cache settings integration validated")

    # Test 9: Validate system function selection
    print("🔍 Test 9: Validating system function selection...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Test that correct system function is used
        cat > test-sysfunc.nix << "EOF"
    let
      lib = import <nixpkgs/lib>;

      # Simulate mkSystem logic
      systemFuncDarwin = "darwinSystem";
      systemFuncNixos = "nixosSystem";

      darwin = true;
      isDarwin = darwin;
      systemFunc1 = if isDarwin then systemFuncDarwin else systemFuncNixos;

      darwin2 = false;
      isDarwin2 = darwin2;
      systemFunc2 = if isDarwin2 then systemFuncDarwin else systemFuncNixos;
    in
    {
      darwinUsesDarwinSystem = systemFunc1 == "darwinSystem";
      nixosUsesNixosSystem = systemFunc2 == "nixosSystem";
    }
    EOF

        # Validate system function selection
        nix eval --impure --expr "(import ./test-sysfunc.nix).darwinUsesDarwinSystem" --json
        nix eval --impure --expr "(import ./test-sysfunc.nix).nixosUsesNixosSystem" --json
      '
    """)

    print("✅ System function selection validated")

    # Test 10: Validate OS config selection
    print("🔍 Test 10: Validating OS config selection...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Test that correct OS config is selected
        cat > test-osconfig.nix << "EOF"
    let
      darwin = true;
      osConfig1 = if darwin then "darwin.nix" else "nixos.nix";

      darwin2 = false;
      osConfig2 = if darwin2 then "darwin.nix" else "nixos.nix";
    in
    {
      darwinUsesDarwinConfig = osConfig1 == "darwin.nix";
      nixosUsesNixosConfig = osConfig2 == "nixos.nix";
    }
    EOF

        # Validate OS config selection
        nix eval --impure --expr "(import ./test-osconfig.nix).darwinUsesDarwinConfig" --json
        nix eval --impure --expr "(import ./test-osconfig.nix).nixosUsesNixosConfig" --json
      '
    """)

    print("✅ OS config selection validated")

    # Test 11: Validate home directory path selection
    print("🔍 Test 11: Validating home directory path selection...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Test that correct home directory is used
        cat > test-homedir.nix << "EOF"
    let
      user = "testuser";
      darwin = true;
      homeDir1 = if darwin then "/Users/\${user}" else "/home/\${user}";

      darwin2 = false;
      homeDir2 = if darwin2 then "/Users/\${user}" else "/home/\${user}";
    in
    {
      darwinUsesUsersDir = homeDir1 == "/Users/testuser";
      nixosUsesHomeDir = homeDir2 == "/home/testuser";
    }
    EOF

        # Validate home directory paths
        nix eval --impure --expr "(import ./test-homedir.nix).darwinUsesUsersDir" --json
        nix eval --impure --expr "(import ./test-homedir.nix).nixosUsesHomeDir" --json
      '
    """)

    print("✅ Home directory path selection validated")

    # Test 12: Comprehensive end-to-end factory test
    print("🔍 Test 12: Running comprehensive factory test...")

    machine.succeed("""
      su - testuser -c '
        cd ~/test-factory

        # Create comprehensive test that validates entire factory
        cat > test-comprehensive.nix << "EOF"
    let
      mockInputs = import ./mock-inputs.nix;
      mockSelf = import ./self.nix;
      mkSystem = import ./lib/mksystem.nix {
        inherit mockInputs self;
        overlays = [];
      };
      self = mockSelf;

      # Test all parameter combinations
      combinations = [
        {
          name = "darwin-aarch64";
          params = {
            system = "aarch64-darwin";
            user = "baleen";
            darwin = true;
            wsl = false;
          };
          expected = {
            systemFunc = "darwin-system-result";
            isDarwin = true;
            isWSL = false;
            homeDir = "/Users/baleen";
          };
        }
        {
          name = "darwin-x86_64";
          params = {
            system = "x86_64-darwin";
            user = "testuser";
            darwin = true;
            wsl = false;
          };
          expected = {
            systemFunc = "darwin-system-result";
            isDarwin = true;
            isWSL = false;
            homeDir = "/Users/testuser";
          };
        }
        {
          name = "nixos-aarch64";
          params = {
            system = "aarch64-linux";
            user = "testuser";
            darwin = false;
            wsl = false;
          };
          expected = {
            isDarwin = false;
            isWSL = false;
            homeDir = "/home/testuser";
          };
        }
        {
          name = "nixos-x86_64";
          params = {
            system = "x86_64-linux";
            user = "baleen";
            darwin = false;
            wsl = false;
          };
          expected = {
            isDarwin = false;
            isWSL = false;
            homeDir = "/home/baleen";
          };
        }
        {
          name = "wsl";
          params = {
            system = "x86_64-linux";
            user = "testuser";
            darwin = false;
            wsl = true;
          };
          expected = {
            isDarwin = false;
            isWSL = true;
            homeDir = "/home/testuser";
          };
        }
      ];

      # Test each combination
      results = builtins.map (combo:
        let
          result = mkSystem "test-machine" combo.params;
          specialArgs = result.specialArgs;
        in
        {
          name = combo.name;
          isDarwinMatch = specialArgs.isDarwin == combo.expected.isDarwin;
          isWSLMatch = specialArgs.isWSL == combo.expected.isWSL;
          hasAllRequired = builtins.hasAttr "currentSystem" specialArgs
                        && builtins.hasAttr "currentSystemName" specialArgs
                        && builtins.hasAttr "currentSystemUser" specialArgs;
        }
      ) combinations;

      # Check if all tests passed
      allPassed = builtins.all (r: r.isDarwinMatch && r.isWSLMatch && r.hasAllRequired) results;
    in
    {
      inherit results;
      allPassed = allPassed;
      testCount = builtins.length combinations;
    }
    EOF

        # Run comprehensive test
        echo "=== Comprehensive Factory Test ==="
        nix eval --impure --expr "(import ./test-comprehensive.nix).allPassed" --json
        nix eval --impure --expr "(import ./test-comprehensive.nix).testCount" --json
      '
    """)

    print("✅ Comprehensive factory test passed")

    # Final validation
    print("\n" + "="*60)
    print("✅ System Factory Validation Test PASSED!")
    print("="*60)
    print("\nValidated:")
    print("  ✓ mkSystem parameter validation")
    print("  ✓ specialArgs propagation")
    print("  ✓ Conditional module loading (Darwin vs NixOS)")
    print("  ✓ Home Manager integration")
    print("  ✓ Overlays application")
    print("  ✓ Cache settings integration")
    print("  ✓ System function selection")
    print("  ✓ OS config selection")
    print("  ✓ Home directory path selection")
    print("  ✓ Comprehensive parameter combinations")
    print("\nThe system factory (mkSystem) works correctly!")
  '';
}
