# Documentation Completeness Tests
# TDD for Phase 4 Sprint 4.3 - Documentation and guides

{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "documentation-completeness-test"
{
  buildInputs = with pkgs; [ bash coreutils findutils ];
} ''
  echo "🧪 Documentation Completeness Tests"
  echo "=================================="

  # Test 1: Core documentation files exist
  echo ""
  echo "📋 Test 1: Core Documentation Files"
  echo "----------------------------------"

  docs_dir="${src}/docs"
  core_docs_found=0

  # Expected core documentation files
  expected_docs=(
    "ARCHITECTURE.md"
    "DEVELOPMENT.md"
    "CONFIGURATION.md"
    "API_REFERENCE.md"
    "TROUBLESHOOTING.md"
  )

  if [[ -d "$docs_dir" ]]; then
    echo "✅ Documentation directory exists"
    for doc_file in "''${expected_docs[@]}"; do
      if [[ -f "$docs_dir/$doc_file" ]]; then
        echo "✅ Found: $doc_file"
        core_docs_found=$((core_docs_found + 1))
      else
        echo "❌ Missing: $doc_file"
      fi
    done
  else
    echo "❌ Documentation directory missing"
    exit 1
  fi

  if [[ $core_docs_found -ge 3 ]]; then
    echo "✅ Sufficient core documentation found: $core_docs_found/''${#expected_docs[@]}"
  else
    echo "❌ Insufficient core documentation: $core_docs_found/''${#expected_docs[@]}"
    exit 1
  fi

  # Test 2: Architecture documentation completeness
  echo ""
  echo "📋 Test 2: Architecture Documentation"
  echo "-----------------------------------"

  arch_doc="${src}/docs/ARCHITECTURE.md"
  if [[ -f "$arch_doc" ]]; then
    echo "✅ Architecture documentation exists"

    # Check for key sections
    arch_sections=0
    sections=(
      "System Overview"
      "Directory Structure"
      "Configuration System"
      "Build Process"
      "Testing Framework"
    )

    for section in "''${sections[@]}"; do
      if grep -q "$section" "$arch_doc"; then
        echo "✅ Found section: $section"
        arch_sections=$((arch_sections + 1))
      else
        echo "❌ Missing section: $section"
      fi
    done

    if [[ $arch_sections -ge 3 ]]; then
      echo "✅ Architecture documentation is comprehensive"
    else
      echo "❌ Architecture documentation incomplete: $arch_sections/''${#sections[@]} sections"
      exit 1
    fi
  else
    echo "❌ Architecture documentation missing"
    exit 1
  fi

  # Test 3: Development guide completeness
  echo ""
  echo "📋 Test 3: Development Guide"
  echo "---------------------------"

  dev_doc="${src}/docs/DEVELOPMENT.md"
  if [[ -f "$dev_doc" ]]; then
    echo "✅ Development guide exists"

    # Check for essential development topics
    dev_topics=0
    topics=(
      "Getting Started"
      "TDD Workflow"
      "Code Standards"
      "Testing Guidelines"
      "Contributing"
    )

    for topic in "''${topics[@]}"; do
      if grep -qi "$topic" "$dev_doc"; then
        echo "✅ Found topic: $topic"
        dev_topics=$((dev_topics + 1))
      else
        echo "❌ Missing topic: $topic"
      fi
    done

    if [[ $dev_topics -ge 3 ]]; then
      echo "✅ Development guide is comprehensive"
    else
      echo "❌ Development guide incomplete: $dev_topics/''${#topics[@]} topics"
      exit 1
    fi
  else
    echo "❌ Development guide missing"
    exit 1
  fi

  # Test 4: Configuration documentation
  echo ""
  echo "📋 Test 4: Configuration Documentation"
  echo "------------------------------------"

  config_doc="${src}/docs/CONFIGURATION.md"
  if [[ -f "$config_doc" ]]; then
    echo "✅ Configuration documentation exists"

    # Check for configuration topics
    config_topics=0
    topics=(
      "Configuration Files"
      "Environment Variables"
      "Platform Settings"
      "Cache Configuration"
      "Network Settings"
    )

    for topic in "''${topics[@]}"; do
      if grep -qi "$topic" "$config_doc"; then
        echo "✅ Found topic: $topic"
        config_topics=$((config_topics + 1))
      fi
    done

    if [[ $config_topics -ge 3 ]]; then
      echo "✅ Configuration documentation is comprehensive"
    else
      echo "❌ Configuration documentation incomplete: $config_topics/''${#topics[@]} topics"
      exit 1
    fi
  else
    echo "❌ Configuration documentation missing"
    exit 1
  fi

  # Test 5: Code documentation (inline comments)
  echo ""
  echo "📋 Test 5: Code Documentation Quality"
  echo "-----------------------------------"

  # Check for well-documented critical files
  documented_files=0

  # Check configuration loader
  config_loader="${src}/scripts/lib/config-loader.sh"
  if [[ -f "$config_loader" ]]; then
    comment_lines=$(grep -c '^#' "$config_loader" || echo 0)
    total_lines=$(wc -l < "$config_loader")
    comment_ratio=$((comment_lines * 100 / total_lines))

    if [[ $comment_ratio -ge 15 ]]; then
      echo "✅ config-loader.sh is well documented ($comment_ratio% comments)"
      documented_files=$((documented_files + 1))
    else
      echo "❌ config-loader.sh needs better documentation ($comment_ratio% comments)"
    fi
  fi

  # Check cache management
  cache_mgmt="${src}/scripts/lib/cache-management.sh"
  if [[ -f "$cache_mgmt" ]]; then
    comment_lines=$(grep -c '^#' "$cache_mgmt" || echo 0)
    total_lines=$(wc -l < "$cache_mgmt")
    comment_ratio=$((comment_lines * 100 / total_lines))

    if [[ $comment_ratio -ge 10 ]]; then
      echo "✅ cache-management.sh is documented ($comment_ratio% comments)"
      documented_files=$((documented_files + 1))
    fi
  fi

  if [[ $documented_files -ge 1 ]]; then
    echo "✅ Code documentation quality is adequate"
  else
    echo "❌ Code documentation needs improvement"
    exit 1
  fi

  # Test 6: README completeness
  echo ""
  echo "📋 Test 6: README Completeness"
  echo "-----------------------------"

  readme="${src}/README.md"
  if [[ -f "$readme" ]]; then
    echo "✅ README.md exists"

    # Check for essential README sections
    readme_sections=0
    sections=(
      "Installation"
      "Usage"
      "Configuration"
      "Contributing"
      "License"
    )

    for section in "''${sections[@]}"; do
      if grep -qi "$section" "$readme"; then
        readme_sections=$((readme_sections + 1))
      fi
    done

    if [[ $readme_sections -ge 3 ]]; then
      echo "✅ README is comprehensive"
    else
      echo "❌ README needs improvement: $readme_sections/''${#sections[@]} sections"
      exit 1
    fi
  else
    echo "❌ README.md missing"
    exit 1
  fi

  echo ""
  echo "🎉 All Documentation Completeness Tests Completed!"
  echo "================================================="
  echo ""
  echo "Summary:"
  echo "- Core documentation files: ✅"
  echo "- Architecture documentation: ✅"
  echo "- Development guide: ✅"
  echo "- Configuration documentation: ✅"
  echo "- Code documentation quality: ✅"
  echo "- README completeness: ✅"

  touch $out
''
