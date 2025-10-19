# Auto-formatting and linting system for dotfiles project
# Provides unified formatting for Nix, shell, YAML, JSON, and Markdown files
# Supports selective formatting by file type or all-in-one formatting
#
# Available Modes:
# - nix: Format Nix files with nixfmt (RFC 166 standard)
# - lint-nix: Lint Nix files with statix and deadnix
# - shell: Format shell scripts with shfmt
# - yaml: Format YAML files with yamlfmt
# - json: Format JSON files with jq
# - markdown: Format Markdown files with prettier
# - all: Format all file types (default)

{ pkgs }:

{
  formatter = pkgs.writeShellApplication {
    name = "dotfiles-format";
    runtimeInputs = with pkgs; [
      nixfmt-rfc-style
      statix
      deadnix
      shfmt
      nodePackages.prettier
      jq
      yamlfmt
    ];

    text = ''
      # Auto-format dotfiles project
      set -e

      MODE="''${1:-all}"

      format_nix() {
        echo "🎨 Formatting Nix files (RFC 166 standard)..."
        find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*" -exec nixfmt {} +
      }

      lint_nix() {
        echo "🔍 Linting Nix files..."
        statix check .
        deadnix --fail .
      }

      format_shell() {
        echo "🎨 Formatting shell scripts..."
        find . -name "*.sh" -not -path "*/.*" -not -path "*/shell-snapshots/*" -exec shfmt -w {} +
      }

      format_yaml() {
        echo "🎨 Formatting YAML files..."
        find . \( -name "*.yaml" -o -name "*.yml" \) -not -path "*/.*" -exec yamlfmt {} +
      }

      format_json() {
        echo "🎨 Formatting JSON files..."
        find . -name "*.json" -not -path "*/.*" -not -path "*/node_modules/*" -exec sh -c 'jq . "$1" > "$1.tmp" && mv "$1.tmp" "$1"' _ {} \;
      }

      format_markdown() {
        echo "🎨 Formatting Markdown files..."
        prettier --write "**/*.md" --ignore-path .gitignore
      }

      case "$MODE" in
        nix) format_nix ;;
        shell) format_shell ;;
        yaml) format_yaml ;;
        json) format_json ;;
        markdown) format_markdown ;;
        lint-nix) lint_nix ;;
        all)
          format_nix
          format_shell
          format_yaml
          format_json
          format_markdown
          ;;
        *)
          echo "Usage: dotfiles-format [nix|shell|yaml|json|markdown|lint-nix|all]"
          exit 1
          ;;
      esac

      echo "✅ Formatting complete!"
    '';
  };
}
