# Neovim Markdown 미리보기 키맵 조사

- 조사일: 2026-09-24
- 범위: `render-markdown.nvim` 인버퍼 렌더링과 `markdown-preview.nvim` 브라우저 미리보기 키맵. 플러그인 공식 문서·소스와 LazyVim 공식 Markdown 설정을 확인했다. 키의 직관성 평가는 조사자의 판단이며 사용 통계 주장이 아니다.

## 추천

현재 설정의 **`<Space>mr` = 인버퍼 렌더링 토글**, **`<Space>mp` = 브라우저 미리보기 토글**을 유지한다. Leader가 Space이고 두 키가 모두 `m`(Markdown) 아래 `r`(render), `p`(preview)로 모여 기능을 구분하기 쉽다. 현재 사용자 설정에서 기존 키맵은 `<leader>q`, `<leader>e`, `<leader>ff`이며 이 두 조합과 겹치지 않는다. [Leader와 Neovim 키맵](../../users/shared/programs/neovim.nix#L32-L63) · [공통 Vim 키맵](../../users/shared/programs/vim-common.vim#L77)

이 쌍은 플러그인의 표준 키가 아니라 저장소에 맞춘 제안이다. [render-markdown.nvim 공식 명령](https://github.com/MeanderingProgrammer/render-markdown.nvim#commands)은 전역 `toggle`과 현재 버퍼용 `buf_toggle`을 제공하고, [markdown-preview.nvim 공식 README](https://github.com/iamcco/markdown-preview.nvim#markdownpreview-config)는 `<Plug>MarkdownPreviewToggle`과 브라우저 미리보기를 설명한다. 두 기능에 공통 접두어와 의미가 드러나는 끝 글자를 쓰는 편이 이 설정에서는 가장 기억하기 쉽다.

## 다른 관례

| 선택                                   | 동작                                    | 판단                                                                                                                                                                                                       |
| -------------------------------------- | --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`<leader>mr` / `<leader>mp` — 추천** | Markdown 렌더링 / 브라우저 미리보기     | 두 키가 한 그룹이고 기능 이름과 연결하기 쉽다.                                                                                                                                                             |
| `<leader>um` / `<leader>cp`            | LazyVim의 렌더 토글 / 브라우저 미리보기 | [LazyVim 공식 Markdown 설정](https://www.lazyvim.org/extras/lang/markdown#markdown-previewnvim)이 쓰는 관례다. LazyVim 키맵에 익숙하면 이식하기 좋지만, 이 저장소만 보면 `u`와 `c`의 의미가 덜 직접적이다. |
| `<C-p>`                                | 브라우저 미리보기 토글 예시             | [플러그인 README 예시](https://github.com/iamcco/markdown-preview.nvim#markdownpreview-config)다. 기본 키맵이라고 설명하지 않으며, 렌더 플러그인과 키 체계도 맞추지 않는다.                                |

현재 checkout에서 `<leader>mr`과 `<leader>mp` 외에 `<leader>m`으로 시작하는 사용자 키맵은 없다. 계획의 동작 범위가 현재 버퍼이므로 `<leader>mr`은 `:RenderMarkdown buf_toggle`에 연결한다. 이 플러그인은 전역 상태를 바꾸는 `toggle`과 버퍼별 상태를 바꾸는 `buf_toggle`을 구분한다. [공식 명령 목록](https://github.com/MeanderingProgrammer/render-markdown.nvim#commands)

**결론:** 이 저장소에서는 `<Space>mr`과 `<Space>mp`를 추천한다. LazyVim 키맵에 이미 익숙한 사용자라면 `<Space>um`과 `<Space>cp`도 합리적이다.

## 실행 의존성

고정된 Nixpkgs의 `markdown-preview.nvim` 패키지에는 플랫폼별 실행 번들이 없고, 플러그인 런처는 번들을 찾지 못하면 `node app/index.js`로 서버를 시작한다. [공식 런처](https://github.com/iamcco/markdown-preview.nvim/blob/master/autoload/mkdp/rpc.vim)와 [설치 안내](https://github.com/iamcco/markdown-preview.nvim#installation--usage)는 Node.js 경로를 요구한다. 따라서 `nodejs_22`를 `programs.neovim.extraPackages`에 넣어 GUI 등 어떤 진입 경로에서도 브라우저 미리보기 서버가 Node를 찾게 한다.
