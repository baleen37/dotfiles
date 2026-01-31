# Git Configuration Integration Test
#
# Tests the Git configuration in users/shared/git.nix
# Verifies user info from lib/user-info.nix, Git LFS, rebase settings, and gitignore patterns.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  ...
} @ args:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
  patterns = import ../lib/patterns.nix { inherit pkgs lib; helpers = helpers; };
  gitHelpers = import ../lib/git-test-helpers.nix {
    inherit pkgs lib;
    testHelpers = helpers;
  };

  # Import user info from lib/user-info.nix
  userInfo = import ../../lib/user-info.nix;

  # Import git configuration
  gitConfig = import ../../users/shared/git.nix {
    inherit pkgs lib;
    config = { };
  };

  # Extract git settings
  gitSettings = gitConfig.programs.git.settings;
  gitIgnores = gitConfig.programs.git.ignores;

  # Expected aliases
  expectedAliases = {
    st = "status";
    co = "checkout";
    br = "branch";
    ci = "commit";
    df = "diff";
    lg = "log --graph --oneline --decorate --all";
  };

  # Expected gitignore patterns
  expectedIgnores = [
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

in
# ===== 모든 테스트를 하나의 testSuite로 통합 =====

helpers.testSuite "git-configuration-test" [
  # ===== Git 기본 설정 검증 (patterns 사용) =====
  # patterns.testBasicGitConfig는 testSuite를 반환하므로 통합
  (helpers.assertTest "git-enabled" gitConfig.programs.git.enable "Git should be enabled")

  # ===== Git 사용자 정보 검증 (git-helpers 사용) =====

  (gitHelpers.assertGitUserInfo "git-user-info" gitSettings userInfo)

  # ===== Git 설정 전체 검증 (git-helpers 사용) =====

  # assertGitConfigComplete는 testSuite를 반환하므로 개별 테스트로 변환 필요
  # 여기서는 주요 검증만 수행

  # ===== 상세 검증 (assertions 사용) =====
  # Git 활성화 확인
  (assertions.assertAttrEquals "git-enabled" gitConfig.programs.git "enable" true null)

  # Git LFS 활성화 확인
  (assertions.assertAttrEquals "git-lfs-enabled" gitConfig.programs.git.lfs "enable" true null)

  # Git 사용자 이름이 userInfo와 일치하는지 확인
  (assertions.assertAttrEquals "git-user-name-matches" gitSettings.user "name" userInfo.name null)

  # Git 사용자 이메일이 userInfo와 일치하는지 확인
  (assertions.assertAttrEquals "git-user-email-matches" gitSettings.user "email" userInfo.email null)

  # Git aliases 목록이 비어있지 않은지 확인
  (assertions.assertListNotEmpty "git-aliases-not-empty" (builtins.attrNames (gitSettings.alias or {})))

  # Git ignores 목록이 비어있지 않은지 확인
  (assertions.assertListNotEmpty "git-ignores-not-empty" gitIgnores)

  # Git core.editor가 vim인지 확인
  (assertions.assertAttrEquals "git-core-editor" gitSettings.core "editor" "vim" null)

  # Git core.autocrlf가 input인지 확인 (Darwin/Linux 호환)
  (assertions.assertAttrEquals "git-core-autocrlf" gitSettings.core "autocrlf" "input" null)

  # Git init.defaultBranch가 main인지 확인
  (assertions.assertAttrEquals "git-init-defaultBranch" gitSettings.init "defaultBranch" "main" null)

  # Git pull.rebase가 활성화되어 있는지 확인
  (assertions.assertAttrEquals "git-pull-rebase" gitSettings.pull "rebase" true null)

  # Git rebase.autoStash가 활성화되어 있는지 확인
  (assertions.assertAttrEquals "git-rebase-autoStash" gitSettings.rebase "autoStash" true null)

  # ===== 필수 별칭 검증 =====

  (assertions.assertAttrEquals "git-alias-st" gitSettings.alias "st" "status" null)
  (assertions.assertAttrEquals "git-alias-co" gitSettings.alias "co" "checkout" null)
  (assertions.assertAttrEquals "git-alias-br" gitSettings.alias "br" "branch" null)
  (assertions.assertAttrEquals "git-alias-ci" gitSettings.alias "ci" "commit" null)
  (assertions.assertAttrEquals "git-alias-df" gitSettings.alias "df" "diff" null)
  (assertions.assertAttrEquals "git-alias-lg" gitSettings.alias "lg" "log --graph --oneline --decorate --all" null)

  # ===== 필수 gitignore 패턴 검증 =====

  (assertions.assertListContains "gitignore-has-swp" gitIgnores "*.swp" null)
  (assertions.assertListContains "gitignore-has-swo" gitIgnores "*.swo" null)
  (assertions.assertListContains "gitignore-has-dsstore" gitIgnores ".DS_Store" null)
  (assertions.assertListContains "gitignore-has-direnv" gitIgnores ".direnv/" null)
  (assertions.assertListContains "gitignore-has-result" gitIgnores "result" null)
  (assertions.assertListContains "gitignore-has-node-modules" gitIgnores "node_modules/" null)

  # ===== Git alias 안전성 검증 =====

  (gitHelpers.assertGitAliasSafety "git-alias-safety" gitSettings.alias {
    requiredAliases = [ "st" "ci" ];
    dangerousPatterns = [ "rm -rf" "sudo " "chmod 777" ];
  })

  # ===== Git ignore 패턴 안전성 검증 =====

  (gitHelpers.assertGitIgnoreSafety "gitignore-safety" gitIgnores)
]
