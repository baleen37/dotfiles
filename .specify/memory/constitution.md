<!--
Sync Impact Report:
Version change: N/A → 1.0.0 (Initial constitution creation)
Added sections: All core principles and governance
Templates requiring updates:
✅ Updated: plan-template.md (constitution check references updated)
✅ Updated: spec-template.md (compatibility maintained)
✅ Updated: tasks-template.md (TDD alignment maintained)
Follow-up TODOs: None
-->

# Professional Nix Dotfiles System Constitution

## Core Principles

### I. 지속가능성 우선 (Sustainability First)

모든 설계 결정은 장기적 유지보수성과 확장성을 고려해야 합니다. 임시방편이나 기술적 부채를 생성하는 솔루션을 금지하며, 변경사항은 기존 설정을 보존하고 롤백 가능해야 합니다. 자동화된 업데이트 메커니즘을 통해 수동 개입을 최소화하고, 설정 변경 시 충돌 해결 도구를 제공해야 합니다.

### II. 모듈화 아키텍처 (Modular Architecture)

시스템은 사용자 중심의 Mitchell-style 구조(`users/{user}/`)로 조직되어야 합니다. 각 사용자 설정은 플랫폼별 파일(`darwin.nix`, `nixos.nix`)과 프로그램별 설정(`programs/`)으로 구성됩니다. 모듈은 단일 책임을 가지며 독립적으로 테스트 가능해야 합니다. 모듈 간 의존성은 명시적으로 선언되어야 하며, 순환 의존성을 금지합니다. 새로운 기능은 기존 설정을 확장하거나 새 프로그램 파일을 생성하여 구현해야 합니다.

### III. Nix 베스트 프랙티스 (Nix Best Practices)

Nix 플레이크와 Home Manager의 공식 가이드라인을 엄격히 준수해야 합니다. 모든 패키지와 설정은 선언적으로 정의되어야 하며, 명령형 설치나 수정을 금지합니다. 입력값은 고정되어야 하고(flake.lock), 빌드는 재현 가능해야 합니다. 사용자 정의 오버레이는 `overlays/` 디렉토리에서 관리되며, 업스트림 기여를 우선적으로 고려해야 합니다.

### IV. 크로스플랫폼 호환성 (Cross-Platform Compatibility)

macOS(Intel + Apple Silicon)와 NixOS(x86_64 + ARM64)에서 핵심 기능이 완전히 동작해야 합니다. 플랫폼별 차이점은 조건부 설정으로 처리되어야 하며, 공통 기능은 `users/{user}/programs/`에서 구현되어야 합니다. 새로운 기능 추가 시 모든 지원 플랫폼에서 테스트되어야 하며, 플랫폼별 제한사항은 명확히 문서화되어야 합니다.

### V. 테스트 주도 품질 (Test-Driven Quality)

시스템은 90% 이상의 테스트 커버리지를 유지해야 하며, 단위 테스트, 통합 테스트, E2E 테스트를 포함해야 합니다. 모든 새로운 기능은 TDD(Test-Driven Development) 방식으로 개발되어야 하며, 실패하는 테스트를 먼저 작성한 후 구현해야 합니다. 성능 테스트와 메모리 사용량 모니터링을 통해 시스템 성능을 지속적으로 검증해야 합니다.

## 기술 표준 (Technical Standards)

Nix 생태계의 안정성과 보안을 보장하기 위해 다음 기술 요구사항을 준수해야 합니다:

- **Nix 버전**: 최신 stable 버전 사용, experimental features는 명시적 승인 후에만 사용
- **보안**: 모든 패키지는 SHA256 해시로 검증되며, 신뢰할 수 없는 소스 금지
- **성능**: 빌드 시간 최적화를 위한 병렬 처리와 캐싱 전략 적용
- **문서화**: 모든 모듈과 설정은 목적과 사용법이 명확히 문서화되어야 함
- **호환성**: nixpkgs unstable 브랜치 기반, 정기적인 flake.lock 업데이트

## 개발 워크플로우 (Development Workflow)

품질 보증과 협업 효율성을 위해 다음 개발 프로세스를 따라야 합니다:

- **TDD 원칙**: 모든 변경사항은 테스트 작성 → 실패 확인 → 구현 → 성공 확인 순서로 진행
- **코드 리뷰**: 모든 PR은 헌법 준수 여부를 검증받아야 하며, 최소 1명의 승인 필요
- **CI/CD**: GitHub Actions를 통한 자동화된 테스트, 빌드, 품질 검사 실행
- **버전 관리**: 의미론적 버전 관리(Semantic Versioning) 사용, 호환성 변경 시 명확한 마이그레이션 가이드 제공
- **문서 동기화**: 코드 변경 시 관련 문서 자동 업데이트 또는 수동 검토

## Governance

이 헌법은 모든 개발 관행과 의사결정에 우선합니다. 헌법 수정은 영향도 분석, 커뮤니티 논의, 마이그레이션 계획을 포함해야 합니다. 모든 PR과 코드 리뷰는 헌법 준수를 확인해야 하며, 복잡성 증가는 명확한 비즈니스 가치로 정당화되어야 합니다. 런타임 개발 가이드는 `CLAUDE.md`와 `CONTRIBUTING.md`에서 제공됩니다.

**Version**: 1.0.0 | **Ratified**: 2025-09-30 | **Last Amended**: 2025-09-30
