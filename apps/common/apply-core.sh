#!/usr/bin/env bash
# Common apply logic shared across all platforms

# Colors for output
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Common apply functions
load_platform_config() {
  local target_name="$1"
  local target_config
  target_config="$(dirname "$0")/targets/${target_name}.sh"

  if [ -f "$target_config" ]; then
    # shellcheck source=/dev/null
    source "$target_config"
    echo -e "${GREEN}Loaded configuration for ${target_name}${NC}"
  else
    echo -e "${RED}Target configuration not found: ${target_config}${NC}"
    return 1
  fi
}

# Common apply template execution
execute_apply_template() {
  local script_dir="$1"
  local apply_template="${script_dir}/../../scripts/templates/apply-template.sh"

  if [ -f "$apply_template" ]; then
    echo -e "${YELLOW}Executing apply template...${NC}"
    bash "$apply_template"
  else
    echo -e "${RED}Apply template not found: ${apply_template}${NC}"
    return 1
  fi
}

# Main apply orchestrator
run_apply() {
  local script_dir
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  local target_name
  target_name="$(basename "$(dirname "$script_dir")")"

  echo -e "${YELLOW}Starting apply process for ${target_name}...${NC}"

  # Load target-specific configuration
  load_platform_config "$target_name"

  # Execute the apply template
  execute_apply_template "$script_dir"

  echo -e "${GREEN}Apply process completed successfully!${NC}"
}
