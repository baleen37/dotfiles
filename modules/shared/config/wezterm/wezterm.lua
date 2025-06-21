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

-- Mouse bindings
config.mouse_bindings = {
  -- Cmd+click opens hyperlinks
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = wezterm.action.OpenLinkAtMouseCursor,
  },
  -- Cmd+click drag for selecting
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = wezterm.action.SelectTextAtMouseCursor 'Cell',
  },
  -- Right click paste
  {
    event = { Up = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'Clipboard',
  },
  -- Middle click paste (useful for 3-button mice)
  {
    event = { Up = { streak = 1, button = 'Middle' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom 'PrimarySelection',
  },
  -- Shift+click extend selection
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'SHIFT',
    action = wezterm.action.ExtendSelectionToMouseCursor 'Cell',
  },
  -- Double-click select word
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.SelectTextAtMouseCursor 'Word',
  },
  -- Triple-click select line
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    action = wezterm.action.SelectTextAtMouseCursor 'Line',
  },
  -- Ctrl+scroll for zoom
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = 'CTRL',
    action = wezterm.action.IncreaseFontSize,
  },
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = 'CTRL',
    action = wezterm.action.DecreaseFontSize,
  },
}

return config
