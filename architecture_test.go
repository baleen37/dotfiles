package main

import (
	"testing"

	"github.com/matthewmcnew/archtest"
)

func TestHexagonalArchitectureDependencies(t *testing.T) {
	t.Log("Testing Hexagonal Architecture dependency rules...")

	// Core packages should not depend on adapters (using pattern matching)
	t.Run("core packages should not depend on adapters", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/internal/.../core").
			ShouldNotDependOn("ssulmeta-go/internal/.../adapters")
	})

	// Core packages should not depend on external HTTP frameworks
	t.Run("core packages should not depend on HTTP frameworks", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/internal/.../core").
			ShouldNotDependOn("github.com/gin-gonic/gin")
	})

	// Ports should not depend on adapters
	t.Run("ports should not depend on adapters", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/internal/.../ports").
			ShouldNotDependOn("ssulmeta-go/internal/.../adapters")
	})

	// Models package should not depend on any internal packages
	t.Run("models should not depend on internal packages", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/pkg/models").
			ShouldNotDependOn("ssulmeta-go/internal/...")
	})

	// Config package should not depend on business domains
	t.Run("config should not depend on business domains", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/internal/config").
			ShouldNotDependOn("ssulmeta-go/internal/story",
				"ssulmeta-go/internal/channel",
				"ssulmeta-go/internal/image",
				"ssulmeta-go/internal/tts",
				"ssulmeta-go/internal/video",
				"ssulmeta-go/internal/youtube")
	})

	// Story package should not depend on other domain interfaces
	t.Run("story package should not cross-depend on other domains", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/internal/story").
			ShouldNotDependOn("ssulmeta-go/internal/channel/...",
				"ssulmeta-go/internal/text/...")
	})

	// Database package should not depend on business logic
	t.Run("database package should not depend on business domains", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/internal/db").
			ShouldNotDependOn("ssulmeta-go/internal/story",
				"ssulmeta-go/internal/channel/...",
				"ssulmeta-go/internal/image",
				"ssulmeta-go/internal/tts",
				"ssulmeta-go/internal/video",
				"ssulmeta-go/internal/youtube")
	})
}

func TestLayerIsolation(t *testing.T) {
	t.Log("Testing layer isolation rules...")

	// Core layers should not cross-depend on other domains
	t.Run("core layers should be domain-isolated", func(t *testing.T) {
		// All core packages should not depend on other domains
		archtest.Package(t, "ssulmeta-go/internal/.../core").
			ShouldNotDependOn("ssulmeta-go/internal/story",
				"ssulmeta-go/internal/channel",
				"ssulmeta-go/internal/text",
				"ssulmeta-go/internal/calculator",
				"ssulmeta-go/internal/health",
				"ssulmeta-go/internal/image",
				"ssulmeta-go/internal/tts",
				"ssulmeta-go/internal/video",
				"ssulmeta-go/internal/youtube")
	})
}

func TestExternalDependencyRules(t *testing.T) {
	t.Log("Testing external dependency rules...")

	// Core and ports should not handle external integrations
	t.Run("only adapters should handle Redis", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/internal/.../core").
			ShouldNotDependOn("github.com/redis/go-redis/v9")

		archtest.Package(t, "ssulmeta-go/internal/.../ports").
			ShouldNotDependOn("github.com/redis/go-redis/v9")
	})

	// Only adapters should handle OpenAI API
	t.Run("only adapters should handle OpenAI", func(t *testing.T) {
		archtest.Package(t, "ssulmeta-go/internal/.../core").
			ShouldNotDependOn("github.com/sashabaranov/go-openai")

		archtest.Package(t, "ssulmeta-go/internal/.../ports").
			ShouldNotDependOn("github.com/sashabaranov/go-openai")

		// Note: story package currently uses OpenAI directly, which might need refactoring
		t.Log("Info: Current story package uses OpenAI directly - consider moving to adapter pattern")
	})
}
