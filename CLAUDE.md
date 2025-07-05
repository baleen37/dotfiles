# CLAUDE.md

> **Last Updated:** 2025-01-06  
> **Version:** 2.0  
> **For:** Claude Code (claude.ai/code)

[... existing content remains unchanged ...]

## Command Design Reflections

- claude/commands 에 command 통합을 대부분 좋지 못하다. 명시적으로 commands를 나누는게 문제가 적다.
  - Command 통합은 시스템의 복잡성을 증가시키고 명확성을 해친다
  - 각 command는 독립적이고 명확한 책임을 가져야 함
  - 통합보다는 모듈화와 명시적 분리가 더 나은 설계 접근법

## Troubleshooting & Prevention

### Common Issues Prevention

1. **Configuration Validation**
   - 변경사항 적용 전 `./scripts/check-config` 실행
   - nix 설정 일관성 및 시스템 파일 충돌 사전 감지

2. **System File Conflicts**
   - build-switch는 이제 자동으로 `/etc/bashrc`, `/etc/zshrc` 백업
   - 원본 파일은 `.before-nix-darwin` 접미사로 보존

3. **Build Configuration Checks**
   - `nix.enable = false`일 때 `nix.gc.automatic = false` 설정 필수
   - 사전 체크 시스템이 이러한 충돌을 감지하고 경고

### Recommended Workflow

```bash
# 1. 구성 검증
./scripts/check-config

# 2. 변경사항 적용
nix run #build-switch

# 3. 문제 발생 시 상세 로그 확인
nix run #build-switch --verbose
```

## Claude Code Limitations & Workarounds

### Root Privilege Requirements

`nix run #build-switch` 실행 시 root 권한이 필요하지만 Claude에서는 sudo 명령을 실행할 수 없음.

**해결 방법:**
1. **코드 분석을 통한 추측**: 빌드 오류 시 `nix build .#darwinConfigurations.aarch64-darwin.system` 명령으로 구체적인 오류 파악
2. **설정 검증**: nix 평가 단계에서 오류 확인 가능
3. **사용자 직접 실행**: Claude가 수정한 코드는 사용자가 직접 테스트 필요

### macOS System Configuration Limitations

nix-darwin에서 일부 macOS 시스템 설정은 `system.defaults`에서 직접 지원하지 않음.
예: `com.apple.HIToolbox.AppleSymbolicHotKeys`

**해결 방법:**
- `system.activationScripts`를 사용하여 Python 스크립트로 plist 파일 직접 수정
- 빌드 시점에 설정 적용되도록 구현
