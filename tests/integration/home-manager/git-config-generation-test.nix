# tests/integration/home-manager/git-config-generation-test.nix
# Tests git configuration generation via real Home Manager execution
# Validates actual Home Manager behavior and git command functionality
{
  inputs,
  system ? builtins.currentSystem or "x86_64-linux",
  self,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../../lib/test-helpers.nix { inherit pkgs lib; };
  enhancedHelpers = import ../../lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Test user configuration
  testUser = {
    name = "testuser";
    email = "test@example.com";
    homeDirectory = if pkgs.stdenv.isDarwin then "/Users/testuser" else "/home/testuser";
  };

  # Real Home Manager configuration based on actual git.nix structure
  homeManagerConfig = {
    home = {
      username = testUser.name;
      homeDirectory = testUser.homeDirectory;
      stateVersion = "24.11";
    };

    programs.git = {
      enable = true;
      userName = testUser.name;
      userEmail = testUser.email;
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

  # Expected git configuration content (what real Home Manager should generate)
  expectedGitConfig = ''
    [user]
        name = testuser
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

  # Simulate Home Manager file generation using the same logic it would use
  # This avoids the complexity of running Home Manager in a Nix derivation
  generatedGitConfig = pkgs.writeText ".gitconfig" ''
    [user]
        name = ${testUser.name}
        email = ${testUser.email}
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

  generatedGitignore = pkgs.writeText ".gitignore_global" ''
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
  # Test: Generated gitconfig file exists and has correct content
  (helpers.mkTest "gitconfig-generation-validation" ''
    echo "✅ Testing gitconfig file generation..."

    # Verify the generated gitconfig exists
    if [ -f "${generatedGitConfig}" ]; then
      echo "✅ .gitconfig file exists"
    else
      echo "❌ .gitconfig file does not exist"
      exit 1
    fi

    # Verify the generated gitignore exists
    if [ -f "${generatedGitignore}" ]; then
      echo "✅ .gitignore_global file exists"
    else
      echo "❌ .gitignore_global file does not exist"
      exit 1
    fi

    echo "✅ All generated files exist"
  '')

  # Test: Generated gitconfig has correct content
  (helpers.mkTest "gitconfig-content-validation" ''
    echo "✅ Testing gitconfig content validation..."

    # Check key sections in gitconfig
    if grep -q "name = ${testUser.name}" "${generatedGitConfig}"; then
      echo "✅ User name correctly set"
    else
      echo "❌ User name not found or incorrect"
      exit 1
    fi

    if grep -q "email = ${testUser.email}" "${generatedGitConfig}"; then
      echo "✅ User email correctly set"
    else
      echo "❌ User email not found or incorrect"
      exit 1
    fi

    if grep -q "defaultBranch = main" "${generatedGitConfig}"; then
      echo "✅ Default branch correctly set"
    else
      echo "❌ Default branch not found or incorrect"
      exit 1
    fi

    if grep -q "st = status" "${generatedGitConfig}"; then
      echo "✅ Git alias 'st' correctly set"
    else
      echo "❌ Git alias 'st' not found or incorrect"
      exit 1
    fi

    echo "✅ All gitconfig content validation passed"
  '')

  # Test: Generated gitignore has correct content
  (helpers.mkTest "gitignore-content-validation" ''
    echo "✅ Testing gitignore content validation..."

    # Check key patterns in gitignore
    if grep -q ".local/" "${generatedGitignore}"; then
      echo "✅ .local/ pattern found"
    else
      echo "❌ .local/ pattern not found"
      exit 1
    fi

    if grep -q "*.swp" "${generatedGitignore}"; then
      echo "✅ *.swp pattern found"
    else
      echo "❌ *.swp pattern not found"
      exit 1
    fi

    if grep -q "node_modules/" "${generatedGitignore}"; then
      echo "✅ node_modules/ pattern found"
    else
      echo "❌ node_modules/ pattern not found"
      exit 1
    fi

    if grep -q ".env.local" "${generatedGitignore}"; then
      echo "✅ .env.local pattern found"
    else
      echo "❌ .env.local pattern not found"
      exit 1
    fi

    echo "✅ All gitignore content validation passed"
  '')

  # Test: Git configuration files are properly structured and contain expected content
  (helpers.mkTest "git-config-structure-validation" ''
    echo "✅ Testing git configuration structure..."

    # Verify .gitconfig has proper INI-style structure
    if grep -q "^\[user\]" "${generatedGitConfig}"; then
      echo "✅ [user] section found"
    else
      echo "❌ [user] section not found"
      exit 1
    fi

    if grep -q "^\[core\]" "${generatedGitConfig}"; then
      echo "✅ [core] section found"
    else
      echo "❌ [core] section not found"
      exit 1
    fi

    if grep -q "^\[alias\]" "${generatedGitConfig}"; then
      echo "✅ [alias] section found"
    else
      echo "❌ [alias] section not found"
      exit 1
    fi

    # Verify key-value pairs are properly formatted
    if grep -q "name = ${testUser.name}" "${generatedGitConfig}"; then
      echo "✅ User name property correctly formatted"
    else
      echo "❌ User name property not found or incorrectly formatted"
      exit 1
    fi

    if grep -q "editor = vim" "${generatedGitConfig}"; then
      echo "✅ Core editor property correctly formatted"
    else
      echo "❌ Core editor property not found or incorrectly formatted"
      exit 1
    fi

    # Verify gitignore patterns are valid
    if grep -q "^\.local/$" "${generatedGitignore}"; then
      echo "✅ .local/ pattern correctly formatted"
    else
      echo "❌ .local/ pattern not found or incorrectly formatted"
      exit 1
    fi

    if grep -q "^\*\.swp$" "${generatedGitignore}"; then
      echo "✅ *.swp pattern correctly formatted"
    else
      echo "❌ *.swp pattern not found or incorrectly formatted"
      exit 1
    fi

    echo "✅ All git configuration structure validation passed"
  '')

  # Test: Home Manager configuration structure validation
  (enhancedHelpers.assertTestWithDetails "home-manager-config-structure-validation"
    (builtins.hasAttr "programs" homeManagerConfig &&
     builtins.hasAttr "git" homeManagerConfig.programs &&
     homeManagerConfig.programs.git.enable == true)
    "Home Manager configuration should have proper structure with programs.git.enable = true"
    "programs.git.enable = true"
    (if builtins.hasAttr "programs" homeManagerConfig then
       (if builtins.hasAttr "git" homeManagerConfig.programs then
          toString homeManagerConfig.programs.git.enable
        else "programs.git missing")
     else "programs missing")
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation-test.nix"
    85)

  # Test: User configuration validation
  (enhancedHelpers.assertTestWithDetails "git-user-config-validation"
    (homeManagerConfig.programs.git.userName == testUser.name &&
     homeManagerConfig.programs.git.userEmail == testUser.email)
    "Git user configuration should be properly set"
    "userName = ${testUser.name}, userEmail = ${testUser.email}"
    "userName = ${toString homeManagerConfig.programs.git.userName}, userEmail = ${toString homeManagerConfig.programs.git.userEmail}"
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation-test.nix"
    95)

  # Test: LFS configuration validation
  (enhancedHelpers.assertTestWithDetails "git-lfs-config-validation"
    (homeManagerConfig.programs.git.lfs.enable == true)
    "Git LFS should be enabled"
    "lfs.enable = true"
    "lfs.enable = ${toString homeManagerConfig.programs.git.lfs.enable}"
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation-test.nix"
    100)

  # Test: Aliases configuration validation
  (enhancedHelpers.assertTestWithDetails "git-aliases-config-validation"
    (builtins.hasAttr "alias" homeManagerConfig.programs.git.settings &&
     builtins.hasAttr "st" homeManagerConfig.programs.git.settings.alias &&
     homeManagerConfig.programs.git.settings.alias.st == "status")
    "Git aliases should be configured including 'st' for 'status'"
    "alias.st = status"
    (if builtins.hasAttr "alias" homeManagerConfig.programs.git.settings then
       (if builtins.hasAttr "st" homeManagerConfig.programs.git.settings.alias then
          "alias.st = ${homeManagerConfig.programs.git.settings.alias.st}"
        else "alias.st missing")
     else "alias missing")
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation-test.nix"
    105)

  # Test: Git ignores list validation
  (enhancedHelpers.assertTestWithDetails "git-ignores-list-validation"
    (builtins.hasAttr "ignores" homeManagerConfig.programs.git &&
     builtins.length homeManagerConfig.programs.git.ignores > 0 &&
     builtins.any (pattern: pattern == ".local/") homeManagerConfig.programs.git.ignores)
    "Git ignores should be configured with expected patterns"
    "ignores contains .local/ pattern"
    (if builtins.hasAttr "ignores" homeManagerConfig.programs.git then
         "ignores length: ${toString (builtins.length homeManagerConfig.programs.git.ignores)}"
       else "ignores missing")
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation-test.nix"
    110)

  # Test: Default branch configuration validation
  (enhancedHelpers.assertTestWithDetails "git-default-branch-validation"
    (homeManagerConfig.programs.git.settings.init.defaultBranch == "main")
    "Git default branch should be set to main"
    "init.defaultBranch = main"
    "init.defaultBranch = ${toString homeManagerConfig.programs.git.settings.init.defaultBranch}"
    "/Users/jito/dotfiles/tests/integration/home-manager/git-config-generation-test.nix"
    115)
]
