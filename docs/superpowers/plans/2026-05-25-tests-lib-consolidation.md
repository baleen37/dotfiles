# Sub-project 4: `tests/lib/` 헬퍼 정리 — 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `tests/lib/` 22개 파일 중 명백한 중복 페어를 단일 파일로 머지하고, import 0건인 unused 파일을 삭제한다. 도메인별 헬퍼(`*-test-helpers.nix`)는 보존. 동작은 1mm도 변화 없음.

**Architecture:** 실증 기반 정리 — inventory 단계에서 모든 파일의 export 함수와 import 사용처를 매핑한 후 결정. 추측 삭제 금지. 머지는 "이름만 다른 페어"(`assertions` ↔ `common-assertions`, `test-helpers` ↔ `test-helpers-advanced`, `test-helpers-property` ↔ `property-test-helpers`) 우선.

**Tech Stack:** Bash (`grep`, `find`), Nix.

**Spec:** `docs/superpowers/specs/2026-05-25-home-manager-module-options-design.md` — Sub-project 4

---

## 파일 구조

| 경로                                                                | 책임                                        | 변경 종류      |
| ------------------------------------------------------------------- | ------------------------------------------- | -------------- |
| `docs/notes/2026-05-25-tests-lib-inventory.md`                      | Inventory 표 (PR description 자료)          | 신규           |
| `tests/lib/assertions.nix`                                          | 머지 대상 (common-assertions 흡수)          | 수정 또는 유지 |
| `tests/lib/common-assertions.nix`                                   | 머지 후 삭제 후보                           | 삭제 또는 유지 |
| `tests/lib/test-helpers.nix`                                        | 머지 대상 (test-helpers-advanced 흡수 후보) | 수정 또는 유지 |
| `tests/lib/test-helpers-advanced.nix`                               | 머지 후 삭제 후보                           | 삭제 또는 유지 |
| `tests/lib/test-helpers-property.nix` ↔ `property-test-helpers.nix` | 머지 페어                                   | 한쪽 삭제      |
| 영향받는 `tests/{unit,integration}/*-test.nix`                      | import 경로 업데이트                        | 수정           |

> "수정 또는 유지"가 많은 이유: inventory(Task 1) 결과에 따라 결정. 추측 금지.

### Task 1: Inventory — 모든 헬퍼의 export와 사용처 매핑

이 task의 산출물(`docs/notes/2026-05-25-tests-lib-inventory.md`)이 이후 모든 결정의 근거가 된다. **이 표 없이 어떤 파일도 삭제·머지하지 않는다.**

**Files:** Create: `docs/notes/2026-05-25-tests-lib-inventory.md`

- [ ] **Step 1: 모든 `tests/lib/*.nix`의 최상위 attr 추출**

```bash
mkdir -p docs/notes
for f in tests/lib/*.nix; do
  echo "=== $f ==="
  # 최상위 attribute set의 키들 (들여쓰기 한 줄 끝의 ` = `)
  grep -nE "^[[:space:]]{2,4}[a-zA-Z][a-zA-Z0-9_-]*[[:space:]]*=" "$f" | head -40
done > /tmp/tests-lib-exports.txt
cat /tmp/tests-lib-exports.txt | head -100
```

> grep 패턴은 휴리스틱이다. let 안의 바인딩도 잡힐 수 있다. 다음 단계의 사용처 grep과 교차 검증으로 보완.

- [ ] **Step 2: 각 헬퍼 파일이 다른 곳에서 import 되는지 grep**

```bash
for f in tests/lib/*.nix; do
  base="$(basename "$f" .nix)"
  count=$(grep -rln "lib/${base}\b\|lib/${base}\.nix" tests/ --include="*.nix" 2>/dev/null | grep -v "tests/lib/${base}.nix" | wc -l | tr -d ' ')
  echo "${count}\t${f}"
done | sort -n
```

> 결과: import 카운트가 0인 파일들이 unused 후보. 1~2인 파일은 사용처 검토. 많이 쓰이는 파일은 보존.

- [ ] **Step 3: 동일/유사 함수 이름 페어 매핑**

세 가지 의심 페어를 검증:

```bash
echo "--- assertions vs common-assertions ---"
grep -nE "^[[:space:]]+[a-zA-Z][a-zA-Z0-9_-]*[[:space:]]*=" tests/lib/assertions.nix tests/lib/common-assertions.nix | sed 's/^.*://; s/=.*//' | sort -u

echo "--- test-helpers vs test-helpers-advanced ---"
grep -nE "^[[:space:]]+[a-zA-Z][a-zA-Z0-9_-]*[[:space:]]*=" tests/lib/test-helpers.nix tests/lib/test-helpers-advanced.nix | sed 's/^.*://; s/=.*//' | sort -u

echo "--- test-helpers-property vs property-test-helpers ---"
grep -nE "^[[:space:]]+[a-zA-Z][a-zA-Z0-9_-]*[[:space:]]*=" tests/lib/test-helpers-property.nix tests/lib/property-test-helpers.nix | sed 's/^.*://; s/=.*//' | sort -u
```

각 페어에서 같은 이름의 함수가 양쪽 다 정의되어 있다면 **명백한 중복**.

- [ ] **Step 4: inventory 문서 작성**

다음 형식의 마크다운 작성:

```markdown
# tests/lib/ Inventory — 2026-05-25

> Sub-project 4 (tests-lib-consolidation) 작업을 위한 사실 조사. PR description에 첨부.

## 파일 목록 (22개)

| 파일                      | import 카운트 | export 핵심 함수                | 결정                             | 비고 |
| ------------------------- | ------------- | ------------------------------- | -------------------------------- | ---- |
| assertions.nix            | N             | assertEq, assertTrue, …         | 머지 → assertions.nix            |      |
| common-assertions.nix     | N             | (같은 이름들)                   | 삭제 (assertions.nix로 통합)     |      |
| test-helpers.nix          | N             | assertTest, assertFileExists, … | 보존                             |      |
| test-helpers-advanced.nix | N             | …                               | 머지 또는 보존 (Task 2에서 결정) |      |
| test-helpers-property.nix | N             | …                               | …                                |      |
| property-test-helpers.nix | N             | …                               | …                                |      |
| patterns.nix              | N             | …                               | 보존/삭제                        |      |
| conventions.nix           | N             | …                               | 보존/삭제                        |      |
| test-builders.nix         | N             | …                               | 보존/삭제                        |      |
| test-runner.nix           | N             | …                               | 보존 (자동 발견 핵심)            |      |
| performance.nix           | N             | …                               | 보존                             |      |
| performance-baselines.nix | N             | …                               | 보존                             |      |
| constants.nix             | N             | …                               | 보존                             |      |
| mock-config.nix           | N             | …                               | 보존                             |      |
| platform-helpers.nix      | N             | …                               | 보존 (이미 사용)                 |      |
| e2e-helpers.nix           | N             | …                               | 보존/삭제                        |      |
| fixtures/                 | N             | (디렉토리)                      | 보존                             |      |
| claude-test-helpers.nix   | N             | …                               | 보존 (도메인)                    |      |
| darwin-test-helpers.nix   | N             | …                               | 보존 (도메인)                    |      |
| git-test-helpers.nix      | N             | …                               | 보존 (도메인)                    |      |
| plugin-test-helpers.nix   | N             | …                               | 보존 (도메인)                    |      |
| starship-test-helpers.nix | N             | …                               | 보존 (도메인)                    |      |

## 머지 페어

| Pair                                          | 머지 방향            | 함수 충돌                         | 처리 |
| --------------------------------------------- | -------------------- | --------------------------------- | ---- |
| assertions ↔ common-assertions                | A ← B (B를 A로 흡수) | (없음 / 있다면 어떻게 해소했는지) |      |
| test-helpers ↔ test-helpers-advanced          | …                    | …                                 |      |
| test-helpers-property ↔ property-test-helpers | …                    | …                                 |      |

## 삭제 후보 (import 0)

(파일 목록 + 마지막 사용 추정)

## 사용처 표 (import count > 0인 헬퍼들의 사용처)

(헬퍼 → 사용하는 테스트 파일들)
```

> 위 표는 실제 grep/inventory 결과로 채운다. 단정 N자리는 실제 수치로.

- [ ] **Step 5: Commit inventory**

```bash
git add docs/notes/2026-05-25-tests-lib-inventory.md
git commit -m "docs(tests): inventory tests/lib/ helpers for consolidation"
```

### Task 2: assertions ↔ common-assertions 머지

inventory 결과에 따라 머지 방향 결정. 일반적으로 "더 많이 사용되는 쪽" 또는 "이름이 더 일반적인 쪽"이 살아남는다. 여기서는 `assertions.nix`가 더 짧고 직관적이므로 이쪽으로 흡수한다 (Task 1에서 다른 결론이 나오면 그쪽 따름).

**Files:**

- Modify: `tests/lib/assertions.nix`
- Delete: `tests/lib/common-assertions.nix`
- Modify: 영향받는 `tests/{unit,integration}/*-test.nix` (inventory에서 식별)

- [ ] **Step 1: 두 파일 내용 비교**

```bash
diff -u tests/lib/assertions.nix tests/lib/common-assertions.nix | head -80
```

- [ ] **Step 2: common-assertions의 unique 함수를 assertions.nix로 복사**

inventory의 "함수 충돌" 항목을 참조. 충돌 없는 함수만 추가. 동일 이름 충돌이 있다면:

- 함수 body가 정확히 같음 → 그냥 한쪽 사용
- 다름 → inventory에서 결정한 "정답" 쪽 채택, 다른 쪽 사용처는 Task 2 Step 4에서 마이그레이트

- [ ] **Step 3: common-assertions.nix 삭제**

```bash
git rm tests/lib/common-assertions.nix
```

- [ ] **Step 4: common-assertions를 import하던 테스트 파일들의 경로 업데이트**

inventory의 "사용처 표"에서 `common-assertions`를 import하던 파일들을 식별. 각 파일에서:

```nix
# Before
import ../lib/common-assertions.nix { inherit pkgs lib; }

# After
import ../lib/assertions.nix { inherit pkgs lib; }
```

`grep -rln "lib/common-assertions" tests/` 명령으로 잔존 import 0건 확인.

- [ ] **Step 5: 테스트 실행 — 동작 동일**

```bash
make test
```

Expected: pass 카운트 변화 없음 (이전과 동일).

- [ ] **Step 6: Commit**

```bash
git add tests/lib/assertions.nix tests/unit/ tests/integration/
git rm tests/lib/common-assertions.nix 2>/dev/null || true
git commit -m "refactor(tests): merge common-assertions into assertions"
```

### Task 3: test-helpers ↔ test-helpers-advanced 머지

inventory에서 두 파일의 함수 중복도와 사용 빈도를 확인한 결과에 따라:

- 거의 중복 → 머지 (이 task 진행)
- 명확히 다른 책임 → 머지 스킵, 이 task를 No-op으로 닫고 commit 없이 다음 task로

**Files (머지 진행 시):**

- Modify: `tests/lib/test-helpers.nix`
- Delete: `tests/lib/test-helpers-advanced.nix`
- Modify: 영향받는 테스트 파일들

- [ ] **Step 1: inventory 결과 확인**

```bash
grep -A1 "test-helpers ↔ test-helpers-advanced" docs/notes/2026-05-25-tests-lib-inventory.md
```

inventory 결정이 "머지 스킵"이면 이 task의 나머지 step을 건너뛴다.

- [ ] **Step 2: 머지 진행 시 — advanced의 unique 함수를 test-helpers.nix로 흡수**

Task 2 Step 2와 동일 패턴.

- [ ] **Step 3: 파일 삭제 + import 경로 업데이트**

```bash
git rm tests/lib/test-helpers-advanced.nix
grep -rln "lib/test-helpers-advanced" tests/ | while read f; do
  # 각 파일에서 import 경로 수정
  echo "Updating $f"
done
```

`tests/{unit,integration}/*-test.nix` 중 `test-helpers-advanced`를 import 하던 파일들의 import 경로를 `test-helpers`로 통합.

- [ ] **Step 4: 테스트 통과 확인**

```bash
make test
```

Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add tests/
git commit -m "refactor(tests): merge test-helpers-advanced into test-helpers"
```

### Task 4: test-helpers-property ↔ property-test-helpers 머지

inventory의 페어 결과에 따라 진행 또는 스킵. 둘 중 살아남을 이름은 더 자주 사용되는 쪽 (혹은 더 짧은 쪽).

**Files (머지 진행 시):**

- Modify: 살아남는 파일 (예: `tests/lib/property-test-helpers.nix`)
- Delete: 다른 한쪽
- Modify: 영향받는 테스트 파일들

- [ ] **Step 1: inventory 결과 확인 + 머지 방향 결정**

```bash
grep -A1 "test-helpers-property ↔ property-test-helpers" docs/notes/2026-05-25-tests-lib-inventory.md
```

- [ ] **Step 2: 머지 (Task 2/3과 동일 패턴)**

- [ ] **Step 3: import 경로 업데이트 + 삭제 파일 제거**

- [ ] **Step 4: 테스트 통과 확인**

```bash
make test
```

Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add tests/
git commit -m "refactor(tests): merge property test helper duplicates"
```

### Task 5: import 0건 파일 삭제

inventory의 "삭제 후보" 섹션에 있는 파일들. 각 파일에 대해:

**Files:** Delete: (inventory에서 식별된 파일들)

- [ ] **Step 1: inventory의 삭제 후보 확인**

```bash
grep -A20 "## 삭제 후보" docs/notes/2026-05-25-tests-lib-inventory.md
```

- [ ] **Step 2: 각 후보 파일에 대해 정말 import 0건인지 재검증**

```bash
# 후보 파일 이름 예: foo.nix
candidate="foo"
grep -rln "lib/${candidate}\b\|lib/${candidate}\.nix" tests/ --include="*.nix" | grep -v "tests/lib/${candidate}.nix"
```

Expected: 결과 없음. **결과가 있으면 삭제 금지** — inventory가 틀린 것. 보존 결정으로 변경.

- [ ] **Step 3: 삭제**

```bash
git rm tests/lib/<candidate>.nix
```

- [ ] **Step 4: 테스트 통과 확인**

```bash
make test
```

Expected: pass.

- [ ] **Step 5: Commit (후보 파일 1개당 1커밋 또는 묶어서 1커밋, inventory 결정 따름)**

```bash
git commit -m "refactor(tests): remove unused tests/lib/<name>.nix"
```

> 후보가 0개라면 이 task는 No-op. 그래도 OK — Task 2~4의 머지만으로도 정리 효과 충분.

### Task 6: 최종 검증

**Files:** (검증만)

- [ ] **Step 1: 헬퍼 파일 수 비교**

```bash
ls tests/lib/*.nix | wc -l
```

Expected: 22보다 작음 (정확한 수는 Task 1 inventory에 따라 결정됨).

- [ ] **Step 2: 잔존 import 0건 확인**

```bash
for f in tests/lib/*.nix; do
  base="$(basename "$f" .nix)"
  count=$(grep -rln "lib/${base}" tests/ --include="*.nix" 2>/dev/null | grep -v "tests/lib/${base}.nix" | wc -l | tr -d ' ')
  if [ "$count" = "0" ]; then
    echo "STILL UNUSED: $f"
  fi
done
```

Expected: STILL UNUSED 로그가 없거나, 있더라도 inventory에서 "보존" 결정된 파일만.

- [ ] **Step 3: make test 통과**

```bash
make test
```

Expected: pass.

- [ ] **Step 4: 전체 flake check**

```bash
export USER=$(whoami)
nix flake check --impure 2>&1 | tail -15
```

Expected: error 없음.

- [ ] **Step 5: 정리 전후 비교 메모**

inventory 문서 끝부분에 "Outcome" 섹션 추가:

```markdown
## Outcome (정리 후)

- 파일: 22 → N
- 머지: A개 페어
- 삭제: B개
- 동작 변화: 0 (`make test` pass/fail 카운트 동일)
```

- [ ] **Step 6: Commit**

```bash
git add docs/notes/2026-05-25-tests-lib-inventory.md
git commit -m "docs(tests): record outcome of tests/lib/ consolidation"
```

---

## Self-Review

**Spec coverage:**

- 실증 기반 inventory ✓ (Task 1)
- 머지 우선 페어 정리 ✓ (Task 2, 3, 4)
- import 0건 파일 삭제 ✓ (Task 5)
- 동작 보존 검증 ✓ (Task 6)
- 도메인 헬퍼 보존 ✓ (inventory에서 결정)
- PR description용 inventory 첨부 ✓ (Task 1, 6)

**Placeholder scan:** "수정 또는 유지"/"머지 또는 보존" 표현이 있지만 이는 *Task 1의 inventory 결과에 따라 분기*하는 설계상의 명시적 분기점이지 placeholder가 아님. 각 task가 "inventory 결정에 따라 진행/스킵"을 명확히 지시. ✓

**Type 일관성:** N/A (이 plan은 코드 타입 시그니처를 다루지 않음). 파일명 일관성만 점검: `assertions.nix`, `test-helpers.nix`, `property-test-helpers.nix` (머지 살아남는 쪽 이름) ✓.

**알려진 위험:**

1. Task 1의 grep 휴리스틱이 let-binding을 export로 잘못 인식할 수 있다. inventory 표는 자동 생성이 아니라 사람이 검토 후 작성한다.
2. Task 2~4의 머지 방향이 inventory에 의존한다. 잘못된 inventory는 잘못된 머지로 이어진다. 의심스러우면 보존 결정.
3. Task 5의 삭제는 git history에서 회수 가능하므로 위험은 낮으나, CI에서만 쓰이는 헬퍼가 grep에 안 잡힐 수 있음 — make test와 nix flake check 둘 다 통과해야 진짜 안전.
