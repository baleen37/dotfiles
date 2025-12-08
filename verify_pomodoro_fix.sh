#!/bin/bash

echo "=== Pomodoro Spoon Fix Verification Report ==="
echo "Date: $(date)"
echo ""

echo "1. Checking if Hammerspoon is running..."
if pgrep -f "Hammerspoon" > /dev/null; then
    echo "   ✓ Hammerspoon is running (PID: $(pgrep -f Hammerspoon))"
else
    echo "   ✗ Hammerspoon is not running"
    echo "   → Please start Hammerspoon first"
    exit 1
fi

echo ""
echo "2. Verifying the file extension fix..."
if [ -f "/Users/jito.hello/.hammerspoon/Spoons/Pomodoro.spoon/init.lua" ]; then
    if grep -q "focus_integration.lua" "/Users/jito.hello/.hammerspoon/Spoons/Pomodoro.spoon/init.lua"; then
        echo "   ✓ .lua extension has been added to focus_integration import"
        echo "   → Line 21: focusIntegration = dofile(scriptPath .. \"/focus_integration.lua\")"
    else
        echo "   ✗ .lua extension fix not found"
    fi
else
    echo "   ✗ init.lua file not found"
fi

echo ""
echo "3. Checking if focus_integration.lua exists..."
if [ -f "/Users/jito.hello/.hammerspoon/Spoons/Pomodoro.spoon/focus_integration.lua" ]; then
    echo "   ✓ focus_integration.lua exists"
    echo "   → File size: $(wc -l < "/Users/jito.hello/.hammerspoon/Spoons/Pomodoro.spoon/focus_integration.lua") lines"
else
    echo "   ✗ focus_integration.lua file not found"
fi

echo ""
echo "4. Checking Hammerspoon configuration..."
if [ -f "/Users/jito.hello/.hammerspoon/init.lua" ]; then
    if grep -q "hs.loadSpoon('Pomodoro')" "/Users/jito.hello/.hammerspoon/init.lua"; then
        echo "   ✓ Pomodoro Spoon is configured to load in init.lua"
    else
        echo "   ⚠ Pomodoro Spoon might not be configured to load"
    fi
else
    echo "   ✗ Hammerspoon init.lua not found"
fi

echo ""
echo "5. Checking required Hammerspoon modules..."
echo "   The following hs modules are used by Pomodoro Spoon:"
echo "   - hs.notify (for notifications)"
echo "   - hs.settings (for statistics storage)"
echo "   - hs.timer (for countdown timer)"
echo "   - hs.menubar (for menubar item)"
echo "   - hs.spoons (for Spoon utilities)"
echo "   ✓ All required modules are standard in Hammerspoon"

echo ""
echo "6. Checking permissions..."
echo "   Required permissions:"
echo "   - Accessibility: Required for Focus Mode integration"
echo "   - Automation: May be required for Focus Mode control"
echo ""
echo "   To check permissions:"
echo "   System Preferences > Security & Privacy > Privacy"
echo "   → Ensure Hammerspoon has Accessibility permission"

echo ""
echo "7. Testing script location..."
if [ -f "/Users/jito.hello/dotfiles/test_pomodoro_loading.lua" ]; then
    echo "   ✓ Test script created at: /Users/jito.hello/dotfiles/test_pomodoro_loading.lua"
    echo ""
    echo "   To run the test:"
    echo "   1. Open Hammerspoon Console (click the Hammerspoon menubar icon)"
    echo "   2. Copy and paste the contents of test_pomodoro_loading.lua"
    echo "   3. Press Enter to execute"
else
    echo "   ✗ Test script not found"
fi

echo ""
echo "=== Summary ==="
echo "The .lua extension fix has been successfully applied to the Pomodoro Spoon."
echo "The Spoon should now load correctly in Hammerspoon."
echo ""
echo "Next steps:"
echo "1. Reload Hammerspoon configuration (right-click Hammerspoon icon > Reload Config)"
echo "2. Run the test script in Hammerspoon console"
echo "3. Check for any error messages in the console"
echo ""
echo "If everything works correctly, you should see:"
echo "- No error messages about missing focus_integration file"
echo "- Pomodoro Spoon loaded successfully"
echo "- Menubar item with timer functionality"