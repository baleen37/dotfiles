# Go Project Setup Template

## Directory Structure

```text
cmd/                      # Main applications
  └── server/
      └── main.go
internal/                 # Private application code
  ├── domain/            # Business logic
  ├── usecase/           # Application use cases
  ├── repository/        # Data access interfaces
  ├── handler/           # HTTP handlers
  └── infrastructure/    # External services
pkg/                     # Public libraries
api/                     # API definitions (OpenAPI, protobuf)
test/
  ├── unit/
  ├── integration/
  ├── e2e/
  └── architecture/      # Architecture validation tests
scripts/
docs/
```

## Project Setup

**`go.mod`:**

```go
module github.com/yourorg/yourproject

go 1.21

require (
    github.com/stretchr/testify v1.8.4
)
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
      - id: gofmt
        name: gofmt
        entry: gofmt -w -s
        language: system
        types: [go]

      - id: goimports
        name: goimports
        entry: goimports -w
        language: system
        types: [go]

      - id: golangci-lint
        name: golangci-lint
        entry: golangci-lint run --fix
        language: system
        types: [go]
        pass_filenames: false

      - id: go-vet
        name: go vet
        entry: go vet ./...
        language: system
        types: [go]
        pass_filenames: false

      - id: go-test-arch
        name: Architecture Tests
        entry: go test ./test/architecture/...
        language: system
        pass_filenames: false

      - id: go-test-unit
        name: Unit Tests
        entry: go test ./test/unit/... -short
        language: system
        pass_filenames: false
```

**Install:**

```bash
brew install pre-commit golangci-lint  # macOS
# or
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
pre-commit install
```

## Architecture Validation Tests

**`test/architecture/dependency_test.go`:**

```go
package architecture_test

import (
    "go/parser"
    "go/token"
    "os"
    "path/filepath"
    "strings"
    "testing"
)

func TestDomainLayerDependencies(t *testing.T) {
    domainDir := "internal/domain"
    forbiddenImports := []string{
        "internal/infrastructure",
        "internal/handler",
        "internal/repository",  // Domain should only have interfaces, not implementations
    }

    err := filepath.Walk(domainDir, func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }

        if !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
            return nil
        }

        fset := token.NewFileSet()
        node, err := parser.ParseFile(fset, path, nil, parser.ImportsOnly)
        if err != nil {
            return err
        }

        for _, imp := range node.Imports {
            importPath := strings.Trim(imp.Path.Value, `"`)

            for _, forbidden := range forbiddenImports {
                if strings.Contains(importPath, forbidden) {
                    t.Errorf("File %s imports forbidden package %s", path, importPath)
                }
            }

            // Domain should not import external frameworks
            if strings.Contains(importPath, "gin-gonic") ||
                strings.Contains(importPath, "echo") ||
                strings.Contains(importPath, "gorm") {
                t.Errorf("Domain layer %s imports external framework %s", path, importPath)
            }
        }

        return nil
    })

    if err != nil {
        t.Fatalf("Failed to walk domain directory: %v", err)
    }
}

func TestUsecaseLayerDependencies(t *testing.T) {
    usecaseDir := "internal/usecase"
    forbiddenImports := []string{
        "internal/handler",
        "internal/infrastructure", // Should depend on interfaces, not implementations
    }

    err := filepath.Walk(usecaseDir, func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }

        if !strings.HasSuffix(path, ".go") || strings.HasSuffix(path, "_test.go") {
            return nil
        }

        fset := token.NewFileSet()
        node, err := parser.ParseFile(fset, path, nil, parser.ImportsOnly)
        if err != nil {
            return err
        }

        for _, imp := range node.Imports {
            importPath := strings.Trim(imp.Path.Value, `"`)

            for _, forbidden := range forbiddenImports {
                if strings.Contains(importPath, forbidden) {
                    t.Errorf("File %s imports forbidden package %s", path, importPath)
                }
            }
        }

        return nil
    })

    if err != nil {
        t.Fatalf("Failed to walk usecase directory: %v", err)
    }
}

func TestNamingConventions(t *testing.T) {
    tests := []struct {
        dir      string
        suffix   string
        message  string
    }{
        {"internal/domain", "_entity.go", "entity files"},
        {"internal/usecase", "_usecase.go", "usecase files"},
        {"internal/repository", "_repository.go", "repository files"},
    }

    for _, tt := range tests {
        t.Run(tt.message, func(t *testing.T) {
            if _, err := os.Stat(tt.dir); os.IsNotExist(err) {
                t.Skipf("Directory %s does not exist", tt.dir)
            }

            err := filepath.Walk(tt.dir, func(path string, info os.FileInfo, err error) error {
                if err != nil {
                    return err
                }

                if !strings.HasSuffix(path, ".go") ||
                    strings.HasSuffix(path, "_test.go") ||
                    strings.HasSuffix(path, "doc.go") {
                    return nil
                }

                if !strings.HasSuffix(path, tt.suffix) {
                    t.Errorf("File %s should have suffix %s", path, tt.suffix)
                }

                return nil
            })

            if err != nil {
                t.Fatalf("Failed to walk directory: %v", err)
            }
        })
    }
}
```

## golangci-lint Configuration

**`.golangci.yml`:**

```yaml
linters:
  enable:
    - gofmt
    - goimports
    - govet
    - errcheck
    - staticcheck
    - unused
    - gosimple
    - ineffassign
    - typecheck
    - revive

linters-settings:
  revive:
    rules:
      - name: exported
        severity: warning
      - name: package-comments
        severity: warning

issues:
  exclude-use-default: false
  max-issues-per-linter: 0
  max-same-issues: 0
```

## CI Configuration

**`.github/workflows/ci.yml`:**

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        go-version: ['1.21', '1.22']

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: ${{ matrix.go-version }}
          cache: true

      - name: Install dependencies
        run: go mod download

      - name: Run gofmt
        run: test -z $(gofmt -l .)

      - name: Run go vet
        run: go vet ./...

      - name: Run golangci-lint
        uses: golangci/golangci-lint-action@v3
        with:
          version: latest

      - name: Architecture tests
        run: go test -v ./test/architecture/...

      - name: Unit tests
        run: go test -v -race -coverprofile=coverage.out ./test/unit/...

      - name: Integration tests
        run: go test -v ./test/integration/...

      - name: Upload coverage
        if: matrix.go-version == '1.22'
        uses: codecov/codecov-action@v4

      - name: Build
        run: go build -v ./cmd/...
```

## Makefile

```makefile
.PHONY: install test lint fmt clean build

install:
	go mod download
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

fmt:
	gofmt -w -s .
	goimports -w .

lint:
	golangci-lint run
	go vet ./...

test:
	go test -v -race -coverprofile=coverage.out ./...

test-arch:
	go test -v ./test/architecture/...

test-unit:
	go test -v -race ./test/unit/...

test-integration:
	go test -v ./test/integration/...

coverage:
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

build:
	go build -v -o bin/ ./cmd/...

clean:
	rm -rf bin/ coverage.out
	go clean -testcache
```
