package ports

// CalculatorService defines the core business logic interface for calculator operations
type CalculatorService interface {
	Add(a, b int) int
	Multiply(a, b int) int
}