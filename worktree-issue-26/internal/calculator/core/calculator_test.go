package core

import (
	"fmt"
	"testing"
)

func TestCalculator_Add(t *testing.T) {
	tests := []struct {
		name string
		a    int
		b    int
		want int
	}{
		{
			name: "positive numbers",
			a:    5,
			b:    3,
			want: 8,
		},
		{
			name: "negative numbers",
			a:    -5,
			b:    -3,
			want: -8,
		},
		{
			name: "mixed numbers",
			a:    10,
			b:    -5,
			want: 5,
		},
		{
			name: "zero values",
			a:    0,
			b:    0,
			want: 0,
		},
	}

	calc := NewCalculator()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := calc.Add(tt.a, tt.b)
			if got != tt.want {
				t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
			}
		})
	}
}

func TestCalculator_Multiply(t *testing.T) {
	tests := []struct {
		name string
		a    int
		b    int
		want int
	}{
		{
			name: "positive numbers",
			a:    5,
			b:    3,
			want: 15,
		},
		{
			name: "negative numbers",
			a:    -5,
			b:    -3,
			want: 15,
		},
		{
			name: "mixed numbers",
			a:    10,
			b:    -5,
			want: -50,
		},
		{
			name: "zero values",
			a:    10,
			b:    0,
			want: 0,
		},
	}

	calc := NewCalculator()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := calc.Multiply(tt.a, tt.b)
			if got != tt.want {
				t.Errorf("Multiply(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
			}
		})
	}
}

func BenchmarkCalculator_Add(b *testing.B) {
	calc := NewCalculator()
	for i := 0; i < b.N; i++ {
		calc.Add(100, 200)
	}
}

func BenchmarkCalculator_Multiply(b *testing.B) {
	calc := NewCalculator()
	for i := 0; i < b.N; i++ {
		calc.Multiply(100, 200)
	}
}

func ExampleCalculator_Add() {
	calc := NewCalculator()
	result := calc.Add(5, 3)
	fmt.Println(result)
	// Output: 8
}

func ExampleCalculator_Multiply() {
	calc := NewCalculator()
	result := calc.Multiply(5, 3)
	fmt.Println(result)
	// Output: 15
}
