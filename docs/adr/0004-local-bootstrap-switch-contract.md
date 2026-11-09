# ADR 0004: 로컬 설치·적용 명령과 키 요구를 단순화한다

- 상태: 채택
- 날짜: 2026-11-09
- 결정·운영 책임자: dotfiles 관리자
- 대체 범위: ADR 0002의 CLI 옵션과 시크릿 검사 정책

## 결정

공개 실행 방법은 `./bootstrap.sh`, `./switch.sh`, `./switch.sh --build`다.
로컬 호스트는 `hostname -s`로 선택한다. 호스트 인자, `--home`, 시크릿 생략
옵션과 키 경로·참조 CLI 옵션은 제공하지 않는다. 원격 VM용 Make 타겟의
`NIXNAME`은 별도다.

Bootstrap은 도구와 유효한 age identity를 준비하고 활성화하지 않는다.
`DOTFILES_AGE_KEY_REF` 환경 변수로 1Password 참조를 지정할 수 있다.
정상 switch는 선언된 시크릿이 없어도 유효한 identity를 요구한다.
Switch는 키를 가져오지 않으며, 준비가 부족하면 bootstrap을 안내하고 중단한다.

Linux에서 NixOS와 Debian 외의 환경은 standalone Home Manager를 자동 선택한다.
`HM_USER`는 해당 프로필만 선택한다. Debian은 bootstrap에서 네이티브 패키지와
키를 준비하고 switch에서 시크릿과 서비스를 적용한다. Debian identity 경로는
`SOPS_AGE_KEY_FILE`로 지정할 수 있다.

`--build`는 키와 복호화 검사 없이 검증한다. Nix 플랫폼은 빌드만 수행하고,
Debian은 선언만 검증한다. 어느 쪽도 설치·키 복원·서비스 적용을 수행하지 않는다.

## 이유와 검증

생략 옵션이나 로컬 키 자동 감지로 적용 구성이 달라지는 경로를 줄인다.
키 복원은 bootstrap에만 두고, 반복 적용은 동일한 준비 조건을 요구한다.

알 수 없는 인자 거부, hostname 자동 선택, 키 없는 정상 switch 거부,
키 없는 build-only 성공, Debian 준비·적용 분리를 검증한다.
