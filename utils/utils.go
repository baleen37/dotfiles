package utils

import "strings"

// Add returns the sum of two integers
func Add(a, b int) int {
	return a + b
}

// Multiply returns the product of two integers
func Multiply(a, b int) int {
	return a * b
}

// ReverseString returns the reversed version of the input string
func ReverseString(s string) string {
	runes := []rune(s)
	for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}
	return string(runes)
}

// CapitalizeWords capitalizes the first letter of each word
func CapitalizeWords(s string) string {
	return strings.Title(strings.ToLower(s))
}

// IsEven checks if a number is even
func IsEven(n int) bool {
	return n%2 == 0
}

// Max returns the maximum of two integers
func Max(a, b int) int {
	if a > b {
		return a
	}
	return b
}