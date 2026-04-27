# Cache Audit & Hit-rate Visibility — Design

- **Date**: 2026-04-27
- **Branch**: `feat/cache`
- **Status**: approved by user, ready for implementation plan

## 1. Goals & Non-goals

### Goals
1. **가시성** — CI에서 빌드마다 캐시 hit/miss/적중률이 GitHub Actions Job Summary에 표시된다.
2. **회귀 방지** — substituter / public key 설정이 4곳에서 어긋나거나 형식이 깨지면 CI에서 잡힌다.
3. **운영 안전성** — hit-rate가 낮아도 CI는 실패하지 않는다 (경고 없음, 표시만). 무관한 PR이 캐시 변동으로 깨지지 않는다.
4. **유지보수성** — 추가 의존성 없음 (`nix`, `bash`만). 코드는 "있어야만 하는 것"만.

### Non-goals (YAGNI)
- 로컬 `make cache-report` 명령
- hit-rate 시계열 저장 / 대시보드
- `flake.nix` ↔ `lib/cache-config.nix` 자동 동기화 스크립트
- 새 substituter 추가 / Cachix 외 캐시 백엔드
- Eval cache / lazy-trees 등 Nix 성능 튜닝
- 캐시 외 영역(zsh, direnv 등)의 캐싱

### Success criteria
- CI Job Summary에 `Cache hit-rate (<matrix name>)` 섹션이 표시되고, total / hit / miss 수가 보인다.
- `nix flake check --impure` 시 `cache-config-test`가 실행된다.
- `lib/cache-config.nix`에서 substituter 하나를 임의로 삭제하면 테스트가 실패한다.

## 2. Current state

| 항목 | 상태 |
|---|---|
| Substituter 3단 구성 (baleen-nix → nix-community → official) | ✅ `lib/cache-config.nix` |
| CI Cachix push (main / tag) | ✅ `continue-on-error` |
| CI 로컬 Nix store 캐시 | ✅ `actions/cache` + `flake.lock` 해시 키 |
| 동일 substituter / key 설정이 4곳에 하드코딩 | ⚠️ `flake.nix nixConfig`, `lib/cache-config.nix`, `ci.yml env.NIX_CONFIG`, `setup-nix/action.yml extra-conf` |
| 캐시 hit/miss 가시성 | ❌ |
| 캐시 설정 회귀 방지 테스트 | ❌ |

`flake.nix nixConfig`는 top-level attrset이므로 `import`가 불가능하다 → 4곳을 코드 레벨로 통합할 수 없다. 따라서 *일치성 검증*으로 대체한다.

## 3. Architecture

```
┌─────────────────────────────────────────────────────────┐
│ 1. cache-config 일치성 테스트 (Nix)                     │
│    tests/unit/cache-config-test.nix                     │
│    - lib/cache-config.nix 를 읽고                       │
│    - flake.nix, ci.yml, setup-nix/action.yml 에         │
│      같은 substituter / key 가 등장하는지 검증          │
│    - URL / public key 형식 검증                         │
└─────────────────────────────────────────────────────────┘
              ↑
              └─ nix flake check --impure / make test 로 실행

┌─────────────────────────────────────────────────────────┐
│ 2. CI hit-rate report (yaml only)                       │
│    .github/workflows/ci.yml 안의 step                   │
│    - nix path-info -r ./result | wc -l → total          │
│    - nix copy --to <cachix> --dry-run ./result          │
│      → "would copy N paths" → miss                      │
│    - hit = total - miss                                 │
│    - $GITHUB_STEP_SUMMARY 에 표 형식으로 기록           │
└─────────────────────────────────────────────────────────┘
```

자작 bash 스크립트 / 외부 도구 없음. 모두 표준 Nix 명령(`nix path-info`, `nix copy --dry-run`)을 사용.

## 4. Component 1 — 일치성 테스트

**파일**: `tests/unit/cache-config-test.nix` (신규)

검증 항목:
1. `lib/cache-config.nix`의 모든 `substituters`가 `flake.nix`에 등장
2. 동일 항목이 `.github/workflows/ci.yml`에 등장
3. 동일 항목이 `.github/actions/setup-nix/action.yml`에 등장
4. `trusted-public-keys`도 위 3곳에 동일하게 등장
5. 각 substituter URL이 `https://`로 시작
6. 각 public key가 `<name>-<digit>:<base64-43chars>=` 형식

구현은 `builtins.readFile` + `lib.hasInfix` + `builtins.match` 만으로 처리한다 (외부 의존성 0, 결정적 평가, 네트워크 / 환경변수에 의존하지 않음).

`tests/default.nix`는 `tests/unit/*-test.nix`를 자동 발견하므로 추가 배선 없음.

### 거부한 대안
- *YAML 파서로 ci.yml 파싱*: 정확하지만 외부 의존성. `hasInfix` 검사로 충분 (substituter URL은 unique).
- *4개 파일을 한 nix 파일이 generate*: 자동 동기화. 메타프로그래밍 부채가 더 큼.

### 회귀 시나리오 (구현 후 수동 검증)
- `lib/cache-config.nix`에서 `nix-community.cachix.org` 줄 삭제 → 일치성 테스트 3개 (flake / ci / setup-nix) 실패해야 함
- public key 끝 `=` 제거 → 형식 검증 실패해야 함
- substituter URL을 `http://`로 변경 → URL 검증 실패해야 함

## 5. Component 2 — CI hit-rate report

**파일**: `.github/workflows/ci.yml` (수정)

### 변경 1 — 기존 "Upload to Cachix" step
`nix build` 호출에 `--out-link result` 를 추가해 `./result` 심볼릭 링크가 남도록 한다. push 동작에는 영향이 없다.

### 변경 2 — 신규 step "Cache hit-rate report"
기존 `Upload to Cachix` step **직전**에 추가한다 (직전 push step의 `nix build`가 `./result`를 만들어 둔 직후 시점).

```yaml
- name: Cache hit-rate report
  if: always()
  continue-on-error: true
  shell: bash
  run: |
    set -uo pipefail
    OUT=$(readlink -f result 2>/dev/null || echo "")
    [ -z "$OUT" ] && exit 0

    TOTAL=$(nix path-info -r "$OUT" | wc -l | tr -d ' ')
    MISS=$(nix copy --to https://baleen-nix.cachix.org --dry-run "$OUT" 2>&1 \
           | grep -oE 'would copy [0-9]+' | grep -oE '[0-9]+' | head -1)
    MISS=${MISS:-0}
    HIT=$(( TOTAL - MISS ))

    {
      echo "### Cache hit-rate (${{ matrix.name }})"
      echo "- total: $TOTAL"
      echo "- hit:   $HIT"
      echo "- miss:  $MISS"
    } >> "$GITHUB_STEP_SUMMARY"
```

### 설계 결정
- **`continue-on-error: true`**: 측정 실패가 CI 빌드를 깨뜨리지 않는다.
- **임계치 / 자동 경고 없음**: 숫자는 사람이 Job Summary에서 본다. false positive 부담 회피.
- **`nix copy --dry-run` 출력 파싱**: nix major 버전이 문구를 바꾸면 MISS=0으로 폴백된다. summary에 total 숫자가 그대로 보여 이상함을 인지 가능 (조용한 실패 X).
- **matrix attr 분기 없음**: 직전 push step에서 이미 만든 `./result`를 그대로 사용.

### 알려진 깨지기 쉬운 지점 (정직하게)
1. `nix copy --dry-run` 출력 문구 변경 — Nix 메이저 업데이트 시 점검 필요.
2. push step 변경 시 `--out-link result`가 사라지면 hit-rate step은 조용히 스킵된다 (Summary에 섹션이 안 찍힘).

## 6. 작업 단계

```
단계 1: 일치성 테스트 추가
  → tests/unit/cache-config-test.nix 작성
  검증: nix flake check --impure 통과
  검증: lib/cache-config.nix 임시 수정 시 fail (롤백 후 다시 pass)

단계 2: CI hit-rate report 통합
  → .github/workflows/ci.yml 수정
    - Upload to Cachix step nix build 에 --out-link result 추가
    - 직전에 Cache hit-rate report step 추가
  검증: PR Actions 에서 모든 matrix job 의 Summary 에 표 표시
  검증: TOTAL > 0, HIT + MISS == TOTAL

단계 3: 의도적 실패로 회귀 방지 확인 (throwaway 브랜치, 머지 X)
  a) substituter 1줄 삭제 → CI 실패해야 함
  b) public key 끝 '=' 제거 → CI 실패해야 함
  c) substituter URL 을 http:// 로 변경 → CI 실패해야 함
```

단계 1, 2 는 한 PR로 묶는다. 단계 3은 머지 X — 검증 결과만 PR description 에 기록.

## 7. 롤백

- 단계 1 revert: `tests/unit/cache-config-test.nix` 삭제. 다른 영향 없음.
- 단계 2 revert: `ci.yml`의 두 변경 되돌림. 빌드 / 캐시 자체 동작에는 영향 없음 (측정 step만 사라짐).

## 8. 위험 및 완화

| 위험 | 완화 |
|---|---|
| `nix copy --dry-run` 출력 포맷 변동 | `continue-on-error: true`. Summary에 MISS=0으로 표시되어 사람이 인지 |
| matrix 별 `./result` 충돌 | 각 matrix는 독립 runner |
| 일치성 테스트의 false positive (주석에 우연히 같은 URL) | 검증 목적은 "빠짐 방지"이므로 "있어서 통과"는 의도된 동작 |
