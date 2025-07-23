# iTerm2 to WezTerm Migration Plan

## Overview
This plan outlines the migration from iTerm2 to WezTerm in the dotfiles system, maintaining all current functionality while taking advantage of WezTerm's improved features and Lua-based configuration.

## Phase 1: Analysis and Foundation ✅

### 1.1 Current State Analysis ✅
- **Current iTerm2 Configuration**: `modules/darwin/config/iterm2/DynamicProfiles.json`
- **File Structure**: Nix-managed dotfiles with configuration files copied to appropriate locations
- **Current Features**:
  - Custom color scheme (dark theme)
  - MesloLGS-NF font family
  - Keyboard mappings for Ctrl+Shift+Arrow keys
  - Terminal settings (scrollback, transparency, etc.)

### 1.2 WezTerm Configuration Structure ✅
- **Config Location**: `~/.config/wezterm/wezterm.lua` or `~/.wezterm.lua`
- **Language**: Lua-based configuration
- **Features**: Dynamic configuration, better performance, cross-platform

## Phase 2: WezTerm Setup and Configuration

### 2.1 Create WezTerm Configuration Structure
```
Task 2.1: Create WezTerm configuration directory and base files
- Create modules/darwin/config/wezterm/ directory
- Create wezterm.lua base configuration file
- Set up proper Lua structure with wezterm.config_builder()
```

### 2.2 iTerm2 to WezTerm Color Scheme Migration
```
Task 2.2: Convert iTerm2 color scheme to WezTerm format
- Map ANSI colors from iTerm2 JSON to WezTerm Lua color scheme
- Convert background (#000000), foreground (#ffffff), cursor colors
- Preserve selection color and transparency settings
- Create custom color scheme named 'iTerm2-Dark'
```

### 2.3 Font Configuration Migration
```
Task 2.3: Configure fonts to match iTerm2 settings
- Set primary font: MesloLGS-NF-Regular
- Set bold font: MesloLGS-NF-Bold  
- Set font size: 14pt
- Configure font rendering options (anti-aliasing, etc.)
```

### 2.4 Key Bindings Migration
```
Task 2.4: Convert iTerm2 key mappings to WezTerm format
- Map Ctrl+Shift+Arrow keys (0xf700-0x260000 → [1;6A format)
- Convert Home/End key mappings (0xf729-0x40000, 0xf72b-0x40000)
- Ensure proper terminal sequence output
```

### 2.5 Terminal Settings Migration
```
Task 2.5: Migrate terminal behavior settings
- Set scrollback_lines = 10000
- Configure window transparency (0.1 alpha)
- Set terminal type to xterm-256color
- Configure initial window size (80x25)
- Enable mouse reporting features
```

## Phase 3: Nix Integration

### 3.1 Package Management Update
```
Task 3.1: Update package installations
- Replace "iterm2" with "wezterm" in modules/darwin/casks.nix
- Verify WezTerm availability in homebrew casks
- Test installation process
```

### 3.2 File Deployment Configuration
```
Task 3.2: Update Nix file deployment
- Modify modules/darwin/files.nix:
  - Remove iTerm2 DynamicProfiles path
  - Add WezTerm configuration path: ${xdg_configHome}/wezterm/wezterm.lua
- Ensure proper file permissions and ownership
```

### 3.3 Build System Integration
```
Task 3.3: Test and validate build process
- Run nix build to verify configuration
- Test darwin-rebuild switch process
- Verify no broken references or missing files
```

## Phase 4: Testing and Validation

### 4.1 Basic Functionality Testing
```
Task 4.1: Verify core WezTerm functionality
- Launch WezTerm and verify it starts correctly
- Test color scheme displays properly
- Confirm font rendering matches iTerm2
- Verify window transparency works
```

### 4.2 Key Binding Testing
```
Task 4.2: Test all keyboard shortcuts
- Test Ctrl+Shift+Arrow key navigation
- Verify Home/End key behavior
- Test any custom key combinations
- Confirm terminal sequences are correct
```

### 4.3 Integration Testing
```
Task 4.3: Test with existing workflow
- Verify tmux integration works
- Test with shell configurations (zsh, p10k)
- Check development workflow compatibility
- Test with any Hammerspoon integrations
```

## Phase 5: Documentation and Cleanup

### 5.1 Documentation Updates
```
Task 5.1: Update project documentation
- Add WezTerm migration notes to relevant docs
- Update installation instructions
- Document any behavioral differences
```

### 5.2 Configuration Cleanup
```
Task 5.2: Clean up old references
- Keep iTerm2 config as backup but comment out in files.nix
- Remove any iTerm2-specific scripts or references
- Update any documentation that mentions iTerm2
```

## Detailed Implementation Steps

### Step 1: WezTerm Configuration Creation
Create a Lua configuration that mirrors iTerm2 settings:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Color scheme (converted from iTerm2)
config.color_schemes = {
  ['iTerm2-Dark'] = {
    foreground = '#ffffff',
    background = '#000000',
    cursor_bg = '#ffffff',
    cursor_fg = '#000000',
    selection_bg = '#333333',
    ansi = {
      '#000000', -- black
      '#cc0000', -- red  (0.8 -> cc)
      '#00cc00', -- green
      '#cccc00', -- yellow
      '#0000cc', -- blue
      '#cc00cc', -- magenta
      '#00cccc', -- cyan
      '#cccccc', -- white
    },
    brights = {
      '#666666', -- bright black (0.4 -> 66)
      '#ff0000', -- bright red
      '#00ff00', -- bright green  
      '#ffff00', -- bright yellow
      '#0000ff', -- bright blue
      '#ff00ff', -- bright magenta
      '#00ffff', -- bright cyan
      '#ffffff', -- bright white
    },
  },
}

config.color_scheme = 'iTerm2-Dark'
config.font = wezterm.font('MesloLGS NF')
config.font_size = 14
config.scrollback_lines = 10000
config.window_background_opacity = 0.9
config.initial_cols = 80
config.initial_rows = 25

-- Key bindings
config.keys = {
  -- Ctrl+Shift+Arrow mappings
  { key = 'UpArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6A' },
  { key = 'DownArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6B' },
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6D' },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = wezterm.action.SendString '\x1b[1;6C' },
  { key = 'Home', mods = 'CTRL', action = wezterm.action.SendString '\x1b[1;5H' },
  { key = 'End', mods = 'CTRL', action = wezterm.action.SendString '\x1b[1;5F' },
}

return config
```

### Step 2: Nix Configuration Updates

Update `modules/darwin/casks.nix`:
```nix
_:

[
  # Development Tools
  "datagrip"  # Database IDE from JetBrains
  "docker-desktop"
  "intellij-idea"
  "wezterm"  # Terminal emulator (replaced iterm2)

  # ... rest unchanged
]
```

Update `modules/darwin/files.nix`:
```nix
{ user, config, pkgs, ... }:

let
  userHome = "${config.users.users.${user}.home}";
  xdg_configHome = "${config.users.users.${user}.home}/.config";
  xdg_dataHome = "${config.users.users.${user}.home}/.local/share";
  xdg_stateHome = "${config.users.users.${user}.home}/.local/state";
in
{
  # ... existing configurations ...

  # WezTerm configuration (replaced iTerm2)
  "${xdg_configHome}/wezterm/wezterm.lua" = {
    source = ./config/wezterm/wezterm.lua;
  };

  # Keep iTerm2 config commented for backup
  # "${userHome}/Library/Application Support/iTerm2/DynamicProfiles/DynamicProfiles.json" = {
  #   source = ./config/iterm2/DynamicProfiles.json;
  # };
}
```

## Risk Assessment and Mitigation

### Potential Risks
1. **Font rendering differences**: WezTerm may render fonts slightly differently
2. **Key binding behavior**: Some terminal sequences might behave differently
3. **Performance characteristics**: Different memory/CPU usage patterns
4. **Third-party integration**: Tools expecting iTerm2 specifically

### Mitigation Strategies
1. **Side-by-side testing**: Keep both terminals available during transition
2. **Gradual rollout**: Test thoroughly in development before production use
3. **Backup configuration**: Maintain iTerm2 config for quick rollback
4. **Documentation**: Clear notes on differences for troubleshooting

## Success Criteria
- [ ] WezTerm launches and displays correctly
- [ ] All colors match or improve upon iTerm2 appearance  
- [ ] Key bindings work identically to iTerm2
- [ ] Font rendering is acceptable
- [ ] Performance is equal or better
- [ ] Integration with existing tools maintained
- [ ] Build/deployment process works correctly

## Timeline Estimate
- **Phase 1**: ✅ Complete (30 minutes)
- **Phase 2**: 60 minutes (configuration creation and testing)
- **Phase 3**: 30 minutes (Nix integration)
- **Phase 4**: 45 minutes (comprehensive testing)  
- **Phase 5**: 15 minutes (cleanup and documentation)
- **Total**: ~3 hours with buffer for unexpected issues
