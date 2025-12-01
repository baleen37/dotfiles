{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ../..
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  enhancedHelpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Mock config for testing zsh configuration
  mockConfig = {
    home.homeDirectory = "/home/test";
  };

  # Import zsh configuration with mocked dependencies
  zshModule = import ../../users/shared/zsh.nix {
    inherit pkgs lib;
    config = mockConfig;
  };
  zshConfig = zshModule.programs.zsh;
  zshInitContent = zshConfig.initContent;
in
helpers.testSuite "zsh-ccw-function" [
  # Test 1: ccw 함수가 존재하는지 확인
  (helpers.assertTest "ccw-function-exists"
    (builtins.match ".*ccw\\(\\).*" zshInitContent != null)
    "ccw function should exist in zsh initContent")

  # Test 2: ccw 함수가 Usage 메시지를 포함하는지 확인
  (helpers.assertTest "ccw-function-has-usage"
    (builtins.match ".*Usage: ccw <branch-name>.*" zshInitContent != null)
    "ccw function should have usage message")

  # Test 3: Nix 이스케이프가 올바른지 확인 - 가장 중요!
  # Nix indented string에서 bash 변수를 전달하려면 ''${...} 형태여야 함
  # 생성되는 bash 코드는 ${branch_name//\//-} 형태여야 함
  (enhancedHelpers.assertTestWithDetails "ccw-function-has-correct-variable-substitution"
    (builtins.match ".*local worktree_dir=\"\\.worktrees/\\$\\{branch_name//\\\\//-\\}\".*" zshInitContent != null)
    "ccw function should have correct bash variable substitution pattern"
    "correct pattern: \${branch_name//\\//-}"
    (if builtins.match ".*local worktree_dir=\"\\.worktrees/\\$\\{branch_name//\\\\//-\\}\".*" zshInitContent != null then
      "correct pattern found: \${branch_name//\\//-}"
    else if builtins.match ".*local worktree_dir=\"\\.worktrees/\\$\\$\\{branch_name//\\\\//-\\}\".*" zshInitContent != null then
      "incorrect pattern found: \$\${branch_name//\\//-} (double dollar sign)"
    else if builtins.match ".*local worktree_dir=.*branch_name.*" zshInitContent != null then
      "some pattern with branch_name found but format is incorrect"
    else
      "no pattern with branch_name found")
    null
    null)

  # Test 4: git worktree add 명령어가 포함되어 있는지 확인
  (helpers.assertTest "ccw-function-has-git-worktree-add"
    (builtins.match ".*git worktree add.*" zshInitContent != null)
    "ccw function should use git worktree add command")

  # Test 5: Claude Code 실행 (cc 명령어) 포함 확인
  (helpers.assertTest "ccw-function-launches-claude-code"
    (builtins.match ".*cd.*&&.*cc.*" zshInitContent != null)
    "ccw function should navigate to worktree and launch Claude Code")

  # Test 6: 브랜치 존재 여부 확인 로직이 있는지 확인
  (helpers.assertTest "ccw-function-checks-branch-existence"
    (builtins.match ".*git rev-parse --verify.*branch_name.*" zshInitContent != null)
    "ccw function should check if branch exists before creating worktree")

  # Test 7: main/master 브랜치 탐지 로직이 있는지 확인
  (helpers.assertTest "ccw-function-detects-base-branch"
    (builtins.match ".*git rev-parse --verify main.*" zshInitContent != null &&
     builtins.match ".*git rev-parse --verify master.*" zshInitContent != null)
    "ccw function should detect main or master as base branch")

  # Test 8: worktree 디렉토리 존재 확인 로직
  (helpers.assertTest "ccw-function-checks-worktree-exists"
    (builtins.match ".*if.*-d.*worktree_dir.*" zshInitContent != null)
    "ccw function should check if worktree directory already exists")
]
