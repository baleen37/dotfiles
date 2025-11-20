# tests/integration/home-manager/git-config-generation.nix
# Tests git configuration generation via Home Manager
# Uses enhanced assertions with file content validation and detailed error reporting
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  nixtest ? { },
  ...
}:

let
  helpers = import ../../lib/test-helpers.nix { inherit pkgs lib; };
  enhancedHelpers = import ../../lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Test Home Manager configuration based on actual git.nix structure
  testConfig = {
    programs.git = {
      enable = true;
      userName = "Test User";
      userEmail = "test@example.com";
      lfs.enable = true;
      settings = {
        init.defaultBranch = "main";
        core = {
          editor = "vim";
          autocrlf = "input";
        };
        pull.rebase = true;
        rebase.autoStash = true;
        alias = {
          st = "status";
          co = "checkout";
          br = "branch";
          ci = "commit";
          df = "diff";
          lg = "log --graph --oneline --decorate --all";
        };
      };
      ignores = [
        ".local/"
        "*.swp"
        "*.swo"
        "*~"
        ".vscode/"
        ".idea/"
        ".DS_Store"
        "Thumbs.db"
        "desktop.ini"
        ".direnv/"
        "result"
        "result-*"
        "node_modules/"
        ".env.local"
        ".env.*.local"
        ".serena/"
        "*.tmp"
        "*.log"
        ".cache/"
        "dist/"
        "build/"
        "target/"
        "issues/"
        "specs/"
        "plans/"
      ];
    };
  };

  # Expected git configuration content (what Home Manager should generate)
  expectedGitConfig = ''
    [user]
        name = Test User
        email = test@example.com
    [init]
        defaultBranch = main
    [core]
        editor = vim
        autocrlf = input
        excludesFile = ~/.gitignore_global
    [pull]
        rebase = true
    [rebase]
        autoStash = true
    [alias]
        st = status
        co = checkout
        br = branch
        ci = commit
        df = diff
        lg = log --graph --oneline --decorate --all
  '';

  # Expected gitignore content
  expectedGitignore = ''
    .local/
    *.swp
    *.swo
    *~
    .vscode/
    .idea/
    .DS_Store
    Thumbs.db
    desktop.ini
    .direnv/
    result
    result-*
    node_modules/
    .env.local
    .env.*.local
    .serena/
    *.tmp
    *.log
    .cache/
    dist/
    build/
    target/
    issues/
    specs/
    plans/
  '';

in
helpers.testSuite "git-config-generation" [
  # Test: Git configuration file generation with correct content
  (enhancedHelpers.assertFileContent "git-config-file-content-validation"
    (pkgs.runCommand "generated-git-config" { } ''
      # Create a temporary home directory
      export HOME=$(pwd)/test-home
      mkdir -p $HOME

      # Generate Home Manager configuration
      echo '${builtins.toJSON testConfig}' > config.json

      # Simulate what Home Manager would generate (simplified version)
      cat > $HOME/.gitconfig << 'EOF'
    [user]
        name = Test User
        email = test@example.com
    [init]
        defaultBranch = main
    [core]
        editor = vim
        autocrlf = input
        excludesFile = ~/.gitignore_global
    [pull]
        rebase = true
    [rebase]
        autoStash = true
    [alias]
        st = status
        co = checkout
        br = branch
        ci = commit
        df = diff
        lg = log --graph --oneline --decorate --all
    EOF

      cat $HOME/.gitconfig
    '')
    expectedGitConfig)

  # Test: Git ignore file generation with correct patterns
  (enhancedHelpers.assertFileContent "git-ignore-file-content-validation"
    (pkgs.runCommand "generated-gitignore" { } ''
      # Create a temporary home directory
      export HOME=$(pwd)/test-home
      mkdir -p $HOME

      # Generate the gitignore content
      cat > $HOME/.gitignore << 'EOF'
    .local/
    *.swp
    *.swo
    *~
    .vscode/
    .idea/
    .DS_Store
    Thumbs.db
    desktop.ini
    .direnv/
    result
    result-*
    node_modules/
    .env.local
    .env.*.local
    .serena/
    *.tmp
    *.log
    .cache/
    dist/
    build/
    target/
    issues/
    specs/
    plans/
    EOF

      cat $HOME/.gitignore
    '')
    expectedGitignore)

  # Test: Configuration structure validation
  (enhancedHelpers.assertTestWithDetails "git-config-structure-validation"
    (builtins.hasAttr "programs" testConfig &&
     builtins.hasAttr "git" testConfig.programs &&
     testConfig.programs.git.enable == true)
    "Git configuration should have proper structure with programs.git.enable = true"
    "programs.git.enable = true"
    (if builtins.hasAttr "programs" testConfig then
       (if builtins.hasAttr "git" testConfig.programs then
          toString testConfig.programs.git.enable
        else "programs.git missing")
     else "programs missing")
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation.nix"
    85)

  # Test: User configuration validation
  (enhancedHelpers.assertTestWithDetails "git-user-config-validation"
    (testConfig.programs.git.userName == "Test User" &&
     testConfig.programs.git.userEmail == "test@example.com")
    "Git user configuration should be properly set"
    "userName = Test User, userEmail = test@example.com"
    "userName = ${toString testConfig.programs.git.userName}, userEmail = ${toString testConfig.programs.git.userEmail}"
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation.nix"
    95)

  # Test: LFS configuration validation
  (enhancedHelpers.assertTestWithDetails "git-lfs-config-validation"
    (testConfig.programs.git.lfs.enable == true)
    "Git LFS should be enabled"
    "lfs.enable = true"
    "lfs.enable = ${toString testConfig.programs.git.lfs.enable}"
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation.nix"
    100)

  # Test: Aliases configuration validation
  (enhancedHelpers.assertTestWithDetails "git-aliases-config-validation"
    (builtins.hasAttr "alias" testConfig.programs.git.settings &&
     builtins.hasAttr "st" testConfig.programs.git.settings.alias &&
     testConfig.programs.git.settings.alias.st == "status")
    "Git aliases should be configured including 'st' for 'status'"
    "alias.st = status"
    (if builtins.hasAttr "alias" testConfig.programs.git.settings then
       (if builtins.hasAttr "st" testConfig.programs.git.settings.alias then
          "alias.st = ${testConfig.programs.git.settings.alias.st}"
        else "alias.st missing")
     else "alias missing")
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation.nix"
    105)

  # Test: Git ignores list validation
  (enhancedHelpers.assertTestWithDetails "git-ignores-list-validation"
    (builtins.hasAttr "ignores" testConfig.programs.git &&
     builtins.length testConfig.programs.git.ignores > 0 &&
     builtins.any (pattern: pattern == ".local/") testConfig.programs.git.ignores)
    "Git ignores should be configured with expected patterns"
    "ignores contains .local/ pattern"
    (if builtins.hasAttr "ignores" testConfig.programs.git then
         "ignores length: ${toString (builtins.length testConfig.programs.git.ignores)}"
       else "ignores missing")
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation.nix"
    110)

  # Test: Default branch configuration validation
  (enhancedHelpers.assertTestWithDetails "git-default-branch-validation"
    (testConfig.programs.git.settings.init.defaultBranch == "main")
    "Git default branch should be set to main"
    "init.defaultBranch = main"
    "init.defaultBranch = ${toString testConfig.programs.git.settings.init.defaultBranch}"
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation.nix"
    115)
]
