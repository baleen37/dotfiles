-- timer.lua
local Timer = {}
Timer.__index = Timer

-- Create a new timer with safe error handling
function Timer.createTimer(duration, onTick, onComplete)
    if not duration or type(duration) ~= "number" or duration <= 0 then
        return { success = false, error = "Invalid duration: must be a positive number" }
    end

    if not onTick or type(onTick) ~= "function" then
        return { success = false, error = "Invalid onTick: must be a function" }
    end

    if not onComplete or type(onComplete) ~= "function" then
        return { success = false, error = "Invalid onComplete: must be a function" }
    end

    local utils = require("utils")

    -- Create timer with safe error handling
    local timerResult = utils.safeCall(function()
        return hs.timer.new(1, function()
            duration = duration - 1

            -- Call onTick callback with remaining time
            onTick(duration)

            -- Check if timer has completed
            if duration <= 0 then
                onComplete()
                return false  -- Stop the timer
            end

            return true  -- Continue the timer
        end)
    end)

    if not timerResult.success then
        return { success = false, error = timerResult.error }
    end

    return { success = true, timer = timerResult.result }
end

return Timer