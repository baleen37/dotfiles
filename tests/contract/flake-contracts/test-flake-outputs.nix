# Contract Tests for Flake Outputs
# These tests MUST FAIL initially (TDD requirement)

{ lib, runTests, ... }:

let
  # Try to evaluate flake outputs (will fail - implementations don't exist)
  flakeOutputs = builtins.tryEval (import ../../../flake.nix).outputs;

in
runTests {
  # Test flake output structure contracts
  testFlakeHasRequiredOutputs = {
    expr =
      if flakeOutputs.success then
        builtins.all (output: builtins.hasAttr output flakeOutputs.value) [
          "nixosConfigurations"
          "darwinConfigurations"
          "homeConfigurations"
          "checks"
          "apps"
        ]
      else
        false;
    expected = true;
  };

  testFlakeHasTestingPackages = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "packages" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.packages
        && builtins.hasAttr "test-runner" flakeOutputs.value.packages.x86_64-linux
      else
        false;
    expected = true;
  };

  testFlakeHasTestingApps = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "apps" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.apps
        && builtins.all (app: builtins.hasAttr app flakeOutputs.value.apps.x86_64-linux) [
          "test-unit"
          "test-contract"
          "test-integration"
          "test-e2e"
          "test-coverage"
        ]
      else
        false;
    expected = true;
  };

  testFlakeHasTestingChecks = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "checks" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.checks
        && builtins.all (check: builtins.hasAttr check flakeOutputs.value.checks.x86_64-linux) [
          "test-unit-all"
          "test-contract-all"
          "test-integration-all"
          "test-e2e-all"
        ]
      else
        false;
    expected = true;
  };

  # Test apps output contracts (will fail - apps don't exist)
  testTestUnitAppStructure = {
    expr =
      if flakeOutputs.success then
        let
          app = flakeOutputs.value.apps.x86_64-linux.test-unit or null;
        in
        if app != null then
          builtins.hasAttr "type" app && app.type == "app" && builtins.hasAttr "program" app
        else
          false
      else
        false;
    expected = true;
  };

  testTestContractAppStructure = {
    expr =
      if flakeOutputs.success then
        let
          app = flakeOutputs.value.apps.x86_64-linux.test-contract or null;
        in
        if app != null then
          builtins.hasAttr "type" app && app.type == "app" && builtins.hasAttr "program" app
        else
          false
      else
        false;
    expected = true;
  };

  testTestIntegrationAppStructure = {
    expr =
      if flakeOutputs.success then
        let
          app = flakeOutputs.value.apps.x86_64-linux.test-integration or null;
        in
        if app != null then
          builtins.hasAttr "type" app && app.type == "app" && builtins.hasAttr "program" app
        else
          false
      else
        false;
    expected = true;
  };

  testTestE2EAppStructure = {
    expr =
      if flakeOutputs.success then
        let
          app = flakeOutputs.value.apps.x86_64-linux.test-e2e or null;
        in
        if app != null then
          builtins.hasAttr "type" app && app.type == "app" && builtins.hasAttr "program" app
        else
          false
      else
        false;
    expected = true;
  };

  testTestCoverageAppStructure = {
    expr =
      if flakeOutputs.success then
        let
          app = flakeOutputs.value.apps.x86_64-linux.test-coverage or null;
        in
        if app != null then
          builtins.hasAttr "type" app && app.type == "app" && builtins.hasAttr "program" app
        else
          false
      else
        false;
    expected = true;
  };

  # Test checks output contracts (will fail - checks don't exist)
  testTestUnitCheckExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "checks" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.checks
        && builtins.hasAttr "test-unit-all" flakeOutputs.value.checks.x86_64-linux
      else
        false;
    expected = true;
  };

  testTestContractCheckExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "checks" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.checks
        && builtins.hasAttr "test-contract-all" flakeOutputs.value.checks.x86_64-linux
      else
        false;
    expected = true;
  };

  testTestIntegrationCheckExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "checks" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.checks
        && builtins.hasAttr "test-integration-all" flakeOutputs.value.checks.x86_64-linux
      else
        false;
    expected = true;
  };

  testTestE2ECheckExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "checks" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.checks
        && builtins.hasAttr "test-e2e-all" flakeOutputs.value.checks.x86_64-linux
      else
        false;
    expected = true;
  };

  testTestCoverageCheckExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "checks" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.checks
        && builtins.hasAttr "test-coverage-check" flakeOutputs.value.checks.x86_64-linux
      else
        false;
    expected = true;
  };

  # Test packages output contracts (will fail - packages don't exist)
  testTestRunnerPackageExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "packages" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.packages
        && builtins.hasAttr "test-runner" flakeOutputs.value.packages.x86_64-linux
      else
        false;
    expected = true;
  };

  testTestBuilderPackageExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "packages" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.packages
        && builtins.hasAttr "test-builders" flakeOutputs.value.packages.x86_64-linux
      else
        false;
    expected = true;
  };

  testCoverageToolsPackageExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "packages" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.packages
        && builtins.hasAttr "coverage-tools" flakeOutputs.value.packages.x86_64-linux
      else
        false;
    expected = true;
  };

  # Test cross-platform contracts (will fail - cross-platform support doesn't exist)
  testDarwinTestingSupport = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "apps" flakeOutputs.value
        && builtins.hasAttr "x86_64-darwin" flakeOutputs.value.apps
        && builtins.hasAttr "test-unit" flakeOutputs.value.apps.x86_64-darwin
      else
        false;
    expected = true;
  };

  testAarch64DarwinTestingSupport = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "apps" flakeOutputs.value
        && builtins.hasAttr "aarch64-darwin" flakeOutputs.value.apps
        && builtins.hasAttr "test-unit" flakeOutputs.value.apps.aarch64-darwin
      else
        false;
    expected = true;
  };

  testAarch64LinuxTestingSupport = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "apps" flakeOutputs.value
        && builtins.hasAttr "aarch64-linux" flakeOutputs.value.apps
        && builtins.hasAttr "test-unit" flakeOutputs.value.apps.aarch64-linux
      else
        false;
    expected = true;
  };

  # Test input integration contracts (will fail - inputs not properly integrated)
  testNixUnitInputIntegration = {
    expr =
      if flakeOutputs.success then
        let
          inputs = flakeOutputs.value.inputs or { };
        in
        builtins.hasAttr "nix-unit" inputs
      else
        false;
    expected = true;
  };

  testNamakaInputIntegration = {
    expr =
      if flakeOutputs.success then
        let
          inputs = flakeOutputs.value.inputs or { };
        in
        builtins.hasAttr "namaka" inputs
      else
        false;
    expected = true;
  };

  testFlakeCheckerInputIntegration = {
    expr =
      if flakeOutputs.success then
        let
          inputs = flakeOutputs.value.inputs or { };
        in
        builtins.hasAttr "flake-checker" inputs
      else
        false;
    expected = true;
  };

  # Test devShells integration contracts (will fail - devShells not updated)
  testTestingDevShellExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "devShells" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.devShells
        && builtins.hasAttr "testing" flakeOutputs.value.devShells.x86_64-linux
      else
        false;
    expected = true;
  };

  testDefaultDevShellHasTestingTools = {
    expr =
      if flakeOutputs.success then
        let
          defaultShell = flakeOutputs.value.devShells.x86_64-linux.default or null;
        in
        if defaultShell != null then
          builtins.hasAttr "nativeBuildInputs" defaultShell
          && builtins.any (pkg: pkg.pname or "" == "bats") defaultShell.nativeBuildInputs
        else
          false
      else
        false;
    expected = true;
  };

  # Test overlays contracts (will fail - overlays not updated)
  testTestingOverlayExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "overlays" flakeOutputs.value
        && builtins.hasAttr "testing" flakeOutputs.value.overlays
      else
        false;
    expected = true;
  };

  testTestingOverlayProvidesPackages = {
    expr =
      if flakeOutputs.success then
        let
          testingOverlay = flakeOutputs.value.overlays.testing or null;
        in
        if testingOverlay != null then
          let
            pkgs = import <nixpkgs> { overlays = [ testingOverlay ]; };
          in
          builtins.hasAttr "test-runner" pkgs && builtins.hasAttr "coverage-tools" pkgs
        else
          false
      else
        false;
    expected = true;
  };

  # Test formatter integration contracts (will fail - formatter not updated)
  testFormatterSupportsTestFiles = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "formatter" flakeOutputs.value
        && builtins.hasAttr "x86_64-linux" flakeOutputs.value.formatter
      else
        false;
    expected = true;
  };

  # Test lib output contracts (will fail - lib not updated)
  testLibExportsTestingFunctions = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "lib" flakeOutputs.value && builtins.hasAttr "testing" flakeOutputs.value.lib
      else
        false;
    expected = true;
  };

  testLibTestingHasTestBuilders = {
    expr =
      if flakeOutputs.success then
        let
          lib = flakeOutputs.value.lib or { };
          testing = lib.testing or { };
        in
        builtins.hasAttr "mkTestSuite" testing && builtins.hasAttr "mkCoverageReport" testing
      else
        false;
    expected = true;
  };

  # Test template contracts (will fail - templates don't exist)
  testTestingTemplateExists = {
    expr =
      if flakeOutputs.success then
        builtins.hasAttr "templates" flakeOutputs.value
        && builtins.hasAttr "testing" flakeOutputs.value.templates
      else
        false;
    expected = true;
  };

  testTestingTemplateStructure = {
    expr =
      if flakeOutputs.success then
        let
          template = flakeOutputs.value.templates.testing or null;
        in
        if template != null then
          builtins.hasAttr "path" template && builtins.hasAttr "description" template
        else
          false
      else
        false;
    expected = true;
  };

  # Test flake metadata contracts
  testFlakeHasCorrectDescription = {
    expr =
      if flakeOutputs.success then
        let
          flake = flakeOutputs.value;
        in
        builtins.hasAttr "description" flake && builtins.isString flake.description
      else
        false;
    expected = true;
  };

  testFlakeInputsAreValid = {
    expr =
      if flakeOutputs.success then
        let
          flake = flakeOutputs.value;
        in
        builtins.hasAttr "inputs" flake && builtins.isAttrs flake.inputs
      else
        false;
    expected = true;
  };

  # Test flake evaluation contracts
  testFlakeEvaluatesWithoutErrors = {
    expr = flakeOutputs.success;
    expected = true;
  };

  testFlakeOutputsAreComplete = {
    expr =
      if flakeOutputs.success then
        let
          outputs = flakeOutputs.value;
          requiredOutputs = [
            "nixosConfigurations"
            "darwinConfigurations"
            "homeConfigurations"
            "checks"
            "apps"
            "packages"
            "devShells"
            "lib"
          ];
        in
        builtins.all (output: builtins.hasAttr output outputs) requiredOutputs
      else
        false;
    expected = true;
  };
}
