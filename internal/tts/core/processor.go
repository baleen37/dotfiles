package core

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"unicode"
)

// TextProcessor implements text processing for TTS
type TextProcessor struct{}

// NewTextProcessor creates a new text processor
func NewTextProcessor() *TextProcessor {
	return &TextProcessor{}
}

// PreprocessText processes text before TTS generation
func (p *TextProcessor) PreprocessText(text string) (string, error) {
	if text == "" {
		return "", fmt.Errorf("text is empty")
	}

	// Remove excessive whitespace
	processed := strings.TrimSpace(text)
	processed = regexp.MustCompile(`\s+`).ReplaceAllString(processed, " ")

	// Convert numbers to Korean words
	processed = p.convertNumbersToKorean(processed)

	// Handle special characters and punctuation for natural speech
	processed = p.normalizeSpecialCharacters(processed)

	// Add SSML pauses for better speech flow
	processed = p.addSSMLPauses(processed)

	return processed, nil
}

// ValidateText validates text for TTS requirements
func (p *TextProcessor) ValidateText(text string) error {
	if text == "" {
		return fmt.Errorf("text is empty")
	}

	// Check text length (Korean TTS works well with 100-500 characters per segment)
	if len([]rune(text)) > 1000 {
		return fmt.Errorf("text too long: %d characters (max 1000)", len([]rune(text)))
	}

	// Check for unsupported characters
	for _, r := range text {
		if !p.isSupportedCharacter(r) {
			return fmt.Errorf("unsupported character: %c", r)
		}
	}

	return nil
}

// convertNumbersToKorean converts Arabic numerals to Korean words
func (p *TextProcessor) convertNumbersToKorean(text string) string {
	// Simple number conversion for common cases
	numberRegex := regexp.MustCompile(`\d+`)
	return numberRegex.ReplaceAllStringFunc(text, func(match string) string {
		num, err := strconv.Atoi(match)
		if err != nil {
			return match // Return original if conversion fails
		}
		return p.numberToKorean(num)
	})
}

// numberToKorean converts a number to Korean words (simplified version)
func (p *TextProcessor) numberToKorean(num int) string {
	if num == 0 {
		return "영"
	}

	// Simple conversion for numbers 1-100
	ones := []string{"", "일", "이", "삼", "사", "오", "육", "칠", "팔", "구"}
	tens := []string{"", "십", "이십", "삼십", "사십", "오십", "육십", "칠십", "팔십", "구십"}

	if num < 10 {
		return ones[num]
	} else if num < 100 {
		tensDigit := num / 10
		onesDigit := num % 10
		result := tens[tensDigit]
		if onesDigit > 0 {
			result += ones[onesDigit]
		}
		return result
	}

	// For numbers >= 100, return as is for now
	return strconv.Itoa(num)
}

// normalizeSpecialCharacters handles special characters for natural speech
func (p *TextProcessor) normalizeSpecialCharacters(text string) string {
	// Replace common symbols with spoken equivalents
	replacements := map[string]string{
		"&":   "그리고",
		"%":   "퍼센트",
		"@":   "골뱅이",
		"#":   "샵",
		"$":   "달러",
		"₩":   "원",
		"...": "점점점",
		"!":   "느낌표",
		"?":   "물음표",
	}

	result := text
	for symbol, replacement := range replacements {
		result = strings.ReplaceAll(result, symbol, replacement)
	}

	return result
}

// addSSMLPauses adds SSML pause tags for better speech flow
func (p *TextProcessor) addSSMLPauses(text string) string {
	// Add short pauses after sentence endings
	text = regexp.MustCompile(`([.!?])\s+`).ReplaceAllString(text, "$1 <break time='0.5s'/>")

	// Add very short pauses after commas
	text = regexp.MustCompile(`,\s+`).ReplaceAllString(text, ", <break time='0.2s'/>")

	return text
}

// isSupportedCharacter checks if a character is supported for Korean TTS
func (p *TextProcessor) isSupportedCharacter(r rune) bool {
	// Allow Korean characters (Hangul)
	if unicode.Is(unicode.Hangul, r) {
		return true
	}

	// Allow basic Latin characters
	if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') {
		return true
	}

	// Allow numbers
	if unicode.IsDigit(r) {
		return true
	}

	// Allow common punctuation and whitespace
	if unicode.IsPunct(r) || unicode.IsSpace(r) {
		return true
	}

	// Allow SSML tags (basic check)
	if r == '<' || r == '>' || r == '/' || r == '\'' || r == '"' || r == '=' {
		return true
	}

	return false
}
