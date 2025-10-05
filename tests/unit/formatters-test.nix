# Formatters Unit Tests
#
# lib/formatters.nix 테스트
# - 포매터 가용성 검증
# - 런타임 입력 도구 검증
# - 포매터 스크립트 유효성
#
# 테스트 대상:
# - formatter: 메인 포매터 스크립트
# - runtimeInputs: 필수 도구 포함 여부
# - 포매팅 모드: nix, shell, yaml, json, markdown, lint-nix, all

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  nixtest ? null,
  self ? null,
}:

let
  nixtestFinal =
    if nixtest != null then nixtest else (import ./nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Import formatters
  formatters =
    if self != null then
      import (self + /lib/formatters.nix) { inherit pkgs; }
    else
      import ../../lib/formatters.nix { inherit pkgs; };

  # Expected runtime inputs

in
nixtestFinal.suite "Formatters Tests" {

  # Formatter structure tests
  formatterStructureTests = nixtestFinal.suite "Formatter Structure Tests" {

    formatterExists = nixtestFinal.test "Formatter attribute exists" (
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "formatter" formatters)
    );

    formatterIsDerivation = nixtestFinal.test "Formatter is a derivation" (
      nixtestFinal.assertions.assertTrue (lib.isDerivation formatters.formatter)
    );

    formatterHasName = nixtestFinal.test "Formatter has name" (
      let
        hasName = builtins.hasAttr "name" formatters.formatter;
      in
      nixtestFinal.assertions.assertTrue hasName
    );

    formatterNameCorrect = nixtestFinal.test "Formatter name is correct" (
      nixtestFinal.assertions.assertEqual "dotfiles-format" formatters.formatter.name
    );
  };

  # Runtime inputs tests
  runtimeInputsTests = nixtestFinal.suite "Runtime Inputs Tests" {

    nixfmtIncluded = nixtestFinal.test "nixfmt-rfc-style in runtime inputs" (
      let
        inputs = formatters.formatter.buildInputs or formatters.formatter.runtimeInputs or [ ];
        names = map (pkg: pkg.pname or pkg.name or "") inputs;
      in
      nixtestFinal.assertions.assertTrue (builtins.any (name: lib.hasInfix "nixfmt" name) names)
    );

    statixIncluded = nixtestFinal.test "statix in runtime inputs" (
      let
        inputs = formatters.formatter.buildInputs or formatters.formatter.runtimeInputs or [ ];
        names = map (pkg: pkg.pname or pkg.name or "") inputs;
      in
      nixtestFinal.assertions.assertTrue (builtins.any (name: lib.hasInfix "statix" name) names)
    );

    deadnixIncluded = nixtestFinal.test "deadnix in runtime inputs" (
      let
        inputs = formatters.formatter.buildInputs or formatters.formatter.runtimeInputs or [ ];
        names = map (pkg: pkg.pname or pkg.name or "") inputs;
      in
      nixtestFinal.assertions.assertTrue (builtins.any (name: lib.hasInfix "deadnix" name) names)
    );

    shfmtIncluded = nixtestFinal.test "shfmt in runtime inputs" (
      let
        inputs = formatters.formatter.buildInputs or formatters.formatter.runtimeInputs or [ ];
        names = map (pkg: pkg.pname or pkg.name or "") inputs;
      in
      nixtestFinal.assertions.assertTrue (builtins.any (name: lib.hasInfix "shfmt" name) names)
    );

    prettierIncluded = nixtestFinal.test "prettier in runtime inputs" (
      let
        inputs = formatters.formatter.buildInputs or formatters.formatter.runtimeInputs or [ ];
        names = map (pkg: pkg.pname or pkg.name or "") inputs;
      in
      nixtestFinal.assertions.assertTrue (builtins.any (name: lib.hasInfix "prettier" name) names)
    );

    jqIncluded = nixtestFinal.test "jq in runtime inputs" (
      let
        inputs = formatters.formatter.buildInputs or formatters.formatter.runtimeInputs or [ ];
        names = map (pkg: pkg.pname or pkg.name or "") inputs;
      in
      nixtestFinal.assertions.assertTrue (builtins.any (name: name == "jq") names)
    );

    yamlfmtIncluded = nixtestFinal.test "yamlfmt in runtime inputs" (
      let
        inputs = formatters.formatter.buildInputs or formatters.formatter.runtimeInputs or [ ];
        names = map (pkg: pkg.pname or pkg.name or "") inputs;
      in
      nixtestFinal.assertions.assertTrue (builtins.any (name: lib.hasInfix "yamlfmt" name) names)
    );
  };

  # Script content tests
  scriptContentTests = nixtestFinal.suite "Script Content Tests" {

    scriptHasFormatNixMode = nixtestFinal.test "Script has nix format mode" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "format_nix()" text
    );

    scriptHasFormatShellMode = nixtestFinal.test "Script has shell format mode" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "format_shell()" text
    );

    scriptHasFormatYamlMode = nixtestFinal.test "Script has yaml format mode" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "format_yaml()" text
    );

    scriptHasFormatJsonMode = nixtestFinal.test "Script has json format mode" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "format_json()" text
    );

    scriptHasFormatMarkdownMode = nixtestFinal.test "Script has markdown format mode" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "format_markdown()" text
    );

    scriptHasLintNixMode = nixtestFinal.test "Script has lint-nix mode" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "lint_nix()" text
    );

    scriptHasCaseStatement = nixtestFinal.test "Script has case statement for modes" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "case" text
    );

    scriptUsesNixfmt = nixtestFinal.test "Script uses nixfmt command" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "nixfmt" text
    );

    scriptUsesShfmt = nixtestFinal.test "Script uses shfmt command" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "shfmt" text
    );

    scriptUsesStatix = nixtestFinal.test "Script uses statix command" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "statix" text
    );

    scriptUsesDeadnix = nixtestFinal.test "Script uses deadnix command" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "deadnix" text
    );

    scriptUsesJq = nixtestFinal.test "Script uses jq command" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "jq" text
    );

    scriptUsesYamlfmt = nixtestFinal.test "Script uses yamlfmt command" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "yamlfmt" text
    );

    scriptUsesPrettier = nixtestFinal.test "Script uses prettier command" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "prettier" text
    );
  };

  # Mode handling tests
  modeHandlingTests = nixtestFinal.suite "Mode Handling Tests" {

    scriptHasAllMode = nixtestFinal.test "Script has 'all' mode" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "all)" text
    );

    scriptHasDefaultMode = nixtestFinal.test "Script has default mode handling" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "MODE=" text
    );

    scriptHasUsageMessage = nixtestFinal.test "Script has usage message" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "Usage:" text
    );

    allModeCallsAllFormatters = nixtestFinal.test "'all' mode calls all formatters" (
      let
        text = formatters.formatter.text or "";
        # Check that all mode calls all format functions
        hasAllCalls =
          lib.hasInfix "format_nix" text
          && lib.hasInfix "format_shell" text
          && lib.hasInfix "format_yaml" text
          && lib.hasInfix "format_json" text
          && lib.hasInfix "format_markdown" text;
      in
      nixtestFinal.assertions.assertTrue hasAllCalls
    );
  };

  # File pattern tests
  filePatternTests = nixtestFinal.suite "File Pattern Tests" {

    nixFilesPattern = nixtestFinal.test "Nix files pattern is correct" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "*.nix" text
    );

    shellFilesPattern = nixtestFinal.test "Shell files pattern is correct" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "*.sh" text
    );

    yamlFilesPattern = nixtestFinal.test "YAML files pattern is correct" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertTrue (lib.hasInfix "*.yaml" text || lib.hasInfix "*.yml" text)
    );

    jsonFilesPattern = nixtestFinal.test "JSON files pattern is correct" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "*.json" text
    );

    markdownFilesPattern = nixtestFinal.test "Markdown files pattern is correct" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "*.md" text
    );

    excludesDotFiles = nixtestFinal.test "Excludes hidden/dot files" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "not -path \"*/.*\"" text
    );

    excludesResultDirs = nixtestFinal.test "Excludes result directories" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "result" text
    );
  };

  # Safety and error handling tests
  safetyTests = nixtestFinal.suite "Safety and Error Handling Tests" {

    scriptUsesSetE = nixtestFinal.test "Script uses 'set -e' for safety" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "set -e" text
    );

    scriptHasErrorExit = nixtestFinal.test "Script exits on unknown mode" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "exit 1" text
    );

    scriptHasCompletionMessage = nixtestFinal.test "Script has completion message" (
      let
        text = formatters.formatter.text or "";
      in
      nixtestFinal.assertions.assertStringContains "Formatting complete" text
    );
  };

  # Tool availability tests
  toolAvailabilityTests = nixtestFinal.suite "Tool Availability Tests" {

    allToolsAvailableInNixpkgs = nixtestFinal.test "All required tools available in nixpkgs" (
      let
        toolsExist =
          builtins.all (tool: builtins.hasAttr tool pkgs || builtins.hasAttr tool pkgs.nodePackages)
            [
              "statix"
              "deadnix"
              "shfmt"
              "jq"
              "yamlfmt"
            ];
      in
      nixtestFinal.assertions.assertTrue toolsExist
    );

    nixfmtAvailable = nixtestFinal.test "nixfmt-rfc-style available" (
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "nixfmt-rfc-style" pkgs)
    );

    prettierAvailable = nixtestFinal.test "prettier available in nodePackages" (
      nixtestFinal.assertions.assertTrue (builtins.hasAttr "prettier" pkgs.nodePackages)
    );
  };
}
