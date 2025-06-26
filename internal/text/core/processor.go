package core

import (
	"golang.org/x/text/cases"
	"golang.org/x/text/language"
	"strings"
)

// Processor implements text processing business logic
type Processor struct{}

// NewProcessor creates a new Processor instance
func NewProcessor() *Processor {
	return &Processor{}
}

// Reverse returns the reversed version of the input string
func (p *Processor) Reverse(s string) string {
	runes := []rune(s)
	for i, j := 0, len(runes)-1; i < j; i, j = i+1, j-1 {
		runes[i], runes[j] = runes[j], runes[i]
	}
	return string(runes)
}

// Capitalize capitalizes the first letter of each word
func (p *Processor) Capitalize(s string) string {
	caser := cases.Title(language.English)
	return caser.String(strings.ToLower(s))
}