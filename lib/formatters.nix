{ pkgs, lib }:

{
  formatter = pkgs.writeShellApplication {
    name = "dotfiles-format";
    runtimeInputs = with pkgs; [
      nixfmt-rfc-style
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
        echo "🎨 Formatting Nix files..."
        find . -name "*.nix" -not -path "*/.*" -not -path "*/result/*" -exec nixfmt {} +
      }

      format_shell() {
        echo "🎨 Formatting shell scripts..."
        find . -name "*.sh" -not -path "*/.*" -exec shfmt -w {} +
      }

      format_yaml() {
        echo "🎨 Formatting YAML files..."
        find . \( -name "*.yaml" -o -name "*.yml" \) -not -path "*/.*" -exec yamlfmt -w {} +
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
        all)
          format_nix
          format_shell
          format_yaml
          format_json
          format_markdown
          ;;
        *)
          echo "Usage: dotfiles-format [nix|shell|yaml|json|markdown|all]"
          exit 1
          ;;
      esac

      echo "✅ Formatting complete!"
    '';
  };
}
