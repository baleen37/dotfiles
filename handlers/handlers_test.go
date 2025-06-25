package handlers

import (
	"fmt"
	"net/http"
	"strings"
	"testing"
)

func TestHelloHandler(t *testing.T) {
	expected := "Hello, World!"
	result := HelloHandler()
	if result != expected {
		t.Errorf("HelloHandler() = %q, want %q", result, expected)
	}
}

func TestAddHandler(t *testing.T) {
	tests := []struct {
		name        string
		aStr        string
		bStr        string
		expectedMsg string
		expectError bool
	}{
		{"valid positive numbers", "5", "3", "Result: 8", false},
		{"valid negative numbers", "-5", "-3", "Result: -8", false},
		{"valid mixed numbers", "-5", "3", "Result: -2", false},
		{"valid zero", "0", "0", "Result: 0", false},
		{"large numbers", "1000", "2000", "Result: 3000", false},
		{"invalid a parameter", "abc", "5", "", true},
		{"invalid b parameter", "5", "xyz", "", true},
		{"both invalid", "abc", "xyz", "", true},
		{"empty a parameter", "", "5", "", true},
		{"empty b parameter", "5", "", "", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := AddHandler(tt.aStr, tt.bStr)
			
			if tt.expectError {
				if err == nil {
					t.Errorf("AddHandler(%q, %q) expected error, got nil", tt.aStr, tt.bStr)
				}
			} else {
				if err != nil {
					t.Errorf("AddHandler(%q, %q) unexpected error: %v", tt.aStr, tt.bStr, err)
				}
				if result != tt.expectedMsg {
					t.Errorf("AddHandler(%q, %q) = %q, want %q", tt.aStr, tt.bStr, result, tt.expectedMsg)
				}
			}
		})
	}
}

func TestReverseHandler(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{"simple string", "hello", "olleh"},
		{"empty string", "", "No text provided"},
		{"single character", "a", "a"},
		{"palindrome", "racecar", "racecar"},
		{"with spaces", "hello world", "dlrow olleh"},
		{"unicode", "안녕", "녕안"},
		{"numbers", "12345", "54321"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ReverseHandler(tt.input)
			if result != tt.expected {
				t.Errorf("ReverseHandler(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}

func TestHealthCheckHandler(t *testing.T) {
	status, message := HealthCheckHandler()
	
	expectedStatus := http.StatusOK
	expectedMessage := "Service is healthy"
	
	if status != expectedStatus {
		t.Errorf("HealthCheckHandler() status = %d, want %d", status, expectedStatus)
	}
	
	if message != expectedMessage {
		t.Errorf("HealthCheckHandler() message = %q, want %q", message, expectedMessage)
	}
}

func TestAddHandlerErrorMessages(t *testing.T) {
	// Test specific error message formats
	_, err := AddHandler("invalid", "5")
	if err == nil {
		t.Error("Expected error for invalid first parameter")
	}
	if !strings.Contains(err.Error(), "invalid parameter a") {
		t.Errorf("Error message should contain 'invalid parameter a', got: %v", err)
	}
	
	_, err = AddHandler("5", "invalid")
	if err == nil {
		t.Error("Expected error for invalid second parameter")
	}
	if !strings.Contains(err.Error(), "invalid parameter b") {
		t.Errorf("Error message should contain 'invalid parameter b', got: %v", err)
	}
}

// Benchmark tests for performance measurement
func BenchmarkHelloHandler(b *testing.B) {
	for i := 0; i < b.N; i++ {
		HelloHandler()
	}
}

func BenchmarkAddHandler(b *testing.B) {
	for i := 0; i < b.N; i++ {
		AddHandler("1000", "2000")
	}
}

func BenchmarkAddHandlerError(b *testing.B) {
	for i := 0; i < b.N; i++ {
		AddHandler("invalid", "2000")
	}
}

func BenchmarkReverseHandler(b *testing.B) {
	testString := "The quick brown fox jumps over the lazy dog"
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ReverseHandler(testString)
	}
}

func BenchmarkReverseHandlerEmpty(b *testing.B) {
	for i := 0; i < b.N; i++ {
		ReverseHandler("")
	}
}

func BenchmarkHealthCheckHandler(b *testing.B) {
	for i := 0; i < b.N; i++ {
		HealthCheckHandler()
	}
}

// Example tests for documentation
func ExampleHelloHandler() {
	result := HelloHandler()
	fmt.Println(result)
	// Output: Hello, World!
}

func ExampleAddHandler() {
	result, err := AddHandler("10", "20")
	if err != nil {
		fmt.Printf("Error: %v", err)
		return
	}
	fmt.Println(result)
	// Output: Result: 30
}

func ExampleAddHandler_error() {
	_, err := AddHandler("invalid", "20")
	if err != nil {
		fmt.Println("Error occurred")
	}
	// Output: Error occurred
}

func ExampleReverseHandler() {
	result := ReverseHandler("hello")
	fmt.Println(result)
	// Output: olleh
}

func ExampleReverseHandler_empty() {
	result := ReverseHandler("")
	fmt.Println(result)
	// Output: No text provided
}

func ExampleHealthCheckHandler() {
	status, message := HealthCheckHandler()
	fmt.Printf("Status: %d, Message: %s", status, message)
	// Output: Status: 200, Message: Service is healthy
}