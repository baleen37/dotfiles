# Makefile Nix Experimental Features Regression Test
#
# Makefile의 모든 nix 명령이 experimental-features 플래그를 올바르게 사용하는지 검증합니다.
#
# 테스트 대상:
# - build-switch 타겟이 $(NIX) 변수를 사용하는지 확인
# - Makefile의 모든 nix run 명령이 experimental-features를 포함하는지 검증
# - NIX 변수 정의가 올바른지 확인
#
# 재발 방지 목적:
# - "error: experimental Nix feature 'nix-command' is disabled" 에러 방지
# - Makefile에서 직접 `nix run` 사용을 방지하고 `$(NIX) run` 사용을 강제
#
# 관련 이슈:
# - Makefile:362에서 nix run을 직접 사용하여 experimental-features 누락

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  nixtest ? null,
}:

let
  nixtestFinal =
    if nixtest != null then
      nixtest
    else
      (import ../unit/nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # System information for test documentation
  currentSystem = system;

  # Makefile 내용을 읽어옴
  makefileContent = builtins.readFile ../../Makefile;
  makefileLines = lib.strings.splitString "\n" makefileContent;

  # NIX 변수 정의 찾기
  nixVariableLine = lib.lists.findFirst (
    line: lib.strings.hasPrefix "NIX :=" line || lib.strings.hasPrefix "NIX=" line
  ) null makefileLines;

  # NIX 변수가 experimental-features를 포함하는지 확인
  nixVariableHasExperimentalFeatures =
    if nixVariableLine != null then
      (lib.strings.hasInfix "--extra-experimental-features" nixVariableLine)
      && (lib.strings.hasInfix "nix-command" nixVariableLine)
      && (lib.strings.hasInfix "flakes" nixVariableLine)
    else
      false;

  # build-switch 타겟 찾기
  buildSwitchLines =
    let
      startIdx = lib.lists.findFirstIndex (
        line: lib.strings.hasPrefix "build-switch:" line
      ) null makefileLines;
      endIdx =
        if startIdx != null then
          lib.lists.findFirstIndex (
            line:
            (lib.strings.hasPrefix ".PHONY:" line)
            || (lib.strings.hasPrefix "# " line && !lib.strings.hasPrefix "#\t" line)
          ) null (lib.lists.drop (startIdx + 1) makefileLines)
        else
          null;
    in
    if startIdx != null && endIdx != null then
      lib.lists.sublist startIdx (endIdx + 1) makefileLines
    else if startIdx != null then
      lib.lists.drop startIdx makefileLines
    else
      [ ];

  # build-switch 타겟에서 nix run 사용 확인
  buildSwitchNixRunLines = builtins.filter (
    line: (lib.strings.hasInfix "nix run" line) && !(lib.strings.hasPrefix "#" (lib.strings.trim line))
  ) buildSwitchLines;

  # build-switch에서 모든 nix run이 $(NIX) run을 사용하는지 확인
  buildSwitchUsesNixVariable = builtins.all (
    line: (lib.strings.hasInfix "$(NIX) run" line) || (lib.strings.hasInfix "$" "{NIX} run" line)
  ) buildSwitchNixRunLines;

  # Makefile 전체에서 잘못된 nix 명령 사용 찾기 ($(NIX) 없이 직접 nix 사용)
  directNixCommands = builtins.filter (
    line:
    let
      trimmed = lib.strings.trim line;
      # 주석이 아니고, nix 명령을 포함하며, $(NIX)나 ${NIX}를 사용하지 않는 경우
      isNotComment = !(lib.strings.hasPrefix "#" trimmed);
      hasNixCommand =
        (lib.strings.hasInfix "nix run" trimmed)
        || (lib.strings.hasInfix "nix build" trimmed)
        || (lib.strings.hasInfix "nix eval" trimmed);
      usesNixVariable =
        (lib.strings.hasInfix "$(NIX)" trimmed) || (lib.strings.hasInfix "$" "{NIX}" trimmed);

      # NIX 변수 정의 라인은 제외
      isNixVariableDefinition = lib.strings.hasPrefix "NIX" trimmed;

      # --extra-experimental-features를 직접 포함하는 경우는 허용
      hasExplicitExperimentalFeatures = lib.strings.hasInfix "--extra-experimental-features" trimmed;
    in
    isNotComment
    && hasNixCommand
    && !usesNixVariable
    && !isNixVariableDefinition
    && !hasExplicitExperimentalFeatures
  ) makefileLines;

  # 직접 nix 명령 사용 개수
  directNixCommandCount = builtins.length directNixCommands;

in
nixtestFinal.suite "Makefile Nix Experimental Features Tests (${currentSystem})" {

  # NIX 변수 정의 검증
  nixVariableTests = nixtestFinal.suite "NIX Variable Definition Tests" {

    nixVariableExists = nixtestFinal.test "NIX variable is defined in Makefile" (
      nixtestFinal.assertions.assertTrue (nixVariableLine != null)
    );

    nixVariableHasCorrectFlags = nixtestFinal.test "NIX variable includes experimental-features flags" (
      nixtestFinal.assertions.assertTrue nixVariableHasExperimentalFeatures
    );

    nixVariableHasNixCommand = nixtestFinal.test "NIX variable includes nix-command feature" (
      let
        hasNixCommand =
          if nixVariableLine != null then lib.strings.hasInfix "nix-command" nixVariableLine else false;
      in
      nixtestFinal.assertions.assertTrue hasNixCommand
    );

    nixVariableHasFlakes = nixtestFinal.test "NIX variable includes flakes feature" (
      let
        hasFlakes =
          if nixVariableLine != null then lib.strings.hasInfix "flakes" nixVariableLine else false;
      in
      nixtestFinal.assertions.assertTrue hasFlakes
    );
  };

  # build-switch 타겟 검증
  buildSwitchTargetTests = nixtestFinal.suite "build-switch Target Tests" {

    buildSwitchExists = nixtestFinal.test "build-switch target exists in Makefile" (
      nixtestFinal.assertions.assertTrue (builtins.length buildSwitchLines > 0)
    );

    buildSwitchUsesNixVariable =
      nixtestFinal.test "build-switch uses $(NIX) variable for nix run commands"
        (
          let
            hasNixRun = builtins.length buildSwitchNixRunLines > 0;
            usesVariable = buildSwitchUsesNixVariable;
          in
          # build-switch에 nix run이 있으면 $(NIX)를 사용해야 함
          nixtestFinal.assertions.assertTrue (!hasNixRun || usesVariable)
        );

    buildSwitchNoDirectNixRun =
      nixtestFinal.test "build-switch does not use direct 'nix run' commands"
        (
          let
            hasDirectNixRun = builtins.any (
              line:
              let
                trimmed = lib.strings.trim line;
                isNotComment = !(lib.strings.hasPrefix "#" trimmed);
                # "nix run"이 있지만 $(NIX)나 ${NIX}가 없는 경우
                hasDirectNix =
                  (lib.strings.hasInfix "nix run" trimmed)
                  && !(lib.strings.hasInfix "$(NIX)" trimmed)
                  && !(lib.strings.hasInfix "$" "{NIX}" trimmed);
              in
              isNotComment && hasDirectNix
            ) buildSwitchLines;
          in
          nixtestFinal.assertions.assertFalse hasDirectNixRun
        );
  };

  # Makefile 전체 검증
  makefileGlobalTests = nixtestFinal.suite "Makefile Global Tests" {

    noDirectNixCommands = nixtestFinal.test "Makefile has no direct nix commands without $(NIX)" (
      nixtestFinal.assertions.assertEqual 0 directNixCommandCount
    );

    allNixCommandsUseVariable =
      nixtestFinal.test "All nix commands use $(NIX) variable or explicit flags"
        (
          let
            # 직접 nix 명령이 없어야 함
            noDirectCommands = directNixCommandCount == 0;
          in
          nixtestFinal.assertions.assertTrue noDirectCommands
        );
  };

  # 회귀 테스트 - 특정 에러 시나리오 검증
  regressionTests = nixtestFinal.suite "Regression Tests" {

    noExperimentalFeaturesError =
      nixtestFinal.test "Prevent 'experimental Nix feature disabled' error"
        (
          let
            # NIX 변수가 올바르게 정의되어 있고, build-switch가 이를 사용하면 에러가 발생하지 않음
            nixVariableCorrect = nixVariableHasExperimentalFeatures;
            buildSwitchCorrect = buildSwitchUsesNixVariable || (builtins.length buildSwitchNixRunLines == 0);
          in
          nixtestFinal.assertions.assertTrue (nixVariableCorrect && buildSwitchCorrect)
        );

    makefileLine362Fixed = nixtestFinal.test "Makefile line 362 (build-switch) uses $(NIX) variable" (
      let
        # build-switch 섹션에서 home-manager 관련 nix run 명령 확인
        homeManagerLines = builtins.filter (
          line: (lib.strings.hasInfix "home-manager" line) && (lib.strings.hasInfix "nix run" line)
        ) buildSwitchLines;

        # home-manager 라인이 $(NIX) run을 사용하는지 확인
        allHomeManagerLinesCorrect = builtins.all (
          line: (lib.strings.hasInfix "$(NIX) run" line) || (lib.strings.hasInfix "$" "{NIX} run" line)
        ) homeManagerLines;
      in
      # home-manager 라인이 없거나, 모두 $(NIX)를 사용하면 통과
      nixtestFinal.assertions.assertTrue (
        (builtins.length homeManagerLines == 0) || allHomeManagerLinesCorrect
      )
    );
  };

  # 에지 케이스 및 예외 상황
  edgeCaseTests = nixtestFinal.suite "Edge Case Tests" {

    commentedNixCommandsIgnored = nixtestFinal.test "Commented nix commands are ignored" (
      let
        commentedNixLines = builtins.filter (
          line:
          let
            trimmed = lib.strings.trim line;
          in
          (lib.strings.hasPrefix "#" trimmed) && (lib.strings.hasInfix "nix run" trimmed)
        ) makefileLines;

        # 주석 처리된 라인은 검증에서 제외되어야 함
        notInDirectCommands = builtins.all (
          commentLine: !(builtins.elem commentLine directNixCommands)
        ) commentedNixLines;
      in
      nixtestFinal.assertions.assertTrue notInDirectCommands
    );

    nixVariableDefinitionNotFlagged =
      nixtestFinal.test "NIX variable definition itself is not flagged"
        (
          let
            # NIX 변수 정의 라인이 directNixCommands에 포함되지 않아야 함
            nixDefNotInDirect =
              if nixVariableLine != null then !(builtins.elem nixVariableLine directNixCommands) else true;
          in
          nixtestFinal.assertions.assertTrue nixDefNotInDirect
        );
  };
}
