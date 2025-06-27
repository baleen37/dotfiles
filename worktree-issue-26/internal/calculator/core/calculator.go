package core

// Calculator implements the calculator business logic
type Calculator struct{}

// NewCalculator creates a new Calculator instance
func NewCalculator() *Calculator {
	return &Calculator{}
}

// Add returns the sum of two integers
func (c *Calculator) Add(a, b int) int {
	return a + b
}

// Multiply returns the product of two integers
func (c *Calculator) Multiply(a, b int) int {
	return a * b
}
