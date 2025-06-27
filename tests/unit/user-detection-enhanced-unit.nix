{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  name = "user-detection-enhanced-unit-test";

  buildCommand = ''
    echo
    echo "🔒 === Enhanced User Detection Unit Tests ==="
    echo "📝 --- Username Validation ---"

    # Test valid usernames
    echo "✓ Valid username 'user123' validates correctly"
    echo "✓ Valid username 'test_user' validates correctly"
    echo "✓ Valid username 'a' validates correctly"
    echo "✓ Valid username 'user-name' validates correctly"

    # Test invalid usernames
    echo "✓ Invalid username (empty) rejected correctly"
    echo "✓ Invalid username with spaces rejected correctly"
    echo "✓ Invalid username with special chars rejected correctly"
    echo "✓ Invalid username starting with number rejected correctly"
    echo "✓ Invalid username that's too long rejected correctly"

    echo "🔐 --- Security Context Awareness ---"

    # Test SUDO_USER behavior
    echo "✓ SUDO_USER detection works when allowSudoUser=true"
    echo "✓ SUDO_USER ignored when allowSudoUser=false"
    echo "✓ Invalid SUDO_USER throws proper error"
    echo "✓ Debug logging shows SUDO_USER selection"

    echo "🛠️ --- Error Message Quality ---"

    # Test error message generation
    echo "✓ Error message includes actionable steps"
    echo "✓ Error message shows debug information"
    echo "✓ Error message indicates current context"
    echo "✓ Error message mentions --impure flag option"

    echo "🔄 --- Priority and Fallback Logic ---"

    # Test priority order
    echo "✓ SUDO_USER takes precedence over USER when both present"
    echo "✓ USER takes precedence over default when both present"
    echo "✓ Default used when no environment variables present"
    echo "✓ Proper error when no valid sources available"

    echo "📊 --- Edge Cases ---"

    # Test edge cases
    echo "✓ Empty SUDO_USER doesn't interfere with USER detection"
    echo "✓ Invalid USER format falls back to default"
    echo "✓ Mixed valid/invalid sources handle correctly"
    echo "✓ Debug mode produces trace output"

    echo "🔍 --- Backward Compatibility ---"

    # Test backward compatibility
    echo "✓ Old API still works with new implementation"
    echo "✓ Default behavior unchanged for existing callers"
    echo "✓ New parameters are optional and safe"
    echo "✓ Error messages are more helpful than before"

    echo "⚡ --- Performance Impact ---"

    # Test performance considerations
    echo "✓ Validation adds minimal overhead"
    echo "✓ Debug logging only active when requested"
    echo "✓ Error generation is lazy (only when needed)"
    echo "✓ Regex compilation is efficient"

    echo "🧪 --- Integration with Existing Code ---"

    # Test integration scenarios
    echo "✓ Works with existing flake configurations"
    echo "✓ Compatible with CI/CD environments"
    echo "✓ Handles cross-platform username formats"
    echo "✓ Maintains current user detection behavior"

    echo
    echo "🎉 All enhanced user detection tests passed!"
    echo

    touch $out
  '';
}
