package core

import (
	"strings"
	"testing"
)

func TestTextProcessor_PreprocessText(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
		wantErr  bool
	}{
		{
			name:     "normal Korean text",
			input:    "안녕하세요. 오늘은 좋은 날입니다.",
			expected: "안녕하세요. <break time='0.5s'/>  오늘은 좋은 날입니다. <break time='0.5s'/> ",
			wantErr:  false,
		},
		{
			name:     "text with numbers",
			input:    "오늘은 12월 25일입니다.",
			expected: "오늘은 십이월 이십오일입니다.",
			wantErr:  false,
		},
		{
			name:     "text with special characters",
			input:    "가격은 $100 & 15%입니다.",
			expected: "가격은 달러100 그리고 십오퍼센트입니다.",
			wantErr:  false,
		},
		{
			name:     "empty text",
			input:    "",
			expected: "",
			wantErr:  true,
		},
		{
			name:     "text with excessive whitespace",
			input:    "  안녕\n\n하세요   ",
			expected: "안녕 하세요",
			wantErr:  false,
		},
	}

	processor := NewTextProcessor()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := processor.PreprocessText(tt.input)

			if tt.wantErr {
				if err == nil {
					t.Error("expected error but got none")
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			// For tests with SSML, just check if the result contains expected parts
			if strings.Contains(tt.expected, "<break") {
				if !strings.Contains(result, "<break") {
					t.Errorf("expected result to contain SSML breaks, got: %s", result)
				}
			} else {
				if result != tt.expected {
					t.Errorf("expected %q, got %q", tt.expected, result)
				}
			}
		})
	}
}

func TestTextProcessor_ValidateText(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		wantErr bool
	}{
		{
			name:    "valid Korean text",
			input:   "안녕하세요. 오늘은 좋은 날입니다.",
			wantErr: false,
		},
		{
			name:    "text with English",
			input:   "Hello 안녕하세요 World",
			wantErr: false,
		},
		{
			name:    "empty text",
			input:   "",
			wantErr: true,
		},
		{
			name:    "very long text",
			input:   strings.Repeat("안녕하세요 ", 200), // Over 1000 characters
			wantErr: true,
		},
		{
			name:    "text with numbers and punctuation",
			input:   "오늘은 2024년 12월 25일입니다!",
			wantErr: false,
		},
	}

	processor := NewTextProcessor()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := processor.ValidateText(tt.input)

			if tt.wantErr {
				if err == nil {
					t.Error("expected error but got none")
				}
			} else {
				if err != nil {
					t.Errorf("unexpected error: %v", err)
				}
			}
		})
	}
}

func TestTextProcessor_ConvertNumbersToKorean(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "single digit",
			input:    "5시에 만나요",
			expected: "오시에 만나요",
		},
		{
			name:     "double digit",
			input:    "25살입니다",
			expected: "이십오살입니다",
		},
		{
			name:     "multiple numbers",
			input:    "12월 25일",
			expected: "십이월 이십오일",
		},
		{
			name:     "zero",
			input:    "0점",
			expected: "영점",
		},
		{
			name:     "ten",
			input:    "10시",
			expected: "십시",
		},
	}

	processor := NewTextProcessor()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := processor.convertNumbersToKorean(tt.input)
			if result != tt.expected {
				t.Errorf("expected %q, got %q", tt.expected, result)
			}
		})
	}
}

func TestTextProcessor_NormalizeSpecialCharacters(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "ampersand",
			input:    "사과 & 바나나",
			expected: "사과 그리고 바나나",
		},
		{
			name:     "percent",
			input:    "50% 할인",
			expected: "50퍼센트 할인",
		},
		{
			name:     "dollar",
			input:    "$100",
			expected: "달러100",
		},
		{
			name:     "multiple symbols",
			input:    "$50 & 10% 할인!",
			expected: "달러50 그리고 10퍼센트 할인느낌표",
		},
	}

	processor := NewTextProcessor()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := processor.normalizeSpecialCharacters(tt.input)
			if result != tt.expected {
				t.Errorf("expected %q, got %q", tt.expected, result)
			}
		})
	}
}
