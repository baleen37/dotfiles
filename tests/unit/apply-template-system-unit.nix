# TDD Test for Apply Template System
# Tests that the template system can replace individual apply scripts

{ pkgs, ... }:

let
  # Test that template system works correctly
  testApplyTemplateSystem = pkgs.runCommand "test-apply-template-system" {
    buildInputs = [ pkgs.bash pkgs.gnugrep ];
  } ''
    echo "=== Testing Apply Template System ==="

    # Test 1: Template directory should exist
    if [ -d ${../../scripts/templates} ]; then
      echo "✅ Templates directory exists"

      # Test 2: Apply template should exist and be functional
      if [ -f ${../../scripts/templates/apply-template.sh} ]; then
        echo "✅ Apply template exists"

        # Test 3: Template should be shorter than original scripts
        TEMPLATE_LINES=$(wc -l < ${../../scripts/templates/apply-template.sh})
        echo "Template has $TEMPLATE_LINES lines"

        # Should be significantly shorter than any individual script
        if [ "$TEMPLATE_LINES" -lt 100 ]; then
          echo "✅ Template is concise ($TEMPLATE_LINES < 100 lines)"
        else
          echo "❌ Template too long: $TEMPLATE_LINES lines"
          exit 1
        fi
      else
        echo "❌ Apply template missing - need to implement"
        exit 1
      fi
    else
      echo "❌ Templates directory missing - need to create"
      exit 1
    fi

    # Test 4: Common utility modules should exist
    echo "=== Testing Common Utility Modules ==="

    for module in ui-utils.sh user-input.sh token-replacement.sh platform-config.sh; do
      if [ -f ${../../scripts/lib}/$module ]; then
        echo "✅ Module exists: $module"
      else
        echo "❌ Module missing: $module - need to implement"
        exit 1
      fi
    done

    # Test 5: Platform config files should exist
    echo "=== Testing Platform Config Files ==="

    for platform in aarch64-darwin x86_64-darwin aarch64-linux x86_64-linux; do
      if [ -f ${../../apps}/$platform/config.sh ]; then
        echo "✅ Platform config exists: $platform"

        # Config should be small (just variables)
        CONFIG_LINES=$(wc -l < ${../../apps}/$platform/config.sh)
        if [ "$CONFIG_LINES" -lt 20 ]; then
          echo "✅ Config is concise: $CONFIG_LINES lines"
        else
          echo "❌ Config too long: $CONFIG_LINES lines"
          exit 1
        fi
      else
        echo "❌ Platform config missing: $platform - need to create"
        exit 1
      fi
    done

    # Test 6: Apply scripts should use template
    echo "=== Testing Apply Script Integration ==="

    for platform in aarch64-darwin x86_64-darwin aarch64-linux x86_64-linux; do
      if [ -f ${../../apps}/$platform/apply ]; then
        # New apply script should be much shorter (just template loader)
        APPLY_LINES=$(wc -l < ${../../apps}/$platform/apply)
        if [ "$APPLY_LINES" -lt 20 ]; then
          echo "✅ Deduplicated apply script: $platform ($APPLY_LINES lines)"
        else
          echo "❌ Apply script still too long: $platform ($APPLY_LINES lines)"
          exit 1
        fi
      else
        echo "❌ Apply script missing: $platform"
        exit 1
      fi
    done

    echo "✅ Apply template system tests completed"

    touch $out
  '';

in testApplyTemplateSystem
