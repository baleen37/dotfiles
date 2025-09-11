local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 다크 테마 고정 설정 (더 어두운 테마 사용)
config.color_scheme = 'Tokyo Night'

-- 폰트 설정 (성능 최적화를 위해 간소화)
config.font = wezterm.font_with_fallback({
  'JetBrains Mono',
  'Apple Color Emoji',
  'Menlo',  -- macOS 기본 fallback
})
config.font_size = 14
config.use_fancy_tab_bar = false

-- 터미널 설정 (성능 최적화)
config.scrollback_lines = 3500  -- 메모리 사용량 최적화
config.window_background_opacity = 1.0  -- 완전 불투명
config.initial_cols = 80
config.initial_rows = 25

-- 키 바인딩 (iTerm2와 동일)
config.keys = {
  -- Ctrl+Shift+Arrow 키 매핑
  { key = 'UpArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6A' },
  { key = 'DownArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6B' },
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6D' },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6C' },

  -- Home/End 키 매핑
  { key = 'Home', mods = 'CTRL', action = wezterm.action.SendString '\x1b[1;5H' },
  { key = 'End', mods = 'CTRL', action = wezterm.action.SendString '\x1b[1;5F' },

  -- 탭 이동 (Navigation)
  { key = '{', mods = 'CMD|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  { key = '}', mods = 'CMD|SHIFT', action = wezterm.action.ActivateTabRelative(1) },

  -- 탭 위치 변경 (Swap)
  { key = '{', mods = 'CMD|OPT', action = wezterm.action.MoveTabRelative(-1) },
  { key = '}', mods = 'CMD|OPT', action = wezterm.action.MoveTabRelative(1) },

  -- Claude Code interactive shell 지원 - Shift+Enter를 \ + Enter 시퀀스로 매핑
  { key = 'Enter', mods = 'SHIFT', action = wezterm.action.SendString '\\\r' },

  -- SSH/tmux 환경 복사-붙여넣기 키 바인딩
  { key = 'c', mods = 'CMD', action = wezterm.action.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CMD', action = wezterm.action.PasteFrom 'Clipboard' },
}

-- 마우스 설정 (SSH/tmux 복사-붙여넣기 지원)
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection',
  },
  -- Middle click으로 붙여넣기 (SSH/tmux 환경)
  {
    event = { Up = { streak = 1, button = 'Middle' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
  -- Option+Click으로 강제 선택 (tmux에서 마우스 모드가 켜져있을 때)
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'ALT',
    action = wezterm.action.CompleteSelection 'ClipboardAndPrimarySelection',
  },
}

-- 윈도우 설정
config.window_decorations = 'RESIZE'
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false

-- 탭 바 색상만 Tokyo Night에 맞춰 커스터마이징 (터미널 색상은 color_scheme 사용)
config.colors = {
  tab_bar = {
    background = '#1a1b26',
    active_tab = {
      bg_color = '#7aa2f7',
      fg_color = '#1a1b26',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#3b4261',
      fg_color = '#9da5b4',
    },
    inactive_tab_hover = {
      bg_color = '#565f89',
      fg_color = '#c0caf5',
    },
    new_tab = {
      bg_color = '#1a1b26',
      fg_color = '#9da5b4',
    },
    new_tab_hover = {
      bg_color = '#3b4261',
      fg_color = '#c0caf5',
    },
  },
}

-- 성능 최적화 설정
config.audible_bell = 'Disabled'
config.check_for_updates = false
config.automatically_reload_config = true

-- SSH/tmux 복사-붙여넣기 최적화
config.selection_word_boundary = " \t\n{}[]()\"'`,;:@"
config.bypass_mouse_reporting_modifiers = 'ALT'  -- Alt+마우스로 터미널 마우스 모드 우회

-- 애니메이션 최적화 (CPU 렌더링용)
config.animation_fps = 1
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'
config.cursor_blink_rate = 0  -- 커서 깜빡임 비활성화로 성능 향상

-- 렌더링 최적화
config.front_end = 'WebGpu'  -- GPU 가속 사용
config.max_fps = 60  -- FPS 제한으로 배터리 절약

return config
