# Python Project Setup Template

## Directory Structure

```text
src/
  ├── domain/          # Business logic (no external dependencies)
  ├── application/     # Use cases
  ├── infrastructure/  # External services, databases
  ├── interfaces/      # Controllers, CLI, API
  └── shared/          # Common utilities
tests/
  ├── unit/
  ├── integration/
  ├── e2e/
  └── architecture/    # Architecture validation tests
config/
scripts/
docs/
```

## Dependencies

**`pyproject.toml`:**

```toml
[project]
name = "your-project"
version = "0.1.0"
requires-python = ">=3.11"

[project.optional-dependencies]
dev = [
    "pytest>=7.4.0",
    "pytest-cov>=4.1.0",
    "pytest-asyncio>=0.21.0",
    "ruff>=0.1.0",
    "mypy>=1.7.0",
    "pre-commit>=3.5.0",
]

[tool.ruff]
line-length = 100
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "C4", "SIM"]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_configs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = "--cov=src --cov-report=term-missing --cov-fail-under=80"
```

## Pre-commit Setup

**Install:**

```bash
pip install pre-commit
pre-commit install
```

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

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]

  - repo: local
    hooks:
      - id: architecture-tests
        name: Architecture Validation
        entry: pytest tests/architecture -v
        language: system
        pass_filenames: false

      - id: unit-tests
        name: Unit Tests
        entry: pytest tests/unit --no-cov
        language: system
        pass_filenames: false
```

## Architecture Validation Tests

**`tests/architecture/test_dependency_rules.py`:**

```python
import ast
from pathlib import Path
import pytest

def get_imports(file_path: Path) -> list[str]:
    """Extract all import statements."""
    with open(file_path) as f:
        tree = ast.parse(f.read())

    imports = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            imports.extend(alias.name for alias in node.names)
        elif isinstance(node, ast.ImportFrom):
            if node.module:
                imports.append(node.module)
    return imports


class TestDependencyRules:
    def test_domain_cannot_import_infrastructure(self):
        """Domain layer must not depend on infrastructure."""
        domain_dir = Path("src/domain")

        for py_file in domain_dir.rglob("*.py"):
            imports = get_imports(py_file)

            for imp in imports:
                assert not imp.startswith("src.infrastructure"), \
                    f"{py_file} imports infrastructure: {imp}"
                assert not imp.startswith("src.interfaces"), \
                    f"{py_file} imports interfaces: {imp}"

    def test_domain_cannot_import_frameworks(self):
        """Domain layer must not depend on frameworks."""
        domain_dir = Path("src/domain")
        forbidden = ["flask", "fastapi", "django", "sqlalchemy", "requests"]

        for py_file in domain_dir.rglob("*.py"):
            imports = get_imports(py_file)

            for imp in imports:
                for forbidden_lib in forbidden:
                    assert not imp.startswith(forbidden_lib), \
                        f"{py_file} imports forbidden framework: {imp}"

    def test_application_cannot_import_infrastructure(self):
        """Application layer should not depend on infrastructure."""
        app_dir = Path("src/application")

        for py_file in app_dir.rglob("*.py"):
            imports = get_imports(py_file)

            for imp in imports:
                assert not imp.startswith("src.infrastructure"), \
                    f"{py_file} imports infrastructure: {imp}"

    def test_each_layer_has_init(self):
        """Each layer must have __init__.py."""
        layers = ["domain", "application", "infrastructure", "interfaces"]

        for layer in layers:
            init_file = Path(f"src/{layer}/__init__.py")
            assert init_file.exists(), f"{layer} missing __init__.py"


class TestNamingConventions:
    def test_entity_files_in_domain(self):
        """Entity files should be in domain/entities/."""
        entity_dir = Path("src/domain/entities")
        if entity_dir.exists():
            for py_file in entity_dir.glob("*.py"):
                if py_file.name == "__init__.py":
                    continue
                assert py_file.stem.islower(), \
                    f"Entity {py_file.name} should use snake_case"

    def test_use_case_files_naming(self):
        """Use case files should follow naming convention."""
        use_case_dir = Path("src/application/use_cases")
        if use_case_dir.exists():
            for py_file in use_case_dir.glob("*.py"):
                if py_file.name == "__init__.py":
                    continue
                assert "_use_case" in py_file.stem or "_usecase" in py_file.stem, \
                    f"Use case {py_file.name} should contain 'use_case'"
```

## Test Configuration

**`pytest.ini`:**

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    --strict-markers
    --cov=src
    --cov-report=term-missing
    --cov-report=html
    --cov-fail-under=80
    -v
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
        python-version: ["3.11", "3.12"]

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          pip install -e ".[dev]"

      - name: Lint with ruff
        run: ruff check src tests

      - name: Type check with mypy
        run: mypy src

      - name: Architecture tests
        run: pytest tests/architecture -v

      - name: Unit tests
        run: pytest tests/unit --cov

      - name: Integration tests
        run: pytest tests/integration

      - name: Upload coverage
        if: matrix.python-version == '3.12'
        uses: codecov/codecov-action@v4
```

## Makefile

```makefile
.PHONY: install test lint format clean

install:
	pip install -e ".[dev]"
	pre-commit install

lint:
	ruff check src tests
	mypy src

format:
	ruff format src tests

test:
	pytest --cov

test-arch:
	pytest tests/architecture -v

test-unit:
	pytest tests/unit

test-integration:
	pytest tests/integration

clean:
	rm -rf .pytest_cache .coverage htmlcov __pycache__
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type d -name "__pycache__" -exec rm -rf {} +
```
