# Hyper Key Secure Input Immunity Design

**Date:** 2026-04-27
**Status:** Draft
**Author:** jito.hello

## Problem

macOS의 Secure Input이 켜진 상태(예: Safari 비밀번호 필드 포커스, stale Secure Input PID, loginwindow 잔류)에서는 Hammerspoon의 모든 Hyper 핫키가 동작하지 않는다.

원인은 구조적이다. Hammerspoon은 user-space program이고 핫키 처리에 `hs.eventtap` (= macOS Accessibility API)을 사용하는데, Secure Input은 이 레이어를 차단한다. Hammerspoon 메인테이너도 [Issue #2341](https://github.com/Hammerspoon/hammerspoon/issues/2341)에서 "essentially impossible for us to defeat secure input mode"라고 공식 인정했다.

반면 Karabiner-Elements는 administrative privilege를 가진 `Karabiner-Core-Service`(DriverKit virtual HID)로 동작하여 Secure Input 환경에서도 정상 동작한다 ([공식 문서: Secure Keyboard Entry Support](https://karabiner-elements.pqrs.org/docs/getting-started/features)).

현재 dotfiles의 구조는 Karabiner를 키 변환(Right Cmd → F19)에만 사용하고 모든 핫키 처리를 Hammerspoon에 맡긴다. 이는 Karabiner의 Secure Input 면역을 활용하지 못하는 구조다.

## Goal

자주 사용되는 앱 실행 핫키 8개를 Karabiner Complex Modifications로 이관하여 Secure Input 환경에서도 동작하도록 한다.

**Non-goal:** 모든 Hyper 바인딩을 Karabiner로 이관하지 않는다. 동적 로직(Pomodoro, HyperModal)이나 컨텍스트 의존 바인딩(localBindings)은 Hammerspoon에 남긴다.

## Scope

### 이관 대상 (Hammerspoon → Karabiner)

`users/shared/.config/hammerspoon/configApplications.lua`의 `hyperKey` 필드 8개:

| 키 | 앱 | Bundle ID |
|----|-----|----------|
| i | Ghostty | com.mitchellh.ghostty |
| e | Mail | com.apple.mail |
| f | Finder | com.apple.finder |
| h | Dash | com.kapeli.dashdoc |
| k | KakaoTalk | com.kakao.KakaoTalkMac |
| n | Notion | notion.id |
| o | Obsidian | md.obsidian |
| t | Things | com.culturedcode.ThingsMac |

### 유지 (Hammerspoon)

- **Hyper+m** — HyperModal 토글 (모달 진입 로직)
- **Hyper+p** — Pomodoro 토글 (상태 머신)
- **HyperModal 내부 바인딩** — 예: `;` → Raycast 테마 토글
- **localBindings** — Things `,`/`.`, Bartender `b`, Homerow `l`, Cardhop `u`, Homerow(superultra) `return`/`tab`
- **Hyper.spoon F19 모달 시스템** — 위 바인딩들의 트리거 인프라
- **Secure Input 모니터** — init.lua:69-79 그대로

### 유지 (Karabiner)

- `simple_modifications: right_command → f19` — Hammerspoon Hyper modal 트리거용

## Architecture

### 키 흐름

**Hyper + 이관된 키 (i, e, f, h, k, n, o, t):**
```
[Right Cmd + i 누름]
  ↓ Karabiner DriverKit (Secure Input 무관)
  ↓ complex_modifications 매칭 (simple보다 먼저 평가됨)
  ↓ software_function.open_application 실행
[Ghostty 실행/포커스]
```

**Hyper + 남은 키 (m, p, localBindings):**
```
[Right Cmd 단독 또는 Right Cmd + 미매칭 키]
  ↓ Karabiner: complex 매칭 없음
  ↓ simple_modifications: Right Cmd → F19
[F19 이벤트]
  ↓ Hammerspoon eventtap (Secure Input ON이면 차단됨)
  ↓ Hyper.spoon이 모달 진입
[Hyper+m, Hyper+p 등 처리]
```

**핵심 보장:** Karabiner는 complex_modifications를 simple_modifications보다 먼저 평가한다. 따라서 두 매핑이 같은 키(Right Cmd)를 사용해도 충돌이 없다 — 매칭되는 것이 있으면 complex가 이기고, 없을 때만 simple이 동작.

### 파일 변경 위치

| 파일 | 변경 |
|------|------|
| `users/shared/.config/karabiner/karabiner.json` | `complex_modifications` 추가 (8개 manipulator) |
| `users/shared/.config/hammerspoon/configApplications.lua` | 이관된 8개 항목에서 `hyperKey` 필드 제거. `localBindings`/`bundleID`는 유지 |

다른 파일은 손대지 않는다 (init.lua, hammerspoon.nix, karabiner.nix 등 모두 그대로).

## Detailed Design

### Karabiner JSON 변경

기존:
```json
{
  "profiles": [{
    "name": "Default profile",
    "selected": true,
    "simple_modifications": [
      { "from": { "key_code": "right_command" },
        "to": [{ "key_code": "f19" }] }
    ],
    "virtual_hid_keyboard": { "keyboard_type_v2": "ansi" }
  }]
}
```

추가될 `complex_modifications` (예시 1개, 실제 8개):
```json
"complex_modifications": {
  "rules": [{
    "description": "Hyper (Right Command) app launchers — Secure Input immune",
    "manipulators": [
      {
        "type": "basic",
        "from": {
          "key_code": "i",
          "modifiers": { "mandatory": ["right_command"] }
        },
        "to": [{
          "software_function": {
            "open_application": {
              "bundle_identifier": "com.mitchellh.ghostty"
            }
          }
        }]
      }
      // ... e, f, h, k, n, o, t 동일 패턴
    ]
  }]
}
```

### "frontmost면 hide" 토글 처리 — 의도적 단순화

현재 Hammerspoon 동작 (configApplications.lua의 init.lua:23-29):
```lua
if hs.application.get(bundleID):isFrontmost() then
    hs.application.get(bundleID):hide()
else
    hs.application.launchOrFocusByBundleID(bundleID)
end
```

Karabiner의 `software_function.open_application`은 launch/focus만 한다. Hide 동작은 이관 후 사라진다.

**의도적 단순화 이유:**
1. `frontmost_application_if` 조건 + osascript hide로 구현 가능하지만, JSON이 매핑마다 두 manipulator로 늘어나서 복잡해짐
2. Hide 토글의 사용 빈도가 낮음 — 주 사용은 "앱으로 이동"
3. 정 필요하면 후속 작업으로 추가 가능

**대체 동작:** 이미 frontmost인 앱에 Hyper+key를 누르면 아무 일도 일어나지 않음 (현재의 hide 대신). Cmd+H로 hide 가능.

### Hammerspoon 변경

`configApplications.lua` — 이관된 항목에서 `hyperKey` 필드만 제거. 나머지 메타데이터(bundleID, localBindings)는 유지:

```lua
-- before
['com.mitchellh.ghostty'] = {
  bundleID = 'com.mitchellh.ghostty',
  hyperKey = 'i'
},

-- after
['com.mitchellh.ghostty'] = {
  bundleID = 'com.mitchellh.ghostty'
},
```

Things처럼 `localBindings`도 함께 가진 항목은 `hyperKey`만 제거:
```lua
-- before
['com.culturedcode.ThingsMac'] = {
  bundleID = 'com.culturedcode.ThingsMac',
  hyperKey = 't',
  localBindings = {',', '.'}
},

-- after
['com.culturedcode.ThingsMac'] = {
  bundleID = 'com.culturedcode.ThingsMac',
  localBindings = {',', '.'}
},
```

`init.lua`의 hyperKey 처리 루프(21-30)는 변경하지 않는다 — 이관되지 않은 항목이 있으면 여전히 동작해야 하기 때문 (현재 8개 모두 이관이지만, 미래에 추가 hyperKey가 생기면 자연스럽게 적용됨).

## Trade-offs

### 받아들이는 손실
- **Hide 토글 동작 손실** (위에서 설명한 단순화)
- **Hyper+m, Hyper+p는 여전히 Secure Input에 영향받음** — 다만 사용 빈도가 낮음

### 얻는 이점
- 자주 쓰는 8개 핫키가 Secure Input 환경에서도 동작
- 일상의 99% 케이스에서 "왜 안 되지?" 디버깅 시간 제거
- 두 도구의 책임 분리 명확화 (정적 실행 = Karabiner, 동적 로직 = Hammerspoon)

### 영향 받지 않는 것
- 머슬 메모리 (모든 핫키 동일하게 동작)
- localBindings (앱 컨텍스트별 바인딩)
- HyperModal, Pomodoro
- 다른 Karabiner 매핑

## Testing Plan

1. **빌드 검증:** `nix run --impure .#build-switch`로 home-manager가 새 karabiner.json을 배포
2. **Karabiner 재시작 / 자동 재로드:** Karabiner-Elements는 `~/.config/karabiner/karabiner.json` 변경 자동 감지
3. **각 핫키 동작 확인:** Hyper+i, e, f, h, k, n, o, t 8개 → 해당 앱 실행/포커스
4. **Secure Input 환경에서 확인:** `Terminal.app → Secure Keyboard Entry` 또는 1Password 비밀번호 필드 포커스 상태에서 Hyper+i 눌러 동작 확인
5. **남은 Hammerspoon 핫키 확인:** Hyper+m (HyperModal), Hyper+p (Pomodoro) 정상 동작
6. **localBindings 확인:** Things 활성화 상태에서 Hyper+, / Hyper+. 동작
7. **충돌 없음 확인:** Right Cmd 단독 → F19 변환 → Hammerspoon Hyper 모달 정상 동작

## Rollback

karabiner.json의 `complex_modifications` 키 통째로 제거 + `configApplications.lua`에 hyperKey 필드 복구. 두 파일 모두 git 추적 중이라 단일 revert로 가능.

## References

- [Hammerspoon Issue #2341 — "Allow capturing of key events in secure input mode"](https://github.com/Hammerspoon/hammerspoon/issues/2341) — 메인테이너 공식 답변
- [Karabiner-Elements — Secure Keyboard Entry Support](https://karabiner-elements.pqrs.org/docs/getting-started/features)
- [Karabiner-Elements — Privacy / Input Monitoring](https://karabiner-elements.pqrs.org/docs/privacy)
- [Karabiner-Elements — software_function.open_application](https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/software_function/open_application)
- [Karabiner-Elements — Complex Modifications Examples](https://karabiner-elements.pqrs.org/docs/json/typical-complex-modifications-examples)
