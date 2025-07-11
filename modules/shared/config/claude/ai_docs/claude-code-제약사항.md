# Claude Code 환경 제약사항 및 대응 방법

## 🚨 핵심 제약사항

### 실행 환경 제약
- **비대화식 환경**: 사용자 입력이나 프롬프트 처리 불가
- **sudo 제약**: 패스워드 프롬프트가 있는 sudo 명령 실행 불가
- **시스템 레벨 제약**: 시스템 설정 변경 명령 직접 실행 제한

### Darwin/macOS 특수 제약사항
- **darwin-rebuild**: 항상 root 권한 필요
- **시스템 활성화**: `nix run #build-switch` 시 sudo 필요
- **SIP 제약**: 시스템 무결성 보호로 인한 제한사항

## 대응 전략

### 1. 코드 우선 분석 (Code-First Analysis)
실행이 불가능한 상황에서는 **코드 분석을 통한 문제 파악**이 필수입니다.

```bash
# 정적 분석 도구 활용
nix flake check --show-trace
nix build .#target --show-trace
./scripts/check-config

# 스크립트 로직 분석
# - 실행 경로 추적
# - 조건문 및 분기 분석
# - 권한 요구사항 확인
```

### 2. Think Hard 프로토콜
복잡한 시스템 문제는 **반드시 완전한 분석** 후 해결책 제시:

#### 필수 분석 단계
1. **전체 시스템 아키텍처 이해**
2. **의존성 체인 완전 분석**
3. **플랫폼별 특수성 고려**
4. **코드 분석을 통한 논리적 추론**

#### 금지사항
- ❌ 추측에 기반한 임시방편 제안
- ❌ 근본 원인 분석 없는 워크어라운드
- ❌ 불완전한 이해 상태에서의 해결책 제시

### 3. 사용자 가이드 제공
실행 불가능한 명령의 경우 **명확한 수동 실행 지침** 제공:

```bash
# 예시: 권한 문제 해결 가이드
echo "다음 명령을 터미널에서 직접 실행해주세요:"
echo "sudo nix run #build-switch"
echo ""
echo "예상 에러 및 해결 방법:"
echo "1. 권한 거부: sudo 패스워드 입력 필요"
echo "2. 빌드 실패: nix build .#darwinConfigurations.aarch64-darwin.system 먼저 실행"
```

## 진단 프로세스

### Phase 0: 환경 제약 평가
```bash
# 권한 요구사항 확인
if grep -q "sudo" script.sh; then
    echo "⚠️  권한 필요 - 사용자 수동 실행 가이드 제공"
fi

# 대화식 환경 확인
if grep -q "read -p" script.sh; then
    echo "⚠️  대화식 환경 필요 - 제약사항 확인"
fi
```

### Phase 1: 정적 분석
```bash
# 설정 검증
nix flake check --show-trace

# 빌드 테스트
nix build .#target --show-trace

# 스크립트 구문 검사
shellcheck script.sh
```

### Phase 2: 로그 분석
```bash
# 기존 실행 로그 확인
journalctl -u service-name -n 50

# 시스템 로그 분석
tail -f /var/log/system.log
```

### Phase 3: 대안 진단
```bash
# 비특권 진단 도구 활용
./scripts/check-config
./scripts/test-build-switch-health

# 환경 상태 확인
nix-env --version
darwin-rebuild --version
```

## 플랫폼별 대응

### macOS/Darwin 특수 대응
```bash
# 시스템 설정 변경 시
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Darwin 특수 권한 처리
    echo "macOS 환경에서 시스템 설정 변경 시 주의사항:"
    echo "1. SIP 비활성화 필요 여부 확인"
    echo "2. 시스템 활성화 단계에서 sudo 필요"
    echo "3. 사용자 수동 실행 가이드 제공"
fi
```

### Linux 환경 대응
```bash
# Linux 환경 특수 처리
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # systemd 기반 서비스 관리
    echo "Linux 환경 서비스 관리 시:"
    echo "1. systemctl 권한 확인"
    echo "2. 서비스 의존성 확인"
    echo "3. 방화벽 설정 확인"
fi
```

## 성공 사례 패턴

### build-switch 문제 해결 사례
이 사례는 Claude Code 제약사항 대응의 모범 사례입니다:

1. **실행 실패 → 코드 분석 전환**
   - 직접 실행 시도 → 권한 에러 발생
   - 즉시 코드 분석 모드로 전환

2. **sudo 관리 로직 완전 추적**
   - 스크립트 내 sudo 처리 로직 분석
   - 플랫폼별 조건 확인
   - 권한 요구사항 정확히 파악

3. **비대화식 환경 처리 로직 식별**
   - 대화식 프롬프트 처리 부분 확인
   - 비대화식 환경 대응 로직 분석

4. **근본 원인 발견**
   - `SUDO_REQUIRED=false` 설정 문제 식별
   - 플랫폼별 권한 요구사항 불일치 확인

5. **정확한 수정 적용**
   - 조건문 추가로 플랫폼별 분기 처리
   - 근본 원인 해결로 완전한 문제 해결

## 트러블슈팅 체크리스트

### 권한 문제 체크리스트
- [ ] 명령어가 sudo 권한을 요구하는가?
- [ ] 비대화식 환경에서 실행 가능한가?
- [ ] 플랫폼별 특수 권한 요구사항이 있는가?
- [ ] 대안적 접근 방법이 있는가?

### 시스템 명령 체크리스트
- [ ] 시스템 설정을 변경하는 명령인가?
- [ ] 서비스 재시작이 필요한가?
- [ ] 방화벽이나 네트워크 설정을 변경하는가?
- [ ] 사용자 수동 실행이 필요한가?

### 분석 완료 체크리스트
- [ ] 전체 실행 경로를 추적했는가?
- [ ] 모든 의존성을 확인했는가?
- [ ] 플랫폼별 특수성을 고려했는가?
- [ ] 근본 원인을 정확히 파악했는가?

---

*이 제약사항들을 숙지하고 적절히 대응하면 Claude Code 환경에서도 효과적으로 작업할 수 있습니다.*
