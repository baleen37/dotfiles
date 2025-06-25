package utils

import (
	"fmt"
	"testing"
)

func TestAdd(t *testing.T) {
	tests := []struct {
		name     string
		a, b     int
		expected int
	}{
		{"positive numbers", 2, 3, 5},
		{"negative numbers", -2, -3, -5},
		{"mixed numbers", -2, 3, 1},
		{"zero values", 0, 0, 0},
		{"zero and positive", 0, 5, 5},
		{"large numbers", 1000, 2000, 3000},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := Add(tt.a, tt.b)
			if result != tt.expected {
				t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, result, tt.expected)
			}
		})
	}
}

func TestMultiply(t *testing.T) {
	tests := []struct {
		name     string
		a, b     int
		expected int
	}{
		{"positive numbers", 3, 4, 12},
		{"negative numbers", -3, -4, 12},
		{"mixed numbers", -3, 4, -12},
		{"zero multiplication", 5, 0, 0},
		{"one multiplication", 7, 1, 7},
		{"large numbers", 100, 200, 20000},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := Multiply(tt.a, tt.b)
			if result != tt.expected {
				t.Errorf("Multiply(%d, %d) = %d, want %d", tt.a, tt.b, result, tt.expected)
			}
		})
	}
}

func TestReverseString(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{"simple string", "hello", "olleh"},
		{"single character", "a", "a"},
		{"empty string", "", ""},
		{"palindrome", "racecar", "racecar"},
		{"with spaces", "hello world", "dlrow olleh"},
		{"unicode characters", "안녕", "녕안"},
		{"numbers", "12345", "54321"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ReverseString(tt.input)
			if result != tt.expected {
				t.Errorf("ReverseString(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestCapitalizeWords(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{"simple words", "hello world", "Hello World"},
		{"all caps", "HELLO WORLD", "Hello World"},
		{"mixed case", "hELLo WoRLd", "Hello World"},
		{"single word", "hello", "Hello"},
		{"empty string", "", ""},
		{"with punctuation", "hello, world!", "Hello, World!"},
		{"with numbers", "hello 123 world", "Hello 123 World"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := CapitalizeWords(tt.input)
			if result != tt.expected {
				t.Errorf("CapitalizeWords(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestIsEven(t *testing.T) {
	tests := []struct {
		name     string
		input    int
		expected bool
	}{
		{"even positive", 4, true},
		{"odd positive", 5, false},
		{"even negative", -4, true},
		{"odd negative", -5, false},
		{"zero", 0, true},
		{"large even", 1000, true},
		{"large odd", 1001, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := IsEven(tt.input)
			if result != tt.expected {
				t.Errorf("IsEven(%d) = %v, want %v", tt.input, result, tt.expected)
			}
		})
	}
}

func TestMax(t *testing.T) {
	tests := []struct {
		name     string
		a, b     int
		expected int
	}{
		{"a greater", 5, 3, 5},
		{"b greater", 3, 5, 5},
		{"equal", 5, 5, 5},
		{"negative numbers", -3, -5, -3},
		{"mixed", -3, 5, 5},
		{"zero", 0, -1, 0},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := Max(tt.a, tt.b)
			if result != tt.expected {
				t.Errorf("Max(%d, %d) = %d, want %d", tt.a, tt.b, result, tt.expected)
			}
		})
	}
}

// Benchmark tests for performance measurement
func BenchmarkAdd(b *testing.B) {
	for i := 0; i < b.N; i++ {
		Add(1000, 2000)
	}
}

func BenchmarkMultiply(b *testing.B) {
	for i := 0; i < b.N; i++ {
		Multiply(123, 456)
	}
}

func BenchmarkReverseString(b *testing.B) {
	testString := "The quick brown fox jumps over the lazy dog"
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ReverseString(testString)
	}
}

func BenchmarkReverseStringLong(b *testing.B) {
	// Generate a longer string for more intensive benchmarking
	longString := ""
	for i := 0; i < 1000; i++ {
		longString += "The quick brown fox jumps over the lazy dog. "
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ReverseString(longString)
	}
}

func BenchmarkCapitalizeWords(b *testing.B) {
	testString := "the quick brown fox jumps over the lazy dog and runs through the forest"
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		CapitalizeWords(testString)
	}
}

func BenchmarkIsEven(b *testing.B) {
	for i := 0; i < b.N; i++ {
		IsEven(12345)
	}
}

func BenchmarkMax(b *testing.B) {
	for i := 0; i < b.N; i++ {
		Max(1000, 2000)
	}
}

// Example tests for documentation
func ExampleAdd() {
	result := Add(5, 3)
	fmt.Println(result)
	// Output: 8
}

func ExampleAdd_negative() {
	result := Add(-5, 3)
	fmt.Println(result)
	// Output: -2
}

func ExampleMultiply() {
	result := Multiply(6, 7)
	fmt.Println(result)
	// Output: 42
}

func ExampleReverseString() {
	result := ReverseString("hello")
	fmt.Println(result)
	// Output: olleh
}

func ExampleReverseString_empty() {
	result := ReverseString("")
	fmt.Println(result)
	// Output: 
}

func ExampleCapitalizeWords() {
	result := CapitalizeWords("hello world")
	fmt.Println(result)
	// Output: Hello World
}

func ExampleIsEven() {
	fmt.Println(IsEven(4))
	fmt.Println(IsEven(5))
	// Output:
	// true
	// false
}

func ExampleMax() {
	result := Max(10, 20)
	fmt.Println(result)
	// Output: 20
}