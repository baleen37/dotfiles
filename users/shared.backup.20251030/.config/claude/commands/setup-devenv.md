---
name: setup-devenv
description: "Instant nix develop + direnv setup for any project"
---

Automatically detect your project type and set up a perfect Nix development environment with direnv. Zero configuration needed.

**Just run this command and your dev environment is ready!**

## What I'll Do

1. **Detect your project** - Node.js, Python, Rust, Go, etc.
2. **Generate flake.nix** - With all the tools you need
3. **Create .envrc** - For automatic environment activation
4. **Run direnv allow** - Everything ready instantly
5. **Add .gitignore entries** - Keep your repo clean

## Supported Projects

Automatically detects and configures:

- **Node.js**: package.json → nodejs, npm, yarn, pnpm
- **Python**: requirements.txt, pyproject.toml → python, pip, virtualenv
- **Rust**: Cargo.toml → rust, cargo, clippy, rustfmt
- **Go**: go.mod → go, gopls, golangci-lint
- **TypeScript**: tsconfig.json → typescript, node, deno
- **Ruby**: Gemfile → ruby, bundler, rake
- **Java**: pom.xml, gradle → jdk, maven, gradle
- **PHP**: composer.json → php, composer

## Generated Setup

### flake.nix

Complete development shell with:

- Language runtime and package managers
- Development tools and linters
- Build dependencies
- Project-specific environment variables

### .envrc

High-performance direnv config with:

- nix-direnv for instant loading
- Automatic flake watching
- Environment caching
- Custom project variables

## No Configuration Needed

Just run `/setup-devenv` and I'll:

1. Detect what kind of project you have
2. Create the perfect Nix environment
3. Set everything up automatically
4. You're ready to code!

The environment activates automatically when you enter the directory.

Ready to set up your development environment?
