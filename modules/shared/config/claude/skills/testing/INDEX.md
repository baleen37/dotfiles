# Testing Skills

Skills for writing reliable, maintainable tests.

## Available Skills

- skills/testing/test-driven-development - Red-green-refactor cycle: write failing test first, minimal code to pass, refactor. Mandatory for all features and bugfixes. Use when writing any production code, when you wrote code before tests, when tempted to test after.

- skills/testing/condition-based-waiting - Replace arbitrary timeouts with condition polling for reliable async tests. Use when tests are flaky, timing-dependent, or use setTimeout/sleep.

- skills/testing/testing-anti-patterns - Never test mock behavior, never add test-only methods to production classes, understand dependencies before mocking. Use when writing tests, adding mocks, fixing failing tests. When tempted to assert on mock elements or add cleanup methods to production code.
