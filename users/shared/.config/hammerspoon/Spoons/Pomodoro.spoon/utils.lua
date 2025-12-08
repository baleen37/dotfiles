-- utils.lua
local utils = {}

function utils.safeCall(fn, ...)
    local success, result = pcall(fn, ...)
    if success then
        return { success = true, result = result }
    else
        return { success = false, error = result }
    end
end

function utils.validateSettings(settings)
    if type(settings) ~= "table" then
        return false, "Settings must be a table"
    end

    -- Validate work duration
    if settings.workDuration and (type(settings.workDuration) ~= "number" or settings.workDuration <= 0) then
        return false, "workDuration must be a positive number"
    end

    -- Validate break duration
    if settings.breakDuration and (type(settings.breakDuration) ~= "number" or settings.breakDuration <= 0) then
        return false, "breakDuration must be a positive number"
    end

    return true, "Settings valid"
end

function utils.showError(message)
    hs.notify.new({
        title = "Pomodoro Error",
        informativeText = message
    }):send()
    print("[Pomodoro Error] " .. message)
end

function utils.showInfo(message)
    hs.notify.new({
        title = "Pomodoro",
        informativeText = message
    }):send()
    print("[Pomodoro] " .. message)
end

return utils