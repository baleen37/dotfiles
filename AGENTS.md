# AGENTS Guide

이 저장소는 **Codex agent**를 활용해 자동화된 작업을 수행합니다. 아래 가이드라인은 agent나 기여자가 참고할 수 있는 기본 규칙을 정리한 것입니다.

## Agent 역할
- PR 생성 및 병합
- Nix flake 환경의 테스트 실행
- 문서 갱신

## 기본 원칙
1. **테스트 실행**: Nix 관련 파일을 수정하면 GitHub Actions에서 수행하는 테스트와 동일한 절차를 로컬에서도 실행합니다. 자세한 단계는 아래 "GitHub CI 테스트" 절을 참고하세요.
2. **문서 업데이트**: 주요 설정이나 구조가 바뀌면 반드시 README.md와 관련 문서를 최신 상태로 갱신합니다.
3. **커밋 규칙**: 의미 있는 단위로 커밋하며 커밋 메시지는 영어로 간결하게 작성합니다.

## 개발자 참고
- AGENTS.md는 추후 agent에게 전달할 추가 규칙이나 팁을 기록하는 곳입니다.
- 특별한 지시가 없으면 기본적으로 위 규칙을 따라 작업합니다.

## 문서 관리
- 이 저장소에서 제공하는 주요 지침은 README.md와 AGENTS.md 두 파일에서 관리합니다.
- 새 규칙이나 가이드를 작성할 때는 AGENTS.md를 수정해 내용이 흩어지지 않도록 합니다.

## 추가 가이드라인
- Nix 파일을 수정한 후에는 `pre-commit run --files <경로>`로 변경 사항을 검증합니다.
- 첫 사용 시 `pre-commit install`을 실행해 Git hook을 설치합니다.
- PR 메시지에는 **Summary**와 **Testing** 섹션을 포함해 어떤 수정이 있었는지와 확인 절차를 명시합니다.
- 새 모듈을 추가할 경우 `modules/` 하위 구조를 따르고, 관련 문서도 함께 갱신합니다.
- 커밋 메시지는 명령형 현재 시제로 작성하며 필요 시 관련 이슈 번호를 본문에 포함합니다.

## 코드 작성 가이드
- Nix 코드와 스크립트는 최대한 모듈화해 재사용성을 높입니다.
- 불필요한 의존성 추가를 피하고 명확한 주석을 남깁니다.
- 디렉터리 구조는 apps/, hosts/, modules/, overlays/ 네 영역을 중심으로 유지합니다.
- 공통 기능은 modules/shared/에 두고 플랫폼 전용 내용은 각 플랫폼 디렉터리에 배치합니다.
- 파일명과 옵션 이름은 소문자-hyphen 스타일로 작성합니다.
- **코드 수정 후에는 반드시 테스트를 실행합니다.**
  - `nix flake check --no-build`
  - 필요한 경우 `pre-commit run --files <경로>`

## Agent 테스트
- 문서나 설정 변경 후 `pre-commit run --all-files`로 전체 검사를 수행합니다.
- Nix 환경 통합을 확인하려면 `nix flake check --all-systems --no-build`를 실행합니다.

## GitHub CI 테스트
agent는 변경 사항이 Nix flake에 영향을 줄 경우 다음 절차를 수행해 CI와 동일한 검증을 선행합니다.

1. **Lint**: `pre-commit run --all-files`를 실행합니다.
2. **Smoke test**: 아래 네 가지 시스템을 대상으로 `nix flake check --system <SYSTEM> --no-build`을 수행합니다.
   - `x86_64-linux`
   - `aarch64-linux`
   - `x86_64-darwin`
   - `aarch64-darwin`
3. **Build test**: 각 시스템별 빌드가 필요한 경우 다음 명령을 실행합니다.
   - `nix build --no-link ".#nixosConfigurations.x86_64-linux.config.system.build.toplevel"`
   - `nix build --no-link ".#nixosConfigurations.aarch64-linux.config.system.build.toplevel"`
   - `nix build --no-link ".#darwinConfigurations.x86_64-darwin.system"`
   - `nix build --no-link ".#darwinConfigurations.aarch64-darwin.system"`
4. **최종 확인**: 빌드 후 다시 한 번 각 시스템에서 `nix flake check --system <SYSTEM> --no-build`을 실행합니다.
