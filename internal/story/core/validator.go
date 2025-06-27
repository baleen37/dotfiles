package core

import (
	"ssulmeta-go/internal/story/ports"
	"ssulmeta-go/pkg/errors"
	"ssulmeta-go/pkg/models"
	"strings"
	"unicode/utf8"
)

// Validator validates story content
type Validator struct {
	minLength int
	maxLength int
}

// Ensure Validator implements the Validator interface
var _ ports.Validator = (*Validator)(nil)

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
		return errors.New(errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "story is nil")
	}

	// Check title
	if err := v.validateTitle(story.Title); err != nil {
		return errors.Wrap(err, errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "title validation failed")
	}

	// Check content
	if err := v.validateContent(story.Content); err != nil {
		return errors.Wrap(err, errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "content validation failed")
	}

	// Check story structure
	if err := v.validateStructure(story.Content); err != nil {
		return errors.Wrap(err, errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "structure validation failed")
	}

	return nil
}

// validateTitle validates the story title
func (v *Validator) validateTitle(title string) error {
	if title == "" {
		return errors.New(errors.ErrorTypeValidation, errors.CodeStoryEmpty, "title is empty")
	}

	titleLength := utf8.RuneCountInString(title)
	if titleLength > 50 {
		return errors.New(errors.ErrorTypeValidation, errors.CodeStoryTooLong, "title too long").
			WithDetails("maxLength", 50).
			WithDetails("actualLength", titleLength)
	}

	return nil
}

// validateContent validates the story content
func (v *Validator) validateContent(content string) error {
	if content == "" {
		return errors.New(errors.ErrorTypeValidation, errors.CodeStoryEmpty, "content is empty")
	}

	// Count characters (not bytes)
	charCount := utf8.RuneCountInString(content)

	if charCount < v.minLength {
		return errors.New(errors.ErrorTypeValidation, errors.CodeStoryTooShort, "content too short").
			WithDetails("minLength", v.minLength).
			WithDetails("actualLength", charCount)
	}

	if charCount > v.maxLength {
		return errors.New(errors.ErrorTypeValidation, errors.CodeStoryTooLong, "content too long").
			WithDetails("maxLength", v.maxLength).
			WithDetails("actualLength", charCount)
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
		return errors.New(errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "story needs at least 3 sentences for proper structure").
			WithDetails("minSentences", 3).
			WithDetails("actualSentences", len(cleanSentences))
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
			return errors.New(errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "inappropriate content detected").
				WithDetails("reason", "inappropriate content")
		}
	}

	return nil
}

// ValidateScenes validates the scenes
func (v *Validator) ValidateScenes(scenes []*models.Scene) error {
	if len(scenes) < 6 {
		return errors.New(errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "too few scenes").
			WithDetails("minScenes", 6).
			WithDetails("actualScenes", len(scenes))
	}

	if len(scenes) > 10 {
		return errors.New(errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "too many scenes").
			WithDetails("maxScenes", 10).
			WithDetails("actualScenes", len(scenes))
	}

	for i, scene := range scenes {
		if scene.Description == "" {
			return errors.New(errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "scene has empty description").
				WithDetails("sceneNumber", i+1)
		}

		if scene.ImagePrompt == "" {
			return errors.New(errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "scene has empty image prompt").
				WithDetails("sceneNumber", i+1)
		}

		if scene.Duration <= 0 {
			return errors.New(errors.ErrorTypeValidation, errors.CodeStoryValidationFailed, "scene has invalid duration").
				WithDetails("sceneNumber", i+1).
				WithDetails("duration", scene.Duration)
		}
	}

	return nil
}
