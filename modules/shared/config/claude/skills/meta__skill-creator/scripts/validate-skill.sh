#!/usr/bin/env bash
set -euo pipefail

# validate-skill.sh - Validates Claude skill structure
# Usage: ./validate-skill.sh <skill-directory>

SKILL_DIR="${1:?Error: Skill directory path required}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation results
ERRORS=0
WARNINGS=0

echo "Validating skill: $SKILL_DIR"
echo "---"

# Check SKILL.md exists
if [[ ! -f "$SKILL_DIR/SKILL.md" ]]; then
  echo -e "${RED}✗ Error: SKILL.md not found${NC}"
  exit 1
fi

echo -e "${GREEN}✓ SKILL.md exists${NC}"

# Check line count (500 line limit)
line_count=$(wc -l <"$SKILL_DIR/SKILL.md" | tr -d ' ')
if [[ $line_count -gt 500 ]]; then
  echo -e "${RED}✗ Error: SKILL.md has $line_count lines (max: 500)${NC}"
  ERRORS=$((ERRORS + 1))
elif [[ $line_count -gt 400 ]]; then
  echo -e "${YELLOW}⚠ Warning: SKILL.md has $line_count lines (consider splitting to reference.md at 500)${NC}"
  WARNINGS=$((WARNINGS + 1))
else
  echo -e "${GREEN}✓ Line count: $line_count (within 500 limit)${NC}"
fi

# Check frontmatter exists
if ! grep -q "^---$" "$SKILL_DIR/SKILL.md"; then
  echo -e "${RED}✗ Error: YAML frontmatter not found${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}✓ YAML frontmatter present${NC}"

  # Extract and validate frontmatter fields (only first frontmatter block)
  frontmatter=$(sed -n '1,/^---$/p' "$SKILL_DIR/SKILL.md" | sed -n '/^---$/,/^---$/p')

  # Check for name field
  if ! echo "$frontmatter" | grep -q "^name:"; then
    echo -e "${RED}✗ Error: 'name' field missing in frontmatter${NC}"
    ERRORS=$((ERRORS + 1))
  else
    name=$(echo "$frontmatter" | grep "^name:" | head -1 | sed 's/^name: *//')
    name_length=${#name}
    if [[ $name_length -gt 64 ]]; then
      echo -e "${RED}✗ Error: Name is $name_length characters (max: 64)${NC}"
      ERRORS=$((ERRORS + 1))
    else
      echo -e "${GREEN}✓ Name field valid ($name_length chars)${NC}"
    fi

    # Check for gerund form (ends with -ing)
    if [[ ! "$name" =~ ing ]]; then
      echo -e "${YELLOW}⚠ Warning: Name doesn't appear to use gerund form (verb + -ing)${NC}"
      WARNINGS=$((WARNINGS + 1))
    fi
  fi

  # Check for description field
  if ! echo "$frontmatter" | grep -q "^description:"; then
    echo -e "${RED}✗ Error: 'description' field missing in frontmatter${NC}"
    ERRORS=$((ERRORS + 1))
  else
    description=$(echo "$frontmatter" | grep "^description:" | head -1 | sed 's/^description: *//')
    desc_length=${#description}
    if [[ $desc_length -gt 1024 ]]; then
      echo -e "${RED}✗ Error: Description is $desc_length characters (max: 1024)${NC}"
      ERRORS=$((ERRORS + 1))
    else
      echo -e "${GREEN}✓ Description field valid ($desc_length chars)${NC}"
    fi
  fi
fi

# Check for Windows-style paths
if grep -q '\\' "$SKILL_DIR/SKILL.md" 2>/dev/null; then
  echo -e "${YELLOW}⚠ Warning: Potential Windows-style paths detected (use Unix '/' instead)${NC}"
  WARNINGS=$((WARNINGS + 1))
fi

# Make scripts executable if they exist
if [[ -d "$SKILL_DIR/scripts" ]]; then
  script_count=$(find "$SKILL_DIR/scripts" -type f -name "*.sh" | wc -l | tr -d ' ')
  if [[ $script_count -gt 0 ]]; then
    find "$SKILL_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;
    echo -e "${GREEN}✓ Made $script_count script(s) executable${NC}"
  fi
fi

# Summary
echo "---"
if [[ $ERRORS -gt 0 ]]; then
  echo -e "${RED}Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo -e "${YELLOW}Validation passed with $WARNINGS warning(s)${NC}"
  exit 0
else
  echo -e "${GREEN}All checks passed!${NC}"
  exit 0
fi
