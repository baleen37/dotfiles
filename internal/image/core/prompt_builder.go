package core

import (
	"fmt"
	"strings"

	"ssulmeta-go/internal/image/ports"
	"ssulmeta-go/pkg/models"
)

// PromptBuilder implements the prompt building logic
type PromptBuilder struct{}

// NewPromptBuilder creates a new prompt builder
func NewPromptBuilder() ports.PromptBuilder {
	return &PromptBuilder{}
}

// BuildPrompt creates an image generation prompt from scene description
func (pb *PromptBuilder) BuildPrompt(scene models.Scene, style string) string {
	// Base prompt components
	var promptParts []string

	// Add scene description
	if scene.Description != "" {
		promptParts = append(promptParts, scene.Description)
	}

	// Add style consistency
	if style != "" {
		promptParts = append(promptParts, style)
	}

	// Add technical requirements
	technicalRequirements := []string{
		"vertical orientation",
		"9:16 aspect ratio",
		"high quality",
		"detailed",
		"youtube shorts format",
	}
	promptParts = append(promptParts, strings.Join(technicalRequirements, ", "))

	// Add composition guidelines
	compositionGuidelines := []string{
		"centered composition",
		"clear focal point",
		"suitable for mobile viewing",
	}
	promptParts = append(promptParts, strings.Join(compositionGuidelines, ", "))

	// Combine all parts
	prompt := strings.Join(promptParts, ", ")

	// Clean up and format
	prompt = cleanPrompt(prompt)

	return prompt
}

// BuildPromptsForStory creates prompts for all scenes maintaining style consistency
func (pb *PromptBuilder) BuildPromptsForStory(scenes []models.Scene, style string) []string {
	prompts := make([]string, len(scenes))

	// Extract consistent elements from the story
	characterDescriptions := extractCharacterDescriptions(scenes)
	settingDescription := extractSettingDescription(scenes)

	// Build each prompt with consistency elements
	for i, scene := range scenes {
		// Start with the base prompt
		basePrompt := pb.BuildPrompt(scene, style)

		// Add consistency elements
		var consistencyParts []string

		// Add character consistency
		if characterDescriptions != "" {
			consistencyParts = append(consistencyParts, fmt.Sprintf("characters: %s", characterDescriptions))
		}

		// Add setting consistency
		if settingDescription != "" {
			consistencyParts = append(consistencyParts, fmt.Sprintf("setting: %s", settingDescription))
		}

		// Add scene number for progression
		consistencyParts = append(consistencyParts, fmt.Sprintf("scene %d of %d", scene.Number, len(scenes)))

		// Combine base prompt with consistency elements
		if len(consistencyParts) > 0 {
			prompts[i] = fmt.Sprintf("%s, %s", basePrompt, strings.Join(consistencyParts, ", "))
		} else {
			prompts[i] = basePrompt
		}
	}

	return prompts
}

// cleanPrompt removes redundant spaces and commas
func cleanPrompt(prompt string) string {
	// Remove multiple spaces
	prompt = strings.Join(strings.Fields(prompt), " ")

	// Remove multiple commas
	for strings.Contains(prompt, ",,") {
		prompt = strings.ReplaceAll(prompt, ",,", ",")
	}

	// Trim spaces around commas
	prompt = strings.ReplaceAll(prompt, " ,", ",")
	prompt = strings.ReplaceAll(prompt, ", ", ", ")

	// Trim leading/trailing spaces and commas
	prompt = strings.Trim(prompt, " ,")

	return prompt
}

// extractCharacterDescriptions analyzes scenes to find consistent character descriptions
func extractCharacterDescriptions(scenes []models.Scene) string {
	// This is a simplified version - in production, you might use NLP
	// to extract character descriptions more intelligently

	characterKeywords := []string{
		"주인공", "소녀", "소년", "여자", "남자", "아이", "할머니", "할아버지",
		"공주", "왕자", "마녀", "요정", "동물", "친구",
	}

	foundCharacters := make(map[string]bool)

	for _, scene := range scenes {
		desc := scene.Description
		for _, keyword := range characterKeywords {
			if strings.Contains(desc, keyword) {
				foundCharacters[keyword] = true
			}
		}
	}

	if len(foundCharacters) == 0 {
		return ""
	}

	// Build character description string
	var characters []string
	for char := range foundCharacters {
		characters = append(characters, char)
	}

	return strings.Join(characters, ", ")
}

// extractSettingDescription analyzes scenes to find consistent setting
func extractSettingDescription(scenes []models.Scene) string {
	// This is a simplified version - in production, you might use NLP
	// to extract setting descriptions more intelligently

	settingKeywords := []string{
		"숲", "마을", "집", "성", "학교", "공원", "바다", "산", "하늘",
		"도시", "시골", "정원", "방", "거리", "길",
	}

	foundSettings := make(map[string]bool)

	for _, scene := range scenes {
		desc := scene.Description
		for _, keyword := range settingKeywords {
			if strings.Contains(desc, keyword) {
				foundSettings[keyword] = true
			}
		}
	}

	if len(foundSettings) == 0 {
		return ""
	}

	// Build setting description string
	var settings []string
	for setting := range foundSettings {
		settings = append(settings, setting)
	}

	// Limit to most important settings
	if len(settings) > 3 {
		settings = settings[:3]
	}

	return strings.Join(settings, ", ")
}
