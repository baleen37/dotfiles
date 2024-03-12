
toggleApp = function(appName, launch)
    launch = launch or false
    local app = hs.application.get(appName)
    if app then
        if app:isFrontmost() then
            app:hide()
        else
            app:activate()
        end
    else
        if launch then
            hs.application.launchOrFocus(appName)
        else
            hs.alert.show("App '" .. appName .. "' is not loaded!")
        end
    end
  end
  
  hs.hotkey.bind({"cmd", "shift", "ctrl"}, "o", function() toggleApp("obsidian") end)
  hs.hotkey.bind({"cmd", "shift", "ctrl"}, "i", function() toggleApp("iTerm") end)
  hs.hotkey.bind({"cmd", "shift", "ctrl"}, "t", function() toggleApp("Things") end)