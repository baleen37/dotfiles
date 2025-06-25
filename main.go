package main

import (
	"fmt"
	"strings"
)

func main() {
	fmt.Println(GetHelloMessage())
}

// GetHelloMessage returns a greeting message
func GetHelloMessage() string {
	return "Hello, World!"
}

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
