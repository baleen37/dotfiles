# E2E Test Helper Functions
#
# Migrated to use unified-test-helpers.nix for backward compatibility
# 공통 헬퍼 함수 모음으로 중복 코드 제거 및 재사용성 향상

{
  pkgs,
  platformSystem,
}:

let
  # Import unified test helpers with compatible configuration
  unifiedHelpers = import ../lib/unified-test-helpers.nix {
    inherit pkgs;
    lib = pkgs.lib;
    testConfig = {
      username = "testuser";
      homeDirPrefix = if platformSystem.isDarwin then "/Users" else "/home";
      inherit platformSystem;
    };
  };
in

# Re-export everything from unified helpers for backward compatibility
unifiedHelpers // {
  # Additional E2E-specific helper functions

  # 플랫폼별 스크립트 존재 검증 (behavioral)
  # This was specific to E2E helpers
  checkPlatformScript =
    scriptBaseName:
    let
      darwinScript = "../../scripts/${scriptBaseName}-darwin.sh";
      linuxScript = "../../scripts/${scriptBaseName}-linux.sh";
      checkScriptReadable =
        scriptPath:
        let
          readResult = builtins.tryEval (builtins.readFile scriptPath);
        in
        readResult.success && builtins.stringLength readResult.value > 0;
    in
    if platformSystem.isDarwin then
      checkScriptReadable darwinScript
    else if platformSystem.isLinux then
      checkScriptReadable linuxScript
    else
      true;
}
