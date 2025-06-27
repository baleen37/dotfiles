package story

import (
	"fmt"
	"ssulmeta-go/pkg/models"
	"strings"
	"unicode/utf8"
)

// Validator validates story content
type Validator struct {
	minLength int
	maxLength int
}

// NewValidator creates a new story validator
func NewValidator() *Validator {
	return &Validator{
		minLength: 270,
		maxLength: 300,
	}
}

// ValidateStory validates a story
func (v *Validator) ValidateStory(story *models.Story) error {
	if story == nil {
		return fmt.Errorf("story is nil")
	}

	// Check title
	if err := v.validateTitle(story.Title); err != nil {
		return fmt.Errorf("title validation failed: %w", err)
	}

	// Check content
	if err := v.validateContent(story.Content); err != nil {
		return fmt.Errorf("content validation failed: %w", err)
	}

	// Check story structure
	if err := v.validateStructure(story.Content); err != nil {
		return fmt.Errorf("structure validation failed: %w", err)
	}

	return nil
}

// validateTitle validates the story title
func (v *Validator) validateTitle(title string) error {
	if title == "" {
		return fmt.Errorf("title is empty")
	}

	if utf8.RuneCountInString(title) > 50 {
		return fmt.Errorf("title too long (max 50 characters)")
	}

	return nil
}

// validateContent validates the story content
func (v *Validator) validateContent(content string) error {
	if content == "" {
		return fmt.Errorf("content is empty")
	}

	// Count characters (not bytes)
	charCount := utf8.RuneCountInString(content)

	if charCount < v.minLength {
		return fmt.Errorf("content too short: %d characters (min %d)", charCount, v.minLength)
	}

	if charCount > v.maxLength {
		return fmt.Errorf("content too long: %d characters (max %d)", charCount, v.maxLength)
	}

	// Check for inappropriate content (basic check)
	if err := v.checkInappropriateContent(content); err != nil {
		return err
	}

	return nil
}

// validateStructure checks if the story has a clear structure
func (v *Validator) validateStructure(content string) error {
	// Check if the story has at least 3 sentences (beginning, middle, end)
	sentences := strings.Split(content, ".")
	cleanSentences := make([]string, 0)

	for _, s := range sentences {
		s = strings.TrimSpace(s)
		if s != "" {
			cleanSentences = append(cleanSentences, s)
		}
	}

	if len(cleanSentences) < 3 {
		return fmt.Errorf("story needs at least 3 sentences for proper structure")
	}

	return nil
}

// checkInappropriateContent performs basic content filtering
func (v *Validator) checkInappropriateContent(content string) error {
	// This is a very basic implementation
	// In production, you might want to use a more sophisticated content filter

	inappropriateWords := []string{
		// Add inappropriate words to filter
		// For POC, we'll keep this minimal
	}

	lowerContent := strings.ToLower(content)
	for _, word := range inappropriateWords {
		if strings.Contains(lowerContent, word) {
			return fmt.Errorf("inappropriate content detected")
		}
	}

	return nil
}

// ValidateScenes validates the scenes
func (v *Validator) ValidateScenes(scenes []models.Scene) error {
	if len(scenes) < 6 {
		return fmt.Errorf("too few scenes: %d (min 6)", len(scenes))
	}

	if len(scenes) > 10 {
		return fmt.Errorf("too many scenes: %d (max 10)", len(scenes))
	}

	for i, scene := range scenes {
		if scene.Description == "" {
			return fmt.Errorf("scene %d has empty description", i+1)
		}

		if scene.ImagePrompt == "" {
			return fmt.Errorf("scene %d has empty image prompt", i+1)
		}

		if scene.Duration <= 0 {
			return fmt.Errorf("scene %d has invalid duration: %f", i+1, scene.Duration)
		}
	}

	return nil
}
