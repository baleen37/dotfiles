package main

import "testing"

func TestGetHelloMessage(t *testing.T) {
	expected := "Hello, World!"
	result := GetHelloMessage()
	if result != expected {
		t.Errorf("GetHelloMessage() = %q, want %q", result, expected)
	}
}

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