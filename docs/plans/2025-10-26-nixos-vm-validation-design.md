# NixOS aarch64 VM 검증 시스템 설계

## 개요

NixOS aarch64 가상 머신이 안정적으로 동작하는지 검증하기 위한 포괄적인 테스트 시스템. 로컬 개발 환경에서의 빠른 피드백 루프와 CI 파이프라인에서의 자동화된 검증을 모두 지원한다.

## 목표

- NixOS aarch64 VM이 성공적으로 부트되는지 검증
- 모든 시스템 서비스와 사용자 설정이 올바르게 적용되는지 테스트
- 개발 환경이 완전히 기능하는지 확인
- CI 파이프라인에서 일관된 테스트 결과 제공
- PR 병합 전 신뢰할 수 있는 품질 보장

## 아키텍처

### 핵심 컴포넌트

1. **VM 빌드 시스템**
   - 기존 `flake.nix` 확장하여 VM 관련 출력 추가
   - `nixosConfigurations.nixos-vm-aarch64` 타겟 생성
   - `machines/nixos-vm.nix` 와의 통합

2. **테스트 프레임워크**
   - 부트 검증: VM 시작 및 로그인 프롬프트 도달
   - SSH 연결: 부트 후 VM 접속 가능 여부
   - 서비스 검증: Docker, 사용자 설정 등 핵심 서비스 동작
   - 패키지 테스트: 설치된 패키지 정상 동작 확인

3. **CI 통합**
   - 다중 아키텍처 테스팅 (aarch64-linux, x86_64-linux)
   - GitHub Actions 워크플로우
   - 자동화된 PR 검증 파이프라인

### 데이터 흐름

```
개발자 푸시 → CI 트리거 → VM 빌드 → 부트 테스트 → SSH 테스트 → 기능 테스트 → 결과 보고
```

**로컬 테스팅**: `make test-vm-aarch64` → 빌드 → 부트 → 검증 → 보고

**CI 테스팅**: GitHub Action → 다중 아키텍처 → 병렬 테스팅 → 상태 보고

## 구현 세부사항

### Flake 확장

```nix
# flake.nix에 추가할 내용
nixosConfigurations = {
  nixos-vm-aarch64 = nixpkgs.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [
      ./machines/nixos-vm.nix
      ./users/baleen/nixos.nix
    ];
  };
};

# VM 자동화 패키지
packages.aarch64-linux.vm-automation = pkgs.callPackage ./packages/vm-automation {};
```

### Make 타겟

- `make test-vm-aarch64` - 로컬 VM 빌드 및 테스트
- `make test-vm-all` - 지원하는 모든 아키텍처 테스트
- `make test-vm-ci` - CI 특화 검증 스위트 실행

### CI 워크플로우

1. 다중 아키텍처용 VM 빌드
2. 자동화된 테스트 스위트 실행
3. 테스트 결과 및 아티팩트 업로드
4. 성능 벤치마크 대비 검증

## 테스트 전략

### 다단계 테스팅 접근

1. **단위 테스트**: 개별 Nix 모듈 동작 검증
2. **통합 테스트**: VM 부트 및 기본 기능 테스트
3. **엔드투엔드 테스트**: 실제 워크로드를 통한 전체 워크플로우 검증
4. **성능 테스트**: 부트 시간, 리소스 사용량, 응답성 측정

### 테스트 시나리오

- **부트 검증**: VM 시작, multi-user 타겟 도달
- **사용자 환경**: Home Manager 설정 올바른 적용
- **서비스 가용성**: Docker 데몬 실행, 사용자 docker 그룹 소속
- **네트워크 연결**: 인터넷 접속, 패키지 설치 가능
- **개발 도구**: Git, 에디터, 빌드 도구 정상 동작
- **크로스 플랫폼**: aarch64/x86_64, Linux/Darwin 간 일관성

## 오류 처리 및 복구

- **VM 부트 실패**: 콘솔 로그, 커널 패닉 정보 수집
- **SSH 연결 문제**: 재시도 로직, 네트워크 진단
- **테스트 실패**: 상세 로그, 아티팩트 수집
- **CI 타임아웃**: 적절한 에스컬레이션, 아티팩트 보존

## 성공 기준

- VM이 aarch64에서 성공적으로 부트
- 모든 핵심 서비스 정상 시작
- 사용자 설정 오류 없이 적용
- 개발 환경 완전히 기능
- CI 파이프라인 일관되게 통과
- 합리적인 시간 내 테스트 실행 완료

## 파일 구조

```
.
├── machines/
│   └── nixos-vm.nix          # VM 설정 (기존)
├── packages/
│   └── vm-automation/        # VM 자동화 도구 (신규)
├── tests/
│   ├── vm/                   # VM 테스트 스위트 (신규)
│   │   ├── boot-test.nix
│   │   ├── service-test.nix
│   │   └── integration-test.nix
│   └── e2e/                  # E2E 테스트 (기존 확장)
├── .github/
│   └── workflows/
│       └── vm-validation.yml # CI 워크플로우 (신규)
└── docs/
    └── plans/
        └── 2025-10-26-nixos-vm-validation-design.md # 본 문서
```

## 다음 단계

1. **VM 자동화 패키지 개발**: QEMU 관리, 테스트 실행 도구
2. **테스트 스위트 구현**: 부트, 서비스, 통합 테스트
3. **CI 워크플로우 설정**: GitHub Actions 자동화
4. **Make 타겟 추가**: 개발자 편의성 향상
5. **문서화**: 사용 가이드 및 문제 해결 절차

## 고려사항

- **리소스 사용**: VM 테스팅은 상당한 CPU/메모리 사용
- **타임아웃 관리**: 적절한 테스트 타임아웃 설정 필요
- **아티팩트 저장**: 테스트 로그 및 스크린샷 보존
- **병렬 실행**: 다중 아키텍처 테스팅 병렬화
- **보안**: VM 내에서의 테스트 실행 환경 격리
