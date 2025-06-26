package ports

// TextProcessor defines the core business logic interface for text processing operations
type TextProcessor interface {
	Reverse(s string) string
	Capitalize(s string) string
}