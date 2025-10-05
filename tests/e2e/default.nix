# E2E Tests Entry Point
#
# End-to-end 테스트 스위트의 진입점
# 모든 e2e 테스트를 통합하고 실행

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  self ? null,
}:

let
  # Import NixTest framework
  inherit ((import ../unit/nixtest-template.nix { inherit lib pkgs; })) nixtest;

  # Import individual e2e test suites
  buildSwitchTests = import ./build-switch-test.nix {
    inherit
      lib
      pkgs
      system
      nixtest
      self
      ;
  };

  userWorkflowTests = import ./user-workflow-test.nix {
    inherit
      lib
      pkgs
      system
      nixtest
      self
      ;
  };

  # Import VM-based build-switch tests
  buildSwitchVMTests = import ./build-switch-vm-test.nix {
    inherit lib pkgs system;
  };

in
{
  # Individual test suites
  inherit buildSwitchTests userWorkflowTests;

  # VM-based build-switch tests (실제 동작 검증)
  build-switch-vm-dry = buildSwitchVMTests.dryRunTest;
  build-switch-vm-full = buildSwitchVMTests.vmTest;
  build-switch-vm-all = buildSwitchVMTests.all;

  # Combined e2e test suite
  all = nixtest.suite "All E2E Tests" {
    inherit buildSwitchTests userWorkflowTests;
  };
}
