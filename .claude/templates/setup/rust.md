# Rust Project Setup Template

## Directory Structure

```text
src/
  ├── domain/          # Business logic (no external dependencies)
  ├── application/     # Use cases
  ├── infrastructure/  # External services, databases
  ├── interface/       # API, CLI adapters
  ├── lib.rs          # Library root
  └── main.rs         # Binary entry point
tests/
  ├── unit/
  ├── integration/
  ├── e2e/
  └── architecture/    # Architecture validation tests
benches/             # Benchmarks
examples/
docs/
```

## Project Setup

**`Cargo.toml`:**

```toml
[package]
name = "your-project"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"

[dependencies]
# Add runtime dependencies here

[dev-dependencies]
# Test dependencies
tokio = { version = "1", features = ["test-util"] }

[lints.rust]
unsafe_code = "forbid"

[lints.clippy]
enum_glob_use = "deny"
unwrap_used = "deny"
```

## Pre-commit Setup

**`.pre-commit-config.yaml`:**

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files

  - repo: local
    hooks:
      - id: cargo-fmt
        name: cargo fmt
        entry: cargo fmt
        language: system
        types: [rust]
        pass_filenames: false

      - id: cargo-clippy
        name: cargo clippy
        entry: cargo clippy -- -D warnings
        language: system
        types: [rust]
        pass_filenames: false

      - id: cargo-test-arch
        name: Architecture Tests
        entry: cargo test --test architecture
        language: system
        pass_filenames: false

      - id: cargo-test-unit
        name: Unit Tests
        entry: cargo test --lib
        language: system
        pass_filenames: false
```

**Install:**

```bash
pip install pre-commit
pre-commit install
```

## Architecture Validation Tests

**`tests/architecture.rs`:**

```rust
//! Architecture rule validation tests

use std::fs;
use std::path::Path;

#[test]
fn test_domain_has_no_external_dependencies() {
    let domain_files = find_rust_files("src/domain");

    let forbidden_crates = vec![
        "tokio",
        "actix",
        "sqlx",
        "diesel",
        "reqwest",
    ];

    for file in domain_files {
        let content = fs::read_to_string(&file)
            .unwrap_or_else(|_| panic!("Failed to read {:?}", file));

        for crate_name in &forbidden_crates {
            assert!(
                !content.contains(&format!("use {};", crate_name))
                    && !content.contains(&format!("use {}::", crate_name)),
                "Domain file {:?} should not depend on external crate {}",
                file,
                crate_name
            );
        }
    }
}

#[test]
fn test_domain_does_not_import_infrastructure() {
    let domain_files = find_rust_files("src/domain");

    for file in domain_files {
        let content = fs::read_to_string(&file)
            .unwrap_or_else(|_| panic!("Failed to read {:?}", file));

        assert!(
            !content.contains("use crate::infrastructure")
                && !content.contains("use super::infrastructure")
                && !content.contains("use crate::interface"),
            "Domain file {:?} should not import from infrastructure or interface layers",
            file
        );
    }
}

#[test]
fn test_application_does_not_import_infrastructure() {
    let app_files = find_rust_files("src/application");

    for file in app_files {
        let content = fs::read_to_string(&file)
            .unwrap_or_else(|_| panic!("Failed to read {:?}", file));

        assert!(
            !content.contains("use crate::infrastructure")
                && !content.contains("use super::infrastructure"),
            "Application file {:?} should not directly import infrastructure",
            file
        );
    }
}

#[test]
fn test_all_layers_have_mod_files() {
    let layers = vec!["domain", "application", "infrastructure", "interface"];

    for layer in layers {
        let mod_file = format!("src/{}/mod.rs", layer);
        let lib_rs = format!("src/{}.rs", layer);

        assert!(
            Path::new(&mod_file).exists() || Path::new(&lib_rs).exists(),
            "Layer {} must have mod.rs or {}.rs",
            layer,
            layer
        );
    }
}

#[test]
fn test_no_unwrap_in_production_code() {
    let src_files = find_rust_files("src");

    for file in src_files {
        let content = fs::read_to_string(&file)
            .unwrap_or_else(|_| panic!("Failed to read {:?}", file));

        // Allow unwrap in tests
        if file.to_str().unwrap().contains("test") {
            continue;
        }

        let lines: Vec<&str> = content.lines().collect();
        for (i, line) in lines.iter().enumerate() {
            if line.contains(".unwrap()") && !line.trim().starts_with("//") {
                panic!(
                    "File {:?} line {} contains .unwrap() in production code",
                    file,
                    i + 1
                );
            }
        }
    }
}

// Helper function
fn find_rust_files(dir: &str) -> Vec<std::path::PathBuf> {
    let mut rust_files = Vec::new();

    if let Ok(entries) = fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();

            if path.is_dir() {
                rust_files.extend(find_rust_files(path.to_str().unwrap()));
            } else if path.extension().and_then(|s| s.to_str()) == Some("rs") {
                rust_files.push(path);
            }
        }
    }

    rust_files
}
```

## rustfmt Configuration

**`.rustfmt.toml`:**

```toml
edition = "2021"
max_width = 100
hard_tabs = false
tab_spaces = 4
newline_style = "Unix"
use_small_heuristics = "Default"
reorder_imports = true
reorder_modules = true
remove_nested_parens = true
```

## clippy Configuration

**`.clippy.toml`:**

```toml
# Add in Cargo.toml under [lints.clippy]
# This file is for workspace-level clippy config
```

## CI Configuration

**`.github/workflows/ci.yml`:**

```yaml
name: CI

on: [push, pull_request]

env:
  CARGO_TERM_COLOR: always

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        rust: [stable, beta]

    steps:
      - uses: actions/checkout@v4

      - uses: dtolnay/rust-toolchain@master
        with:
          toolchain: ${{ matrix.rust }}
          components: rustfmt, clippy

      - uses: Swatinem/rust-cache@v2

      - name: Check formatting
        run: cargo fmt -- --check

      - name: Run clippy
        run: cargo clippy --all-targets --all-features -- -D warnings

      - name: Architecture tests
        run: cargo test --test architecture

      - name: Unit tests
        run: cargo test --lib

      - name: Integration tests
        run: cargo test --test '*'

      - name: Doc tests
        run: cargo test --doc

      - name: Build
        run: cargo build --release

      - name: Run benchmarks (no-op)
        run: cargo bench --no-run

  coverage:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable

      - name: Install tarpaulin
        run: cargo install cargo-tarpaulin

      - name: Generate coverage
        run: cargo tarpaulin --out xml

      - name: Upload coverage
        uses: codecov/codecov-action@v4
```

## Makefile

```makefile
.PHONY: test lint fmt clean build bench

fmt:
	cargo fmt

lint:
	cargo clippy --all-targets --all-features -- -D warnings

test:
	cargo test

test-arch:
	cargo test --test architecture

test-unit:
	cargo test --lib

test-integration:
	cargo test --test '*'

coverage:
	cargo tarpaulin --out html

build:
	cargo build --release

bench:
	cargo bench

clean:
	cargo clean

check:
	cargo check --all-targets --all-features
```

## Additional Tools

**Install useful cargo tools:**

```bash
# Code coverage
cargo install cargo-tarpaulin

# Security audit
cargo install cargo-audit

# Dependency tree
cargo install cargo-tree

# Unused dependencies
cargo install cargo-udeps

# Watch for changes
cargo install cargo-watch
```

**Add to CI:**

```yaml
- name: Security audit
  run: |
    cargo install cargo-audit
    cargo audit

- name: Check unused dependencies
  run: |
    cargo install cargo-udeps
    cargo udeps
```
