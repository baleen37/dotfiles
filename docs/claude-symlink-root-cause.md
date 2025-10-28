# Claude Code Symlink Issue: Root Cause Analysis

## TL;DR

**문제**: `xdg.configFile` + `mkOutOfStoreSymlink` + `self.outPath` 조합이 Nix Flakes에서 작동하지 않음
**근본 원인**: Flakes가 소스를 평가할 때 자동으로 `/nix/store`에 복사하기 때문
**해결책**: `home.activation` 스크립트로 절대 경로를 동적으로 탐지하여 symlink 생성

---

## 문제 상황

### 초기 코드 (작동하지 않음)

```nix
# users/shared/claude-code.nix (실패한 시도)
{ config, self, ... }:
{
  xdg.configFile."claude" = {
    source = config.lib.file.mkOutOfStoreSymlink "${self.outPath}/users/shared/.config/claude";
    recursive = true;  # 또는 false
    force = true;
  };
}
```

### 예상 결과
```
~/.config/claude -> /Users/jito/dotfiles/users/shared/.config/claude
```

### 실제 결과
```
~/.config/claude -> /nix/store/xhkbx2wi7awzn137jfyzp8j7frn8k86v-source/users/shared/.config/claude
```

---

## 근본 원인 분석

### 1. Nix Flakes의 소스 처리 방식

Nix Flakes는 **pure evaluation**을 보장하기 위해 다음과 같이 동작합니다:

```bash
# Flake 평가 시
$ nix eval --impure --expr 'let flake = builtins.getFlake "/Users/jito/dotfiles"; in flake.outPath'
"/nix/store/x4gl10qdf7gg13fi61a82s4zf0ciylx1-source"
```

**동작 과정**:
1. `/Users/jito/dotfiles` (실제 디렉토리)
2. → Nix가 소스를 복사
3. → `/nix/store/...-source` (read-only 복사본)
4. → `self.outPath`가 이 경로를 가리킴

### 2. mkOutOfStoreSymlink의 한계

`mkOutOfStoreSymlink`는 다음과 같이 정의됩니다:

```nix
lib.file.mkOutOfStoreSymlink = path:
  let
    pathStr = toString path;
    name = hm.strings.storeFileName (baseNameOf pathStr);
  in
    pkgs.runCommandLocal name {} ''ln -s ${escapeShellArg pathStr} $out'';
```

**문제점**:
- **입력값**이 이미 `/nix/store` 경로이면 의미 없음
- `self.outPath` → 이미 `/nix/store/...-source`
- `mkOutOfStoreSymlink "${self.outPath}/..."` → 여전히 `/nix/store` 가리킴

### 3. xdg.configFile의 동작

```nix
xdg.configFile."claude" = {
  source = mkOutOfStoreSymlink "/nix/store/.../claude";  # 입력이 이미 store 경로
  recursive = true;  # 이것도 영향 없음
};
```

**결과**:
- Home Manager가 symlink 생성
- 하지만 target이 이미 `/nix/store`
- read-only, `nix-collect-garbage`로 삭제될 수 있음

---

## 관련 이슈 및 커뮤니티 논의

### GitHub Issue #2085
**제목**: "mkOutOfStoreSymlink doesn't work as expected with a flake setup"
**URL**: https://github.com/nix-community/home-manager/issues/2085

**핵심 내용**:
> When flakes process relative paths, they get copied into the store during evaluation, causing mkOutOfStoreSymlink to reference the stored version rather than the original filesystem location.

**커뮤니티 해결책**:
1. **절대 경로 하드코딩**:
   ```nix
   mkOutOfStoreSymlink "${config.home.homeDirectory}/projects/dot/config/alacritty"
   ```

2. **커스텀 옵션 정의**:
   ```nix
   options.dotfiles = mkOption {
     type = types.str;
     default = "${config.home.homeDirectory}/.dotfiles";
   };
   ```

3. **Activation 스크립트 사용** (우리가 선택한 방법):
   ```nix
   home.activation.linkClaudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
     DOTFILES_ROOT="..." # 동적 탐지
     ln -sfn "$DOTFILES_ROOT/users/shared/.config/claude" "$HOME/.config/claude"
   '';
   ```

---

## 우리의 해결책

### 최종 구현 (claude-code.nix)

```nix
{ config, lib, pkgs, self, ... }:
{
  home.activation.linkClaudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CLAUDE_TARGET="${config.home.homeDirectory}/.config/claude"

    # Find actual dotfiles repository path by checking common locations
    DOTFILES_ROOT=""
    if [ -d "${config.home.homeDirectory}/dotfiles/.git" ]; then
      DOTFILES_ROOT="${config.home.homeDirectory}/dotfiles"
    elif [ -d "${config.home.homeDirectory}/.dotfiles/.git" ]; then
      DOTFILES_ROOT="${config.home.homeDirectory}/.dotfiles"
    elif [ -d "${config.home.homeDirectory}/dev/dotfiles/.git" ]; then
      DOTFILES_ROOT="${config.home.homeDirectory}/dev/dotfiles"
    fi

    if [ -z "$DOTFILES_ROOT" ] || [ ! -d "$DOTFILES_ROOT" ]; then
      echo "⚠️  Warning: Could not find dotfiles repository"
      CLAUDE_SOURCE="${self.outPath}/users/shared/.config/claude"
    else
      CLAUDE_SOURCE="$DOTFILES_ROOT/users/shared/.config/claude"
    fi

    # Create symlink
    rm -rf "$CLAUDE_TARGET"
    mkdir -p "${config.home.homeDirectory}/.config"
    ln -sfn "$CLAUDE_SOURCE" "$CLAUDE_TARGET"
    echo "✅ Created symlink: $CLAUDE_TARGET -> $CLAUDE_SOURCE"
  '';
}
```

### 왜 이 방법이 작동하는가?

1. **런타임 평가**: Activation 스크립트는 빌드 후 실행됨 (Nix 평가 단계 아님)
2. **실제 파일시스템 탐색**: `.git` 디렉토리로 실제 dotfiles 위치 찾음
3. **절대 경로 사용**: `$HOME/dotfiles` 같은 실제 경로 사용
4. **Fallback**: 찾지 못하면 `self.outPath` 사용 (최소한 작동은 함)

### 장점

✅ **편집 가능**: 파일이 writable (read-only 아님)
✅ **지속성**: `nix-collect-garbage` 후에도 유지
✅ **즉시 반영**: 변경사항이 재빌드 없이 바로 적용
✅ **멀티 사용자**: 동적 경로 탐지로 모든 사용자 지원

### 단점

⚠️ **Impure**: 파일시스템 상태에 의존
⚠️ **재현성 낮음**: 다른 머신에서 dotfiles 위치가 다르면 실패 가능
⚠️ **수동 관리**: Dotfiles를 삭제하면 symlink가 깨짐

---

## 다른 접근 방법 비교

### 방법 1: xdg.configFile + text (순수 Nix)

```nix
xdg.configFile."claude/CLAUDE.md".text = ''
  # Content here
'';
```

**장점**: 완전히 재현 가능, pure evaluation
**단점**: 대용량 파일 관리 어려움, 편집 시 재빌드 필요

### 방법 2: mkOutOfStoreSymlink + 절대 경로 하드코딩

```nix
xdg.configFile."claude".source =
  config.lib.file.mkOutOfStoreSymlink "/Users/jito/dotfiles/users/shared/.config/claude";
```

**장점**: 간단, Home Manager 통합
**단점**: 경로 하드코딩 (멀티 사용자 불가), 유연성 낮음

### 방법 3: home.activation (우리의 선택)

```nix
home.activation.linkClaudeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  # Dynamic path detection + symlink creation
'';
```

**장점**: 동적 경로 탐지, 멀티 사용자 지원, 유연함
**단점**: 복잡성 증가, impure evaluation

### 방법 4: 하이브리드 (조건부)

```nix
xdg.configFile."claude".source =
  if builtins.pathExists /Users/jito/dotfiles
  then config.lib.file.mkOutOfStoreSymlink "/Users/jito/dotfiles/users/shared/.config/claude"
  else "${self.outPath}/users/shared/.config/claude";
```

**장점**: Fallback 제공
**단점**: 여전히 하드코딩, pure evaluation 위반

---

## 교훈 및 Best Practices

### 1. Nix Flakes의 제약 이해하기

- ✅ Flakes는 **pure evaluation**을 목표로 함
- ✅ 소스는 자동으로 `/nix/store`에 복사됨
- ✅ `self.outPath`는 항상 Nix store 경로

### 2. mkOutOfStoreSymlink 사용 시 주의사항

- ✅ **절대 경로**를 전달해야 함 (상대 경로 ❌)
- ✅ `${config.home.homeDirectory}` 사용 권장
- ✅ `self.outPath` 전달은 무의미함

### 3. Dotfiles 관리 철학 선택

**Option A: Pure Nix** (재현성 최우선)
- 모든 설정을 Nix 파일에 작성
- `text` 또는 `source` with store paths
- 변경 시 재빌드 필요

**Option B: Hybrid** (유연성 + 편의성) ← **우리의 선택**
- 자주 변경하는 파일: symlink 사용
- 안정적인 설정: Nix 파일 사용
- `home.activation`으로 impurity 격리

**Option C: External Tools** (Nix 밖에서 관리)
- GNU Stow, Chezmoi 등 사용
- Nix는 패키지만 관리
- 완전히 별개 시스템

### 4. 통합 테스트의 중요성

우리가 작성한 `tests/integration/test-claude-symlink.sh`:
- ✅ Symlink 대상 검증
- ✅ `/nix/store` 참조 확인
- ✅ 파일 접근성 테스트
- ✅ CI/CD 파이프라인 통합

---

## 참고 자료

- [Home Manager Issue #2085](https://github.com/nix-community/home-manager/issues/2085)
- [Managing dotfiles with Nix](https://seroperson.me/2024/01/16/managing-dotfiles-with-nix/)
- [Managing mutable files in NixOS](https://www.foodogsquared.one/posts/2023-03-24-managing-mutable-files-in-nixos/)
- [The home-manager function that changes everything](https://jeancharles.quillet.org/posts/2023-02-07-The-home-manager-function-that-changes-everything.html)

---

## 결론

`xdg.configFile` + `mkOutOfStoreSymlink` + `self.outPath` 조합이 작동하지 않는 이유는:

1. **Flakes가 소스를 `/nix/store`에 복사**
2. **`self.outPath`가 이미 store 경로**
3. **`mkOutOfStoreSymlink`에 store 경로를 전달하면 무의미**

해결책은:
- **절대 경로 사용** (하드코딩 또는 동적 탐지)
- **`home.activation` 스크립트** (런타임 symlink 생성)
- **통합 테스트**로 검증

이 문서가 동일한 문제를 겪는 다른 개발자들에게 도움이 되기를 바랍니다. 🚀
