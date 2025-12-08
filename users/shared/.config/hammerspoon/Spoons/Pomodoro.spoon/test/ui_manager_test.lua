-- test/ui_manager_test.lua
local UIManager = require("ui_manager")
local utils = require("utils")

function testUIManagerCreation()
    local ui = UIManager:new()
    assert(ui ~= nil, "UIManager should be created")
    assert(ui:getMenuBarItem() == nil, "Initial menubar should be nil")
    print("✓ UIManager creation test passed")
end

function testUpdateMenuBarText()
    local ui = UIManager:new()
    local mockItem = { setTitle = function() end }
    ui:setMenuBarItem(mockItem)

    -- Should not error
    ui:updateMenuBarText("Work", 1500)
    print("✓ UpdateMenuBarText test passed")
end

function testUpdateMenuBarTextWithoutItem()
    local ui = UIManager:new()

    -- Should not error even without menubar item
    ui:updateMenuBarText("Work", 1500)
    print("✓ UpdateMenuBarText without item test passed")
end

function testUpdateMenu()
    local ui = UIManager:new()
    local mockItem = {
        setMenu = function() end,
        setTitle = function() end
    }
    ui:setMenuBarItem(mockItem)

    -- Mock state
    local mockState = {
        isRunning = function() return false end,
        isBreak = function() return false end,
        getTimeLeft = function() return 1500 end
    }

    -- Mock obj with methods
    _G.obj = {
        startSession = function() end,
        stopSession = function() end,
        reset = function() end
    }

    -- Should not error
    ui:updateMenu(mockState)
    ui:updateMenuBarText("Work", 1500)

    -- Cleanup global
    _G.obj = nil

    print("✓ UpdateMenu test passed")
end

function testUpdateMenuRunning()
    local ui = UIManager:new()
    local mockItem = {
        setMenu = function() end,
        setTitle = function() end
    }
    ui:setMenuBarItem(mockItem)

    -- Mock state (running)
    local mockState = {
        isRunning = function() return true end,
        isBreak = function() return false end,
        getTimeLeft = function() return 1500 end
    }

    -- Mock obj with methods
    _G.obj = {
        startSession = function() end,
        stopSession = function() end,
        reset = function() end
    }

    -- Should not error
    ui:updateMenu(mockState)

    -- Cleanup global
    _G.obj = nil

    print("✓ UpdateMenu running test passed")
end

-- Run tests
testUIManagerCreation()
testUpdateMenuBarText()
testUpdateMenuBarTextWithoutItem()
testUpdateMenu()
testUpdateMenuRunning()
print("All UIManager tests passed!")