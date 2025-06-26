package core

import (
	"fmt"
	"testing"
)

func TestProcessor_Reverse(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{
			name:  "simple word",
			input: "hello",
			want:  "olleh",
		},
		{
			name:  "empty string",
			input: "",
			want:  "",
		},
		{
			name:  "single character",
			input: "a",
			want:  "a",
		},
		{
			name:  "unicode characters",
			input: "안녕하세요",
			want:  "요세하녕안",
		},
		{
			name:  "mixed characters",
			input: "Hello 世界",
			want:  "界世 olleH",
		},
	}

	proc := NewProcessor()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := proc.Reverse(tt.input)
			if got != tt.want {
				t.Errorf("Reverse(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func TestProcessor_Capitalize(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{
			name:  "lowercase words",
			input: "hello world",
			want:  "Hello World",
		},
		{
			name:  "mixed case",
			input: "hELLo WORld",
			want:  "Hello World",
		},
		{
			name:  "empty string",
			input: "",
			want:  "",
		},
		{
			name:  "single word",
			input: "golang",
			want:  "Golang",
		},
		{
			name:  "already capitalized",
			input: "Hello World",
			want:  "Hello World",
		},
	}

	proc := NewProcessor()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := proc.Capitalize(tt.input)
			if got != tt.want {
				t.Errorf("Capitalize(%q) = %q, want %q", tt.input, got, tt.want)
			}
		})
	}
}

func BenchmarkProcessor_Reverse(b *testing.B) {
	proc := NewProcessor()
	for i := 0; i < b.N; i++ {
		proc.Reverse("hello world")
	}
}

func BenchmarkProcessor_Capitalize(b *testing.B) {
	proc := NewProcessor()
	for i := 0; i < b.N; i++ {
		proc.Capitalize("hello world")
	}
}

func ExampleProcessor_Reverse() {
	proc := NewProcessor()
	result := proc.Reverse("hello")
	fmt.Println(result)
	// Output: olleh
}

func ExampleProcessor_Capitalize() {
	proc := NewProcessor()
	result := proc.Capitalize("hello world")
	fmt.Println(result)
	// Output: Hello World
}