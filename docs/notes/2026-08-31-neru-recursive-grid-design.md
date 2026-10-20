# Neru recursive grid 디자인 리서치

- 조사일: 2026-08-31
- 대상: macOS의 Neru `recursive_grid`, v1.51.0
- 범위: 현재 설정의 가독성·시각적 계층·키보드 흐름 개선
- 상태: P0 설정을 적용했다. 색상 역할 분리와 실제 사용자 테스트는 아직 보류했다.

## 결론

가장 안전한 1차 개선은 위치 선택 구조를 바꾸지 않고 오버레이의 정보 계층을 강화하는 것이다.

1. 현재 `3 x 3`과 `rtyfghvbn` 키 배열을 유지한다.
2. 셀 라벨의 둥근 배경을 켜서 앱 콘텐츠 위에서도 주 라벨을 읽기 쉽게 한다.
3. `sub_key_preview`를 켜서 다음 단계의 키를 미리 보여준다.
4. 주 라벨은 현재 테마의 `text`, 다음 단계 미리보기는 `accent` 계열을 쓰는 후보를 먼저 시험한다.
5. 5 x 5나 2단계 coarse 선택은 기본값으로 바꾸지 않고 별도 속도 실험으로 둔다.

현재 설정의 가장 큰 디자인 리스크는 `label_background = false`, `sub_key_preview = false`다. 두 옵션을 켜는 것은 Neru가 공식적으로 지원하는 설정 변경이며, 기하 구조와 단축키를 보존한다. 주 라벨 배경을 켜도 색상과 여백은 테마에서 파생할 수 있다. [Neru 설정 문서](https://github.com/y3owk1n/neru/blob/main/docs/CONFIGURATION.md#recursive_grid)

## 적용 전 상태

리서치 시작 시 저장소 설정과 실행 중인 Neru의 `config dump`는 다음과 같았다.

| 항목            | 현재 값                                                         | 확인된 의미                                                |
| --------------- | --------------------------------------------------------------- | ---------------------------------------------------------- |
| 분할            | `3 x 3`                                                         | 한 번에 9개 영역을 선택한다.                               |
| 선택 키         | `rtyfghvbn`                                                     | 3 x 3 셀에 대응하는 고정 키 배열이다.                      |
| 종료 조건       | `min_size_width = 25`, `min_size_height = 25`, `max_depth = 10` | 너무 작은 영역과 최대 재귀 깊이에서 더 이상 좁히지 않는다. |
| 전환 애니메이션 | `50ms`                                                          | 깊이 전환 애니메이션이 켜져 있다.                          |
| 주 라벨         | `font_size = 10`, `label_background = false`                    | 앱 배경 위에 라벨 텍스트만 그린다.                         |
| 다음 단계 안내  | `sub_key_preview = false`                                       | 현재 셀 안에 다음 단계 키를 미리 그리지 않는다.            |
| 라벨 자동 숨김  | `1.5` 배수                                                      | 셀 크기가 글꼴 크기에 비해 작아지면 라벨을 숨긴다.         |
| 핫키            | `Space` reset, `Backspace` backtrack, `Escape` idle             | 현재 조작 흐름은 유지한다. `Hyper+L`은 추가하지 않는다.    |

Neru의 공식 기본값도 recursive grid에 `3 x 3`, `rtyfghvbn`, 50ms 애니메이션을 사용한다. 현재 설정은 그 기본 흐름을 유지하면서 최소 셀 크기와 테마만 명시한 형태다. [공식 설정 레퍼런스](https://github.com/y3owk1n/neru/blob/main/docs/CONFIGURATION.md#recursive_grid), [재귀 그리드 구현](https://github.com/y3owk1n/neru/blob/main/internal/domain/recursivegrid/recursive_grid.go)

## 적용 후 상태

P0 적용 후 live `config dump`에서 다음 값을 확인했다.

- `recursiveGrid.ui.labelBackground = true`
- `recursiveGrid.ui.subKeyPreview = true`
- `recursiveGrid.gridCols = 3`, `recursiveGrid.gridRows = 3`
- `recursiveGrid.keys = "rtyfghvbn"`
- `Primary+Shift+Space`는 `hints`로 유지됐다.
- `Cmd+Ctrl+Alt+Shift+L` 바인딩은 존재하지 않는다.

저장소 설정 파일과 `~/.config/neru/config.toml`의 내용도 일치한다.

## 디자인 진단

### 1. 주 라벨은 배지가 필요하다

현재 주 라벨은 선택 셀의 배경과 그 아래 앱 콘텐츠 위에 바로 그려진다. 웹 페이지, 터미널, 에디터처럼 배경이 계속 바뀌는 화면에서는 같은 색의 텍스트가 서로 다른 가독성을 가질 수 있다.

Neru에는 `label_background`, 자동 여백, 자동 모서리 반경, 테마 기반 `label_background_color`가 이미 있다. 따라서 라벨 주변에 작은 배지를 추가하는 것은 새 렌더링 기능 없이 가능한 개선이다. [Neru macOS 오버레이 렌더러](https://github.com/y3owk1n/neru/blob/main/internal/adapter/platform/darwin/overlay_darwin.m), [UI 설정](https://github.com/y3owk1n/neru/blob/main/internal/adapter/overlay/render/recursivegrid/style.go)

디자인 제안:

- `label_background = true`
- `label_background_padding_x/y = -1` 유지
- `label_background_border_radius = -1` 유지
- `label_background_border_width = 1` 유지
- 처음에는 `font_size = 10` 유지

글꼴을 먼저 키우면 작은 셀에서 자동 숨김이 더 빨리 발생할 수 있다. 배지와 현재 글꼴 크기를 먼저 시험하고, 실제 화면에서 라벨이 작을 때만 11px을 비교하는 순서가 안전하다. 이 문단의 우선순위는 소스 동작에 기반한 디자인 추론이다.

### 2. 다음 단계 미리보기는 방향 감각을 보완한다

현재 `sub_key_preview = false`라서 사용자는 셀을 고른 다음에야 다음 3 x 3 키 배열을 확인한다. `sub_key_preview = true`로 바꾸면 각 셀 안에 다음 단계의 키가 보인다. Neru는 셀이 작아지면 `sub_key_preview_autohide_multiplier` 기준으로 미리보기를 자동 숨긴다. [sub-key preview 구현](https://github.com/y3owk1n/neru/blob/main/internal/adapter/overlay/render/recursivegrid/subkeypreview.go)

미리보기에는 한계도 있다. 현재 구현은 다음 단계의 작은 라벨을 그리지만 내부 셀 경계까지 그리지는 않는다. 그래서 미리보기 키가 보이는 것과 실제로 어느 작은 영역을 뜻하는지가 완전히 같은 정보는 아니다. Neru의 공식 이슈도 이 문제를 지적하며 `sub_grid_preview`와 경계 스타일을 제안하고 있고, 2026-08-31 기준 열려 있다. [Neru issue #1116: Subgrid preview](https://github.com/y3owk1n/neru/issues/1116)

디자인 제안:

- 1차에서는 `sub_key_preview = true`만 사용한다.
- `sub_key_preview_font_size = 8`, `sub_key_preview_autohide_multiplier = 1.5`는 유지한다.
- 미리보기 글자는 주 라벨보다 약한 계층으로 둔다.
- 내부 경계를 흉내 내기 위해 임의의 선이나 비공식 설정 키를 추가하지 않는다.

### 3. 색상 역할을 분리한다

현재 테마는 이미 라이트와 다크에 대해 `surface`, `accent`, `accent_alt`, `text`를 정의한다. recursive grid의 파생 색상은 현재 다음 역할을 사용한다.

- 선과 주 라벨: `accent`
- 선택 영역 강조: `accent_alt`의 반투명 색상
- 라벨 배경: `surface`
- 다음 단계 미리보기: `accent`

주 라벨과 미리보기가 같은 계열을 공유하면 정보 계층이 약해질 수 있다. 주 라벨은 읽기 우선인 `text`, 미리보기는 위치를 보조하는 `accent`로 분리하는 후보가 합리적이다. Neru는 recursive UI에 `text_color`와 `sub_key_preview_text_color`를 각각 지원한다. 정확한 대비와 시각적 무게는 실제 화면에서 확인해야 하므로, 첫 변경에서 `line_color`와 `highlight_color`까지 동시에 바꾸지는 않는다. 이 색상 역할 분리는 현재 저장소 테마에 적용한 디자인 추론이다.

다음은 적용한 P0 설정과 아직 보류한 색상 역할 분리를 합친 후보 형태다. 현재 적용된 변경은 `label_background = true`, `sub_key_preview = true` 두 항목이고, `text_color`와 `sub_key_preview_text_color`는 아직 적용하지 않았다.

```toml
[recursive_grid.ui]
line_width = 1
font_size = 10
font_family = ""

label_background = true
label_background_padding_x = -1
label_background_padding_y = -1
label_background_border_radius = -1
label_background_border_width = 1

text_color = { light = "#17327A", dark = "#E8EEFF" }
sub_key_preview = true
sub_key_preview_font_size = 8
sub_key_preview_autohide_multiplier = 1.5
sub_key_preview_text_color = { light = "#465FBC", dark = "#6E82D6" }
```

### 4. 기하 구조 변경은 속도 실험으로 분리한다

3 x 3은 9개 키만 기억하면 되고, 현재 `rty / fgh / vbn` 배열은 물리 키보드의 작은 격자처럼 읽힌다. 이 구조는 이미 동작 중이며, 디자인 개선의 첫 단계에서 바꿀 이유가 약하다.

Neru는 depth별 `layers` 설정으로 분할 수와 키를 바꿀 수 있다. 5 x 5 같은 더 큰 분할은 한 번에 더 많은 영역을 구분할 수 있지만, 키 기억 부담과 오선택 비용이 함께 바뀐다. Neru 공식 이슈 #1536도 coarse 영역을 두 번의 키 입력으로 고르는 동작을 별도 기능으로 제안하고 있다. 현재 이슈는 열려 있으며, `coarse_keypresses` 같은 이름의 설정을 이미 지원한다는 뜻은 아니다. [depth별 layers 문서](https://github.com/y3owk1n/neru/blob/main/docs/CONFIGURATION.md#recursive_grid), [Neru issue #1536: coarse region selection](https://github.com/y3owk1n/neru/issues/1536)

따라서 다음 순서가 적합하다.

1. 3 x 3을 유지한 채 가독성 개선을 검증한다.
2. 같은 키 흐름으로 10개 작업의 기준 시간을 측정한다.
3. 그 후에만 5 x 5 또는 depth별 `layers`를 별도 프로필로 비교한다.

## 우선순위

| 우선순위 | 변경                              | 이유                                                  | 상태               |
| -------- | --------------------------------- | ----------------------------------------------------- | ------------------ |
| P0       | 라벨 배경 켜기                    | 다양한 앱 배경에서 주 라벨의 읽기 안정성을 높인다.    | 적용 완료          |
| P0       | 다음 단계 미리보기 켜기           | 재귀 선택 중 다음 키를 미리 기억할 수 있다.           | 적용 완료          |
| P0       | 3 x 3, 키 배열, 핫키 유지         | 근육 기억과 현재 사용 흐름을 보호한다.                | 유지 권장          |
| P1       | 주 라벨과 미리보기 색상 역할 분리 | 현재 테마의 의미를 시각적 계층으로 드러낸다.          | P0 결과 후 비교    |
| P1       | subgrid 경계 미리보기             | 미리보기 키와 실제 하위 영역의 대응을 더 명확히 한다. | upstream 이슈 대기 |
| P2       | 5 x 5 또는 depth별 layers         | 키 입력 수와 오선택 비용의 균형을 다시 잡는다.        | 별도 실험          |
| P2       | 두 번의 coarse 선택               | 빠른 coarse-to-fine 흐름을 제공한다.                  | upstream 제안      |

## 검증 계획

### 시각 검증

현재 설정을 기준으로 다음 네 화면에서 P0 후보를 비교한다.

- 밝은 웹 페이지
- 어두운 터미널 또는 에디터
- 이미지나 색상 변화가 큰 화면
- 작은 창이 여러 개 있는 데스크톱

각 화면에서 확인할 항목:

- 주 라벨이 배경과 섞이지 않는가
- 선택 영역 강조가 라벨 배지보다 강해 시선을 빼앗지 않는가
- 다음 단계 미리보기가 주 라벨과 구분되는가
- 작은 셀에서 라벨과 미리보기가 서로 겹치지 않는가
- Escape, Backspace, Space의 현재 의미가 즉시 이해되는가

Neru README는 Recursive Grid를 연습할 수 있는 공식 Neru Dojo도 안내한다. 실제 앱을 오염시키지 않는 첫 시각·조작 테스트 대상으로 사용할 수 있다. [Neru README와 Neru Dojo 안내](https://github.com/y3owk1n/neru#neru-dojo)

### 조작 검증

현재 설정과 P0 후보를 각각 10개 작업에 3회씩 적용한다. 작업은 브라우저, 터미널, 에디터에서 고르게 선택한다.

측정값:

- 모드 진입부터 클릭까지의 시간
- 잘못된 셀 선택 횟수
- `Backspace` 사용 횟수
- `Escape` 취소 횟수
- 주관적 가독성 점수

승격 기준의 제안:

- P0 후보의 중앙 완료 시간이 기준보다 10% 이상 느려지지 않는다.
- 잘못된 셀 선택과 취소가 기준보다 늘지 않는다.
- 네 가지 배경 유형에서 주 라벨과 선택 상태를 식별할 수 있다.
- `neru config validate`, `neru config reload`가 성공한다.

이번 조사에서는 오버레이 스크린샷과 실제 10개 작업의 시간 측정을 실행하지 않았다. 설정 reload와 `config dump`로 적용 상태만 확인했다. 따라서 위 시각 판단은 Neru 소스, 현재 설정, 공식 이슈를 바탕으로 한 후보 설계이며, 실제 체감 개선 여부는 별도 사용자 테스트가 필요하다.

## 접근성 및 단축키 원칙

Apple은 키보드 접근성을 지원하고 표준 단축키를 존중하며, 키보드로 탐색·상호작용할 수 있게 하라고 안내한다. Neru overlay는 macOS 네이티브 컨트롤은 아니지만, 같은 원칙을 적용하면 라벨 가독성, 명확한 포커스 표현, 일관된 Escape와 Backspace 흐름을 우선할 수 있다. [Apple HIG: Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards/), [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), [Apple HIG: Focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/)

이번 후보에서는 사용자가 명시한 `Hyper+L`을 추가하지 않는다. 기존 Neru hotkey와 로컬 Hyper 바인딩의 경계를 보존하는 것이 현재 목표에 맞다.

## 출처와 사실의 범위

- Neru v1.51.0 실행 파일의 commit은 `847730a`다.
- Neru 설정 문서와 소스에서 확인한 옵션만 후보에 사용했다.
- `sub_grid_preview`, `coarse_keypresses`는 현재 저장소 설정에 추가하지 않았다. 각각 공식 이슈의 제안 또는 요구사항으로만 다뤘다.
- Apple HIG는 Neru의 동작을 보증하는 문서가 아니라 키보드·접근성 디자인 원칙의 참고 기준이다.
