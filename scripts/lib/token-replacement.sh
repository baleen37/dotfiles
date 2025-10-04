#!/bin/sh
# Token Replacement Module for Apply Scripts
# Contains logic for replacing tokens in configuration files

# Replace tokens in a file
replace_tokens_in_file() {
  local file="$1"
  local temp_file=$(mktemp)

  if [ ! -f "$file" ]; then
    _print "${RED}Error: File not found: $file${NC}"
    return 1
  fi

  # Replace common tokens
  sed "s/REPLACE_USERNAME/$USERNAME/g; s/REPLACE_GIT_EMAIL/$GIT_EMAIL/g; s/REPLACE_GIT_NAME/$GIT_NAME/g" "$file" >"$temp_file"

  # Move temp file back to original
  mv "$temp_file" "$file"

  _print "${GREEN}Tokens replaced in: $file${NC}"
}

# Replace tokens in multiple files
replace_tokens() {
  local target_dir="$1"

  if [ ! -d "$target_dir" ]; then
    _print "${RED}Error: Directory not found: $target_dir${NC}"
    return 1
  fi

  _print "${YELLOW}Replacing tokens in configuration files...${NC}"

  # Find and process configuration files
  find "$target_dir" -type f \( -name "*.nix" -o -name "*.conf" -o -name "*.toml" \) | while read -r file; do
    if grep -q "REPLACE_" "$file"; then
      replace_tokens_in_file "$file"
    fi
  done

  _print "${GREEN}Token replacement completed${NC}"
}
