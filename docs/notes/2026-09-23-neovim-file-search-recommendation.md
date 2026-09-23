# Neovim 파일 이름 검색 추천

- 조사일: 2026-09-23
- 범위: 사이드바 트리가 아닌 파일 이름 퍼지 검색과 키 조합. 공식 문서는 동작·의존성 근거로, Reddit은 사용자 선호와 키맵 사례의 일화 근거로만 사용했다.

## 추천

Neovim으로 전환한다면 **`fzf-lua`를 추천한다.** 사용자가 이미 `fzf`를 쓰고 있고, 이 checkout도 `fzf`, `fd`, `ripgrep`을 패키지로 선언한다. `fzf-lua`는 파일 picker를 제공하며 `:FzfLua files`로 실행할 수 있다. Neovim 0.9 이상과 fzf 0.36 초과(또는 `skim`)가 필요하고, `fd`와 `rg`는 선택 의존성이다. [공식 의존성·사용법](https://github.com/ibhagwan/fzf-lua#dependencies) · [현재 패키지 목록](../../users/shared/packages/core.nix#L22-L26)

현재 Leader가 Space이므로 파일 검색 키맵은 **`<Space>ff`**를 추천한다. `ff`는 “find files”로 외우기 쉽고, 최근 Reddit 키맵 사례에서도 `<leader>ff`를 파일 검색에 연결했다. 이 조합은 이 설정에 맞춘 제안이며 플러그인의 기본값은 아니다. [Reddit 키맵 관례 토론](https://www.reddit.com/r/neovim/comments/1htd3m9/) · [fzf-lua `<leader>ff` 사례](https://www.reddit.com/r/neovim/comments/1senmvj/)

## 현재 설정과 선택지

조사 당시 Home Manager는 Vim만 활성화했고 Neovim은 꺼져 있었다. 이번 변경으로 Neovim과 `fzf-lua`를 활성화하고 `<Space>ff`를 연결했다. 기존 Vim 옵션·키맵·Airline/Tmux 플러그인 설정은 공통 파일로 옮겨 Vim과 Neovim이 함께 읽으며, Zsh의 `vi`와 `vim` 별칭은 Neovim을 실행한다. [활성화 설정](../../users/shared/home-manager.nix) · [Neovim 모듈과 키맵](../../users/shared/programs/neovim.nix) · [공통 Vim 설정](../../users/shared/programs/vim-common.vim) · [Zsh 별칭](../../users/shared/programs/zsh/default.nix)

셸의 **Ctrl-T 파일 검색은 이미 설정돼 있다.** Zsh fzf 통합이 켜져 있고, 파일 후보는 `fd --type f --hidden --follow --exclude .git`로 만든다. fzf의 Ctrl-T 동작은 선택한 경로를 명령줄에 붙여 넣는 셸 기능이므로, 에디터 안에서 파일을 찾아 여는 picker와는 별개다. [저장소 설정](../../users/shared/programs/zsh/default.nix#L35-L60) · [fzf 셸 키 바인딩](https://github.com/junegunn/fzf#key-bindings-for-command-line)

| 선택지             | 적합한 경우                                           | 의존성·특징                                                                                                                                                                                                                                                                                                                                                                                               |
| ------------------ | ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **fzf-lua — 추천** | 기존 fzf 사용 흐름을 Neovim 안에서도 이어가고 싶을 때 | fzf 또는 `skim` 실행 파일 필요. `fd`/`rg` 선택 사용 가능. 파일 검색은 `:FzfLua files`. [공식 문서](https://github.com/ibhagwan/fzf-lua#usage)                                                                                                                                                                                                                                                             |
| Snacks Picker      | 파일 검색 외 여러 picker를 한 플러그인에 묶고 싶을 때 | fzf 검색 문법을 지원하는 자체 matcher. 파일 목록은 `fd` → `rg` → `find` 순으로 탐색기를 고른다. 공식 문서와 소스에서 확인되는 구조상 파일 picker 자체에 fzf 실행 파일은 필요하지 않다(소스 근거에서의 추론). [Picker 문서](https://github.com/folke/snacks.nvim/blob/main/docs/picker.md) · [파일 탐색 소스](https://github.com/folke/snacks.nvim/blob/main/lua/snacks/picker/source/files.lua#L597-L624) |
| Telescope          | 폭넓은 builtin picker와 확장 기능을 원할 때           | 최신 공식 README 기준 Neovim 0.11.7 이상과 `plenary.nvim` 필요. `rg`/`fd` 권장. [공식 README](https://github.com/nvim-telescope/telescope.nvim#requirements)                                                                                                                                                                                                                                              |
| fzf.vim            | Neovim 전환 전 현재 Vim에서 파일 picker가 필요할 때   | fzf 본체와 `fzf.vim` 플러그인을 함께 설정하고 `:Files` 실행. `:Files`는 `FZF_DEFAULT_COMMAND`가 있으면 그 목록 생성 명령을 사용한다. [공식 문서](https://github.com/junegunn/fzf.vim#installation) · [`:Files` 동작](https://github.com/junegunn/fzf.vim#commands)                                                                                                                                        |

## Reddit에서 보인 흐름

최근 2년의 r/neovim 글은 설치량 표본이 아니라 개인 선택과 댓글 토론이다. 그래서 글 점수나 댓글만으로 “가장 많이 쓰는 picker”를 확정할 수는 없다.

2025년 6월 비교 글에서는 큰 프로젝트 검색 속도와 기존 CLI fzf와의 일관성을 이유로 `fzf-lua`를 고른 사람이 있었고, Snacks의 빠른 반응과 설정·확장 편의성, Telescope의 기능과 기존 워크플로를 이유로 각자 유지하는 사람도 있었다. `mini.pick`을 단순함 때문에 고른 댓글도 나왔다. [picker 비교 토론](https://www.reddit.com/r/neovim/comments/1la9epu/)

Snacks는 2025년 초 picker 출시 글과 LazyVim 새 설치 기본값 변경 글에서 큰 관심을 받았다. 이는 생태계 관심의 신호로 볼 수 있지만, 실제 설치 비율을 뜻하지는 않는다. [Snacks Picker 출시 토론](https://www.reddit.com/r/neovim/comments/1i1indh/) · [LazyVim 기본값 토론](https://www.reddit.com/r/neovim/comments/1ikontg/)

2026년 8월의 Telescope 토론도 속도 비교에서 `fzf-lua`, Snacks, `mini.pick`을 각각 추천하는 댓글이 섞였다. 이 자료까지 보면 Reddit에서 단일 승자를 고르기 어렵다. [2026년 의견 토론](https://www.reddit.com/r/neovim/comments/1w3767b/)

### 파일 검색 키 조합

2025년 Reddit 키맵 토론에서는 `f`를 파일 검색 그룹으로 두고 `<leader>ff`를 Find Files, `<leader>fg`를 Find Grep, `<leader>gf`를 Git Files로 쓰는 사례가 나왔다. 2026년 fzf-lua 키맵 사례도 `<leader>ff`를 현재 작업 디렉터리의 파일 검색에 연결한다. 이 두 사례는 통계가 아니지만 `ff`가 의미를 바로 떠올리기 좋은 선택임을 뒷받침한다. [2025년 키맵 토론](https://www.reddit.com/r/neovim/comments/1htd3m9/) · [2026년 fzf-lua 키맵 사례](https://www.reddit.com/r/neovim/comments/1senmvj/)

`<leader><space>`도 일부 LazyVim/Telescope 설정에서 파일 검색으로 사용하지만, 다른 설정에서는 열린 버퍼 검색에 연결되기도 한다. 기본 설정을 그대로 따르려는 배포판 사용자가 아니라면 `<Space>ff`가 더 명확하다. [LazyVim 파일 검색 키 사례](https://www.reddit.com/r/neovim/comments/1hzjsvt/) · [버퍼와 파일을 구분한 키맵 사례](https://www.reddit.com/r/neovim/comments/1nbkso6/)

**결론:** Neovim에서는 `<Space>ff`로 `fzf-lua` 파일 검색을 열 수 있다. 셸에서 `vi`나 `vim`을 입력해도 Neovim 설정이 적용된다. Vim 바이너리를 직접 실행할 때는 `fzf.vim`의 `:Files`를 대안으로 쓸 수 있고, 셸의 Ctrl-T 검색도 이미 설정돼 있다.
