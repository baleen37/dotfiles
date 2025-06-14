# Development Scenarios Guide

> **Practical, step-by-step guides for common development tasks**

This guide provides concrete, actionable instructions for real-world development scenarios you'll encounter when working with this dotfiles repository.

## 📦 Package Management Scenarios

### Scenario 1: "I want to add a new development tool"

**Goal**: Add a new package that should be available on all platforms.

#### Step-by-Step Process

1. **Determine the package location**:
   ```bash
   # Check if the package exists in nixpkgs
   nix search nixpkgs your-package-name
   
   # Example: Adding 'jq' JSON processor
   nix search nixpkgs jq
   ```

2. **Add to the appropriate module**:
   ```bash
   # Edit the shared packages file
   $EDITOR modules/shared/packages.nix
   ```

3. **Add the package to the list**:
   ```nix
   # modules/shared/packages.nix
   { pkgs }:

   with pkgs; [
     # Existing packages...
     jq           # JSON processor for command line
     # Keep alphabetical order for maintainability
   ]
   ```

4. **Test the addition**:
   ```bash
   # Build to ensure no conflicts
   make build
   
   # Apply locally to test
   nix run --impure .#build-switch
   
   # Verify package is available
   which jq
   jq --version
   ```

5. **Run quality checks**:
   ```bash
   make lint     # Check formatting
   make test     # Run tests
   ```

### Scenario 2: "I want to add a macOS-only application"

**Goal**: Add a Homebrew cask that should only be installed on macOS.

#### Step-by-Step Process

1. **Find the cask name**:
   ```bash
   # Search Homebrew casks
   brew search your-app-name
   
   # Example: Adding Visual Studio Code
   brew search visual-studio-code
   ```

2. **Add to Darwin casks**:
   ```bash
   $EDITOR modules/darwin/casks.nix
   ```

3. **Add the cask**:
   ```nix
   # modules/darwin/casks.nix
   _:

   [
     # Existing casks...
     "visual-studio-code"    # Add new cask here
     # Keep alphabetical order
   ]
   ```

4. **Test on macOS**:
   ```bash
   # Build Darwin configuration
   make build-darwin
   
   # Apply to see the application install
   nix run --impure .#build-switch
   ```

### Scenario 3: "I want to add a NixOS-only package"

**Goal**: Add a package that only makes sense on NixOS (like a display manager).

#### Step-by-Step Process

1. **Edit NixOS packages**:
   ```bash
   $EDITOR modules/nixos/packages.nix
   ```

2. **Add the package**:
   ```nix
   # modules/nixos/packages.nix
   { pkgs }:

   with pkgs;
   let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
   shared-packages ++ [
     # Existing NixOS packages...
     lightdm          # Display manager for NixOS
   ]
   ```

3. **Test on NixOS**:
   ```bash
   # Build NixOS configuration
   make build-linux
   ```

## 🏗️ Custom Package and Overlay Scenarios

### Scenario 4: "I want to modify an existing package"

**Goal**: Customize an existing nixpkgs package with patches or different configuration.

#### Step-by-Step Process

1. **Create a new overlay**:
   ```bash
   touch overlays/30-my-custom-package.nix
   $EDITOR overlays/30-my-custom-package.nix
   ```

2. **Define the overlay**:
   ```nix
   # overlays/30-my-custom-package.nix
   final: prev: {
     # Override existing package
     your-package = prev.your-package.overrideAttrs (oldAttrs: {
       # Example: Add a patch
       patches = (oldAttrs.patches or []) ++ [
         ./patches/your-patch.patch
       ];
       
       # Example: Change build configuration
       configureFlags = (oldAttrs.configureFlags or []) ++ [
         "--enable-my-feature"
       ];
       
       # Example: Add build dependencies
       buildInputs = (oldAttrs.buildInputs or []) ++ [
         final.some-additional-dependency
       ];
     });
   }
   ```

3. **Test the overlay**:
   ```bash
   # The overlay is automatically applied due to modules/shared/default.nix
   make build
   
   # Test the modified package
   nix run --impure .#build-switch
   your-package --version  # Should show your modifications
   ```

### Scenario 5: "I want to add a completely new package"

**Goal**: Package software that doesn't exist in nixpkgs.

#### Step-by-Step Process

1. **Create the overlay**:
   ```bash
   touch overlays/40-my-new-package.nix
   $EDITOR overlays/40-my-new-package.nix
   ```

2. **Define the package**:
   ```nix
   # overlays/40-my-new-package.nix
   final: prev: {
     my-new-tool = final.stdenv.mkDerivation {
       pname = "my-new-tool";
       version = "1.0.0";
       
       src = final.fetchFromGitHub {
         owner = "owner-name";
         repo = "repo-name";
         rev = "v1.0.0";
         hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
       };
       
       nativeBuildInputs = with final; [
         cmake
         pkg-config
       ];
       
       buildInputs = with final; [
         openssl
         curl
       ];
       
       meta = with final.lib; {
         description = "My awesome new tool";
         homepage = "https://github.com/owner-name/repo-name";
         license = licenses.mit;
         platforms = platforms.unix;
       };
     };
   }
   ```

3. **Add to packages if needed**:
   ```bash
   # Add to shared packages to install by default
   $EDITOR modules/shared/packages.nix
   ```

4. **Test the new package**:
   ```bash
   # Build and test
   nix build .#my-new-tool
   ./result/bin/my-new-tool --help
   
   # Apply to system
   make build
   nix run --impure .#build-switch
   ```

## 🖥️ Host Configuration Scenarios

### Scenario 6: "I want to add a new host/machine"

**Goal**: Set up this dotfiles configuration for a new machine.

#### Step-by-Step Process

1. **Determine the platform and architecture**:
   ```bash
   # Check current system
   uname -m    # aarch64, x86_64
   uname -s    # Darwin, Linux
   ```

2. **For macOS (Darwin) hosts**:
   ```bash
   # Darwin hosts use a single configuration
   # No additional host-specific files needed
   
   # Simply clone and apply
   export USER=$(whoami)
   make build-darwin
   make switch HOST=aarch64-darwin  # or x86_64-darwin
   ```

3. **For NixOS hosts**:
   ```bash
   # Create host-specific directory if needed
   mkdir -p hosts/nixos/your-hostname
   
   # Create hardware configuration
   sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/nixos/your-hostname/hardware-configuration.nix
   
   # Create host configuration
   cat > hosts/nixos/your-hostname/configuration.nix << 'EOF'
   { config, pkgs, ... }:
   
   {
     imports = [
       ./hardware-configuration.nix
       ../default.nix
     ];
     
     # Host-specific settings
     networking.hostName = "your-hostname";
     
     # Add any host-specific configuration here
   }
   EOF
   ```

4. **Update flake.nix for custom NixOS hosts**:
   ```nix
   # Add to nixosConfigurations in flake.nix if using custom host
   nixosConfigurations = {
     # Existing configurations...
     your-hostname = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";  # or aarch64-linux
       specialArgs = inputs;
       modules = [
         disko.nixosModules.disko
         home-manager.nixosModules.home-manager
         ./hosts/nixos/your-hostname/configuration.nix
       ];
     };
   };
   ```

### Scenario 7: "I want to customize settings for this specific machine"

**Goal**: Add machine-specific configurations without affecting other hosts.

#### Step-by-Step Process

1. **For macOS customizations**:
   ```bash
   # Edit the Darwin configuration
   $EDITOR hosts/darwin/default.nix
   ```

2. **Add machine-specific settings**:
   ```nix
   # hosts/darwin/default.nix
   { config, pkgs, ... }:
   
   let
     getUser = import ../../lib/get-user.nix { };
     user = getUser;
     # Get hostname for conditional configuration
     hostname = builtins.readFile /etc/hostname or "unknown";
   in
   {
     # Existing configuration...
     
     # Machine-specific configuration example
     system.defaults.dock.tilesize = 
       if lib.hasPrefix "work-" hostname then 64    # Work machines
       else if lib.hasPrefix "home-" hostname then 48  # Home machines
       else 56;  # Default
   }
   ```

3. **For NixOS customizations**:
   ```bash
   # Edit your specific host configuration
   $EDITOR hosts/nixos/your-hostname/configuration.nix
   ```

## 🔧 Advanced Module Development Scenarios

### Scenario 8: "I want to create a new shared module"

**Goal**: Create a reusable module for a specific application or service.

#### Step-by-Step Process

1. **Create the module file**:
   ```bash
   touch modules/shared/my-app.nix
   $EDITOR modules/shared/my-app.nix
   ```

2. **Define the module**:
   ```nix
   # modules/shared/my-app.nix
   { config, pkgs, lib, ... }:

   with lib;

   let
     cfg = config.programs.my-app;
   in
   {
     options.programs.my-app = {
       enable = mkEnableOption "my-app";
       
       package = mkOption {
         type = types.package;
         default = pkgs.my-app;
         description = "The my-app package to use";
       };
       
       config = mkOption {
         type = types.attrs;
         default = {};
         description = "Configuration for my-app";
       };
     };
     
     config = mkIf cfg.enable {
       home.packages = [ cfg.package ];
       
       home.file.".config/my-app/config.json".text = 
         builtins.toJSON cfg.config;
         
       # Add any additional configuration here
     };
   }
   ```

3. **Import in shared modules**:
   ```bash
   $EDITOR modules/shared/default.nix
   ```

4. **Add to imports**:
   ```nix
   # modules/shared/default.nix
   { config, pkgs, ... }:
   
   {
     imports = [
       # Existing imports...
       ./my-app.nix
     ];
     
     # Existing configuration...
   }
   ```

5. **Enable in home-manager**:
   ```bash
   $EDITOR modules/shared/home-manager.nix
   ```

6. **Configure the module**:
   ```nix
   # modules/shared/home-manager.nix
   { config, pkgs, lib, ... }:
   
   {
     # Existing configuration...
     
     programs.my-app = {
       enable = true;
       config = {
         setting1 = "value1";
         setting2 = "value2";
       };
     };
   }
   ```

### Scenario 9: "I want to use the advanced module library functions"

**Goal**: Leverage the sophisticated file change detection and configuration preservation systems.

#### Step-by-Step Process

1. **Understanding file-change-detector.nix**:
   ```nix
   # Import the detector in your module
   let
     fileDetector = import ../../lib/file-change-detector.nix { inherit lib pkgs; };
   in
   {
     # Use change detection
     myFileCheck = fileDetector.compareFiles 
       "/path/to/original" 
       "/path/to/current";
       
     # Detect changes in directory
     myDirCheck = fileDetector.detectChangesInDirectory 
       "/source/dir" 
       "/target/dir" 
       ["file1.txt" "file2.json"];
   }
   ```

2. **Understanding claude-config-policy.nix**:
   ```nix
   # Import the policy engine
   let
     configPolicy = import ../../lib/claude-config-policy.nix { inherit lib pkgs; };
   in
   {
     # Get policy for a file
     myFilePolicy = configPolicy.getPolicyForFile 
       "/path/to/file" 
       true  # userModified
       { forceOverwrite = false; };
       
     # Generate actions for directory
     myDirPlan = configPolicy.generateDirectoryPlan 
       "/target/dir" 
       "/source/dir" 
       changeDetections 
       { forceOverwrite = false; };
   }
   ```

3. **Create a module using these libraries**:
   ```nix
   # modules/shared/my-config-manager.nix
   { config, pkgs, lib, ... }:

   let
     fileDetector = import ../../lib/file-change-detector.nix { inherit lib pkgs; };
     configPolicy = import ../../lib/claude-config-policy.nix { inherit lib pkgs; };
     
     cfg = config.my-config-manager;
   in
   {
     options.my-config-manager = {
       enable = lib.mkEnableOption "my-config-manager";
       sourceDir = lib.mkOption {
         type = lib.types.path;
         description = "Source directory for configuration files";
       };
       targetDir = lib.mkOption {
         type = lib.types.str;
         description = "Target directory for configuration files";
       };
     };
     
     config = lib.mkIf cfg.enable {
       # Use the detection and policy systems
       home.activation.my-config-sync = lib.hm.dag.entryAfter ["writeBoundary"] ''
         # Detection logic using the library
         echo "Checking for config changes..."
         
         # This would use the Nix functions in a real scenario
         # For activation scripts, you'd generate shell commands
       '';
     };
   }
   ```

## 🎯 Configuration Customization Scenarios

### Scenario 10: "I want to change the shell configuration"

**Goal**: Customize zsh settings, add aliases, or change the prompt.

#### Step-by-Step Process

1. **Edit the shared home-manager configuration**:
   ```bash
   $EDITOR modules/shared/home-manager.nix
   ```

2. **Customize zsh settings**:
   ```nix
   # modules/shared/home-manager.nix
   {
     zsh = {
       enable = true;
       
       # Add custom aliases
       shellAliases = {
         ll = "ls -la";
         la = "ls -la";
         grep = "grep --color=auto";
         # Add your custom aliases here
       };
       
       # Add to initContent
       initContent = lib.mkBefore ''
         # Your custom shell initialization
         export MY_CUSTOM_VAR="value"
         
         # Custom functions
         myfunction() {
           echo "Hello from my function"
         }
         
         # Existing content continues...
       '';
     };
   }
   ```

3. **Add custom plugins**:
   ```nix
   zsh = {
     plugins = [
       # Existing plugins...
       {
         name = "zsh-syntax-highlighting";
         src = pkgs.zsh-syntax-highlighting;
         file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
       }
       {
         name = "zsh-autosuggestions";
         src = pkgs.zsh-autosuggestions;
         file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
       }
     ];
   };
   ```

### Scenario 11: "I want to customize application settings"

**Goal**: Modify configurations for vim, git, alacritty, or other applications.

#### Step-by-Step Process

1. **Find the application configuration**:
   ```bash
   # All app configs are in modules/shared/home-manager.nix
   grep -n "your-app-name" modules/shared/home-manager.nix
   ```

2. **Example: Customizing Git configuration**:
   ```nix
   git = {
     enable = true;
     userName = "Your Name";
     userEmail = "your.email@example.com";
     
     # Add custom aliases
     aliases = {
       co = "checkout";
       br = "branch";
       ci = "commit";
       st = "status";
       unstage = "reset HEAD --";
       last = "log -1 HEAD";
       visual = "!gitk";
       # Your custom aliases
     };
     
     # Custom configuration
     extraConfig = {
       init.defaultBranch = "main";
       core.editor = "vim";
       
       # Add your custom git settings
       push.default = "simple";
       pull.rebase = true;
       merge.tool = "vimdiff";
     };
   };
   ```

3. **Example: Customizing Vim configuration**:
   ```nix
   vim = {
     enable = true;
     plugins = with pkgs.vimPlugins; [
       # Existing plugins...
       vim-surround          # Add new plugins
       vim-commentary
       nerdtree
     ];
     
     extraConfig = ''
       # Your custom vim configuration
       set number relativenumber
       set tabstop=4
       set shiftwidth=4
       set expandtab
       
       # Custom key mappings
       nnoremap <leader>n :NERDTreeToggle<CR>
       
       # Custom settings...
     '';
   };
   ```

## 🚀 Performance Optimization Scenarios

### Scenario 12: "My builds are taking too long"

**Goal**: Optimize build times and improve development experience.

#### Step-by-Step Process

1. **Enable parallel builds**:
   ```bash
   # Add to your shell profile or run before builds
   export NIX_BUILD_CORES=0  # Use all available cores
   
   # For persistent setting, add to modules/shared/home-manager.nix
   ```

2. **Use build caching**:
   ```bash
   # Check current cache settings
   cat ~/.config/nix/nix.conf
   
   # Add cache settings to hosts/darwin/default.nix or hosts/nixos/default.nix
   ```

3. **Optimize in host configuration**:
   ```nix
   # hosts/darwin/default.nix or hosts/nixos/default.nix
   nix = {
     settings = {
       # Use all available cores
       max-jobs = "auto";
       cores = 0;
       
       # Enable additional caches
       substituters = [
         "https://cache.nixos.org"
         "https://nix-community.cachix.org"
       ];
       
       trusted-public-keys = [
         "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
         "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
       ];
     };
   };
   ```

4. **Clean up to free space**:
   ```bash
   # Clean old generations
   nix-collect-garbage -d
   
   # Clean build cache
   nix store gc
   
   # Optimize store
   nix store optimise
   ```

### Scenario 13: "I want to debug why something isn't working"

**Goal**: Diagnose and fix issues with packages, modules, or configurations.

#### Step-by-Step Process

1. **Enable verbose output**:
   ```bash
   # For detailed build information
   nix build --impure --show-trace .#darwinConfigurations.aarch64-darwin.system
   
   # For very detailed debugging
   nix build --impure --show-trace --verbose .#your-target
   ```

2. **Check individual components**:
   ```bash
   # Test specific packages
   nix-instantiate --eval --expr 'with import <nixpkgs> {}; your-package.version'
   
   # Test specific modules
   nix-instantiate --eval --expr 'with import ./.; darwinConfigurations.aarch64-darwin.config.system.packages'
   ```

3. **Use the REPL for debugging**:
   ```bash
   # Start Nix REPL
   nix repl '<nixpkgs>'
   
   # Load your flake
   :l .
   
   # Inspect configurations
   :t darwinConfigurations.aarch64-darwin
   ```

4. **Test modules individually**:
   ```bash
   # Create a test file for your module
   cat > test-module.nix << 'EOF'
   { pkgs ? import <nixpkgs> {} }:
   
   let
     module = import ./modules/shared/my-module.nix { 
       config = {}; 
       inherit pkgs; 
       lib = pkgs.lib; 
     };
   in module
   EOF
   
   # Test the module
   nix-instantiate --eval test-module.nix
   ```

## 🔄 Development Workflow Scenarios

### Scenario 14: "I want to test changes before applying them"

**Goal**: Safely test configurations without breaking your current setup.

#### Step-by-Step Process

1. **Use the comprehensive local testing**:
   ```bash
   # Run all tests that mirror CI
   ./scripts/test-all-local
   ```

2. **Build without switching**:
   ```bash
   # Build to check for errors
   make build
   
   # Build specific configurations
   nix build --impure .#darwinConfigurations.aarch64-darwin.system
   nix build --impure .#nixosConfigurations.x86_64-linux.config.system.build.toplevel
   ```

3. **Test in a VM (for NixOS)**:
   ```bash
   # Create a VM to test NixOS configurations
   nix run .#nixosConfigurations.your-host.config.system.build.vm
   ```

4. **Use a separate branch for testing**:
   ```bash
   # Create test branch
   git checkout -b test-my-changes
   
   # Make changes and test
   # ... make changes ...
   make lint && make build
   
   # Only apply if tests pass
   nix run --impure .#build-switch
   ```

### Scenario 15: "I want to contribute a feature back to the project"

**Goal**: Properly contribute your improvements to the main repository.

#### Step-by-Step Process

1. **Follow the contribution workflow**:
   ```bash
   # Create feature branch
   git checkout -b feature/my-improvement
   
   # Make your changes following the patterns in this guide
   # ... development work ...
   
   # Run comprehensive tests
   ./scripts/test-all-local
   
   # Ensure code quality
   make lint && make smoke && make build && make smoke
   ```

2. **Document your changes**:
   ```bash
   # Update CONTRIBUTING.md if you're adding new patterns
   # Update this guide if you're adding new scenarios
   # Update README.md if you're adding user-facing features
   ```

3. **Create pull request**:
   ```bash
   # Push your branch
   git push -u origin feature/my-improvement
   
   # Create PR with proper description
   gh pr create --title "feat: description of your improvement" --body "
   ## Description
   Brief description of changes
   
   ## Type of Change
   - [x] New feature
   
   ## Testing
   - [x] Local tests pass (./scripts/test-all-local)
   - [x] Pre-commit workflow complete
   - [x] Tested on: [list platforms]
   "
   ```

---

## 💡 Tips for Effective Development

### General Best Practices

1. **Always test incrementally**: Don't make too many changes at once
2. **Use the module library functions**: Leverage file-change-detector and claude-config-policy for advanced features
3. **Follow existing patterns**: Look at similar implementations before creating new ones
4. **Document as you go**: Update this guide when you discover new scenarios
5. **Test across platforms**: Your changes might affect multiple systems

### Debugging Mindset

1. **Start simple**: Test the minimal change first
2. **Use verbose output**: Don't guess, see what's actually happening
3. **Check one thing at a time**: Isolate the issue to specific components
4. **Read the error messages**: Nix error messages are often very informative
5. **Use the REPL**: Interactive exploration often reveals issues quickly

### Performance Mindset

1. **Use caching**: Don't rebuild what doesn't need rebuilding
2. **Parallel builds**: Take advantage of multiple cores
3. **Clean regularly**: Old generations and cache can slow things down
4. **Profile when needed**: Use `nix-store --gc --print-roots` to understand what's taking space

---

> **Remember**: This guide covers the most common scenarios, but the Nix ecosystem is very flexible. When in doubt, explore existing implementations and don't hesitate to experiment in a safe branch!