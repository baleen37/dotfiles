// Package internal provides architecture testing for the ssulmeta-go project.
// This package validates that the codebase follows Hexagonal Architecture principles
// and maintains proper dependency boundaries between layers.
//
// Architecture Rules Tested:
// 1. Hexagonal Architecture compliance (Core → Ports → Adapters)
// 2. Domain isolation (no cross-domain dependencies)
// 3. Shared package boundaries (pkg packages remain independent)
// 4. External dependency constraints (Core layer restrictions)
//
// Test execution: These tests run automatically with `make test` and in CI/CD pipeline.
package internal

import (
	"testing"

	"github.com/matthewmcnew/archtest"
)

// TestHexagonalArchitecture tests the core rules of hexagonal architecture
func TestHexagonalArchitecture(t *testing.T) {
	t.Run("Core should not depend on Adapters", func(t *testing.T) {
		// Test only domains that have proper hexagonal structure
		domainsWithHexStructure := []string{"channel", "text", "calculator"}

		for _, domain := range domainsWithHexStructure {
			corePkg := "ssulmeta-go/internal/" + domain + "/core"
			adaptersPkg := "ssulmeta-go/internal/" + domain + "/adapters"

			// Core packages should never import adapters packages
			archtest.Package(t, corePkg).
				ShouldNotDependOn(adaptersPkg)
		}
	})

	t.Run("Core should not depend on external HTTP libraries", func(t *testing.T) {
		// Core packages should not depend on HTTP clients or servers
		domainsWithCore := []string{"channel", "text", "calculator"}

		for _, domain := range domainsWithCore {
			corePkg := "ssulmeta-go/internal/" + domain + "/core"

			archtest.Package(t, corePkg).
				ShouldNotDependOn("net/http")
		}
	})

	t.Run("Ports should not depend on Adapters", func(t *testing.T) {
		// Ports define interfaces and should not depend on implementations
		domainsWithPorts := []string{"channel", "text", "calculator"}

		for _, domain := range domainsWithPorts {
			portsPkg := "ssulmeta-go/internal/" + domain + "/ports"
			adaptersPkg := "ssulmeta-go/internal/" + domain + "/adapters"

			archtest.Package(t, portsPkg).
				ShouldNotDependOn(adaptersPkg)
		}
	})

	t.Run("Story package should not depend on Channel", func(t *testing.T) {
		// Test specific cross-domain dependencies that should not exist
		archtest.Package(t, "ssulmeta-go/internal/story").
			ShouldNotDependOn("ssulmeta-go/internal/channel")
	})

	t.Run("Channel should not depend on Story", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/internal/channel").
			ShouldNotDependOn("ssulmeta-go/internal/story")
	})

	t.Run("Adapters should not depend on other adapters", func(t *testing.T) {
		// Adapters within the same domain should not depend on each other
		domains := []string{"channel", "text", "calculator"}

		for _, domain := range domains {
			adaptersPkg := "ssulmeta-go/internal/" + domain + "/adapters"

			// Check that adapters don't depend on other domain's adapters
			for _, otherDomain := range domains {
				if domain != otherDomain {
					otherAdaptersPkg := "ssulmeta-go/internal/" + otherDomain + "/adapters"
					archtest.Package(t, adaptersPkg).
						ShouldNotDependOn(otherAdaptersPkg)
				}
			}
		}
	})
}

// TestSharedPackages tests shared package dependencies
func TestSharedPackages(t *testing.T) {
	t.Run("pkg/models should not depend on internal packages", func(t *testing.T) {
		// Shared model package should not depend on domain-specific code
		archtest.Package(t, "ssulmeta-go/pkg/models").
			ShouldNotDependOn("ssulmeta-go/internal/story")
		archtest.Package(t, "ssulmeta-go/pkg/models").
			ShouldNotDependOn("ssulmeta-go/internal/channel")
		archtest.Package(t, "ssulmeta-go/pkg/models").
			ShouldNotDependOn("ssulmeta-go/internal/text")
	})

	t.Run("pkg/logger should not depend on internal packages", func(t *testing.T) {
		// Logger should not depend on domain-specific code
		archtest.Package(t, "ssulmeta-go/pkg/logger").
			ShouldNotDependOn("ssulmeta-go/internal/story")
		archtest.Package(t, "ssulmeta-go/pkg/logger").
			ShouldNotDependOn("ssulmeta-go/internal/channel")
		archtest.Package(t, "ssulmeta-go/pkg/logger").
			ShouldNotDependOn("ssulmeta-go/internal/text")
	})

	t.Run("Avoid circular dependencies in cmd packages", func(t *testing.T) {
		// Command packages should not depend on each other
		archtest.Package(t, "ssulmeta-go/cmd/api").
			ShouldNotDependOn("ssulmeta-go/cmd/cli")

		archtest.Package(t, "ssulmeta-go/cmd/cli").
			ShouldNotDependOn("ssulmeta-go/cmd/api")
	})
}

// Future Architecture Rules (for next iterations):
//
// 1. Business Logic Purity Rules:
//    - Core packages should not import context package (except for interfaces)
//    - Core packages should not import time package (use injection instead)
//    - Core packages should not import fmt package for error formatting
//
// 2. External Service Boundaries:
//    - Only adapters should import external HTTP clients
//    - Only adapters should import database drivers
//    - Only adapters should import third-party APIs (OpenAI, etc)
//
// 3. Configuration Rules:
//    - Core packages should not import config package
//    - Configuration should only flow through constructor injection
//
// 4. Logging Rules:
//    - Core packages should use structured logging interfaces only
//    - Direct logger imports should be limited to adapters
//
// 5. Testing Rules:
//    - Test files should follow the same dependency rules
//    - Mock implementations should not depend on real implementations
//
// Example implementations for future use:
//
// func TestBusinessLogicPurity(t *testing.T) {
//     archtest.Package(t, "ssulmeta-go/internal/*/core").
//         ShouldNotDependOn("context")  // Use interfaces for context
//
//     archtest.Package(t, "ssulmeta-go/internal/*/core").
//         ShouldNotDependOn("net/http") // HTTP should be in adapters only
// }
//
// func TestExternalServiceBoundaries(t *testing.T) {
//     archtest.Package(t, "ssulmeta-go/internal/*/core").
//         ShouldNotDependOn("github.com/redis/go-redis")
//
//     archtest.Package(t, "ssulmeta-go/internal/*/core").
//         ShouldNotDependOn("database/sql")
// }
