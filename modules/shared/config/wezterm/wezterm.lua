local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- Color scheme
config.color_scheme = 'Catppuccin Mocha'

-- Font configuration with fallback for CJK characters
config.font = wezterm.font_with_fallback({
  'JetBrains Mono',
  'SF Mono',
  'Menlo',
  'Hiragino Sans',
  'Hiragino Kaku Gothic ProN',
  'Apple SD Gothic Neo',
  'PingFang SC',
  'PingFang TC',
  'Apple Color Emoji',
})
config.font_size = 14.0

-- Unicode handling
config.unicode_version = 14

-- Window configuration
config.window_decorations = 'RESIZE'
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

-- Tab bar
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false

-- Performance
config.enable_wayland = false

-- Key bindings
config.keys = {
  -- Tab navigation
  {
    key = '{',
    mods = 'ALT|SHIFT',
    action = wezterm.action.MoveTabRelative(-1),
  },
  {
    key = '}',
    mods = 'ALT|SHIFT',
    action = wezterm.action.MoveTabRelative(1),
  },
}

return config
