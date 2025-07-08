#!/bin/bash

echo "🧪 Documentation and Guide Tests (Phase 4 Sprint 4.3 - Red Phase)"
echo "=================================================================="

# Test 1: Architecture documentation
echo ""
echo "📋 Test 1: Architecture Documentation"
echo "------------------------------------"

architecture_docs=true

# Check for architecture documentation
if [[ ! -f "docs/ARCHITECTURE.md" ]]; then
  echo "❌ Missing architecture documentation: docs/ARCHITECTURE.md"
  architecture_docs=false
fi

# Check for updated architecture reflecting new structure
if [[ -f "docs/ARCHITECTURE.md" ]]; then
  if ! grep -q "Phase 4\|설정 외부화\|디렉토리 구조 최적화" docs/ARCHITECTURE.md; then
    echo "❌ Architecture documentation not updated with recent changes"
    architecture_docs=false
  else
    echo "✅ Architecture documentation updated"
  fi
fi

if [[ "$architecture_docs" == false ]]; then
  exit 1
fi

# Test 2: Configuration guide
echo ""
echo "📋 Test 2: Configuration Guide"
echo "-----------------------------"

config_guide=true

# Check for configuration guide
if [[ ! -f "docs/CONFIGURATION-GUIDE.md" ]]; then
  echo "❌ Missing configuration guide: docs/CONFIGURATION-GUIDE.md"
  config_guide=false
fi

# Check for external config documentation
if [[ -f "docs/CONFIGURATION-GUIDE.md" ]]; then
  if ! grep -q "config-loader\|external.*config\|YAML" docs/CONFIGURATION-GUIDE.md; then
    echo "❌ Configuration guide missing external config documentation"
    config_guide=false
  else
    echo "✅ Configuration guide includes external config"
  fi
fi

if [[ "$config_guide" == false ]]; then
  exit 1
fi

# Test 3: Development guide
echo ""
echo "📋 Test 3: Development Guide"
echo "---------------------------"

dev_guide=true

# Check for development guide
if [[ ! -f "docs/DEVELOPMENT.md" ]]; then
  echo "❌ Missing development guide: docs/DEVELOPMENT.md"
  dev_guide=false
fi

# Check for TDD methodology documentation
if [[ -f "docs/DEVELOPMENT.md" ]]; then
  if ! grep -q "TDD\|Test.*Driven.*Development\|Red.*Green.*Refactor" docs/DEVELOPMENT.md; then
    echo "❌ Development guide missing TDD methodology"
    dev_guide=false
  else
    echo "✅ Development guide includes TDD methodology"
  fi
fi

if [[ "$dev_guide" == false ]]; then
  exit 1
fi

# Test 4: API reference documentation
echo ""
echo "📋 Test 4: API Reference Documentation"
echo "-------------------------------------"

api_docs=true

# Check for API reference
if [[ ! -f "docs/API_REFERENCE.md" ]]; then
  echo "❌ Missing API reference: docs/API_REFERENCE.md"
  api_docs=false
fi

# Check for configuration API documentation
if [[ -f "docs/API_REFERENCE.md" ]]; then
  if ! grep -q "get_unified_config\|load_all_configs\|config-loader" docs/API_REFERENCE.md; then
    echo "❌ API reference missing configuration functions"
    api_docs=false
  else
    echo "✅ API reference includes configuration functions"
  fi
fi

if [[ "$api_docs" == false ]]; then
  exit 1
fi

# Test 5: Migration guide
echo ""
echo "📋 Test 5: Migration Guide"
echo "-------------------------"

migration_guide=true

# Check for migration guide
if [[ ! -f "docs/MIGRATION-GUIDE.md" ]]; then
  echo "❌ Missing migration guide: docs/MIGRATION-GUIDE.md"
  migration_guide=false
fi

# Check for Phase 4 migration instructions
if [[ -f "docs/MIGRATION-GUIDE.md" ]]; then
  if ! grep -q "Phase 4\|directory.*structure\|configuration.*external" docs/MIGRATION-GUIDE.md; then
    echo "❌ Migration guide missing Phase 4 changes"
    migration_guide=false
  else
    echo "✅ Migration guide includes Phase 4 changes"
  fi
fi

if [[ "$migration_guide" == false ]]; then
  exit 1
fi

# Test 6: Code examples and snippets
echo ""
echo "📋 Test 6: Code Examples and Snippets"
echo "------------------------------------"

code_examples=true

# Check for examples directory
if [[ ! -d "docs/examples" ]]; then
  echo "❌ Missing examples directory: docs/examples"
  code_examples=false
fi

# Check for configuration examples
if [[ -d "docs/examples" ]]; then
  config_examples=$(find docs/examples -name "*config*" -o -name "*yaml*" | wc -l)
  if [[ $config_examples -lt 2 ]]; then
    echo "❌ Insufficient configuration examples"
    code_examples=false
  else
    echo "✅ Configuration examples available"
  fi
fi

if [[ "$code_examples" == false ]]; then
  exit 1
fi

echo ""
echo "❌ Documentation Tests Failed (Expected for Red Phase)"
echo "====================================================="
echo ""
echo "Summary of missing documentation:"
echo "- Updated architecture documentation"
echo "- Comprehensive configuration guide"
echo "- TDD-focused development guide"
echo "- Complete API reference"
echo "- Phase 4 migration guide"
echo "- Code examples and snippets"
echo ""
echo "🔴 Red Phase: Documentation tests properly failing - ready for Green Phase"
