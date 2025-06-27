package adapters

import (
	"fmt"
	"regexp"
	"ssulmeta-go/pkg/models"
	"strings"
	"unicode/utf8"
)

// SceneSplitter handles the logic for splitting stories into scenes
type SceneSplitter struct {
	minScenes     int
	maxScenes     int
	minSceneChars int
	maxSceneChars int
}

// NewSceneSplitter creates a new scene splitter with default configuration
func NewSceneSplitter() *SceneSplitter {
	return &SceneSplitter{
		minScenes:     6,
		maxScenes:     10,
		minSceneChars: 20, // Minimum characters per scene
		maxSceneChars: 80, // Maximum characters per scene
	}
}

// SplitResult contains the results of scene splitting
type SplitResult struct {
	Scenes      []SceneContent
	TotalScenes int
}

// SceneContent represents the content of a single scene
type SceneContent struct {
	Number     int
	Text       string
	StartIndex int
	EndIndex   int
	KeyPhrases []string
	SceneType  SceneType
}

// SceneType represents the type of scene for better image generation
type SceneType int

const (
	OpeningScene SceneType = iota
	ActionScene
	DialogueScene
	TransitionScene
	ClimaxScene
	ClosingScene
)

// SplitIntoScenes analyzes the story and splits it into appropriate scenes
func (s *SceneSplitter) SplitIntoScenes(story *models.Story) (*SplitResult, error) {
	if story.Content == "" {
		return nil, fmt.Errorf("story content is empty")
	}

	// Step 1: Analyze text for natural break points
	breakPoints := s.findNaturalBreakPoints(story.Content)

	// Step 2: Determine optimal number of scenes based on content length
	targetScenes := s.calculateTargetScenes(story.Content)

	// Step 3: Split content based on break points and target scenes
	sceneContents := s.splitByBreakPoints(story.Content, breakPoints, targetScenes)

	// Step 4: Analyze and classify each scene
	for i := range sceneContents {
		sceneContents[i].KeyPhrases = s.extractKeyPhrases(sceneContents[i].Text)
		sceneContents[i].SceneType = s.classifyScene(sceneContents[i].Text, i, len(sceneContents))
	}

	return &SplitResult{
		Scenes:      sceneContents,
		TotalScenes: len(sceneContents),
	}, nil
}

// findNaturalBreakPoints identifies natural breaking points in Korean text
func (s *SceneSplitter) findNaturalBreakPoints(content string) []int {
	var breakPoints []int

	// Korean sentence endings and transition markers
	patterns := []string{
		`[.!?][\s]*`,             // Sentence endings
		`습니다[\s]*`,               // Formal endings
		`었습니다[\s]*`, `았습니다[\s]*`, // Past tense formal endings
		`그런데[\s]*`, `그러나[\s]*`, `하지만[\s]*`, // Conjunctions
		`그때[\s]*`, `그러자[\s]*`, `그리고[\s]*`, // Time/sequence markers
		`한편[\s]*`, `이때[\s]*`, `그 후[\s]*`, // Temporal transitions
	}

	for _, pattern := range patterns {
		re := regexp.MustCompile(pattern)
		matches := re.FindAllStringIndex(content, -1)
		for _, match := range matches {
			breakPoints = append(breakPoints, match[1])
		}
	}

	// Sort and deduplicate break points
	breakPoints = s.sortAndDeduplicate(breakPoints)

	return breakPoints
}

// calculateTargetScenes determines the optimal number of scenes based on content length
func (s *SceneSplitter) calculateTargetScenes(content string) int {
	contentLength := utf8.RuneCountInString(content)

	// Base calculation: aim for 25-35 characters per scene for Korean text
	targetByLength := contentLength / 30

	// For very long content, ensure we reach max scenes
	if contentLength > 350 {
		targetByLength = s.maxScenes
	}

	// Ensure it's within our min/max bounds
	if targetByLength < s.minScenes {
		return s.minScenes
	}
	if targetByLength > s.maxScenes {
		return s.maxScenes
	}

	return targetByLength
}

// splitByBreakPoints splits content into scenes using identified break points
func (s *SceneSplitter) splitByBreakPoints(content string, breakPoints []int, targetScenes int) []SceneContent {
	if len(breakPoints) == 0 {
		// Fallback: split by equal length
		return s.splitByEqualLength(content, targetScenes)
	}

	// Select best break points for target number of scenes
	selectedBreaks := s.selectOptimalBreaks(breakPoints, targetScenes, len(content))

	var scenes []SceneContent
	start := 0

	for i, breakPoint := range selectedBreaks {
		sceneText := strings.TrimSpace(content[start:breakPoint])
		if sceneText != "" {
			scenes = append(scenes, SceneContent{
				Number:     i + 1,
				Text:       sceneText,
				StartIndex: start,
				EndIndex:   breakPoint,
			})
		}
		start = breakPoint
	}

	// Add the last scene if there's remaining content
	if start < len(content) {
		lastText := strings.TrimSpace(content[start:])
		if lastText != "" {
			scenes = append(scenes, SceneContent{
				Number:     len(scenes) + 1,
				Text:       lastText,
				StartIndex: start,
				EndIndex:   len(content),
			})
		}
	}

	return scenes
}

// selectOptimalBreaks chooses the best break points for the target number of scenes
func (s *SceneSplitter) selectOptimalBreaks(breakPoints []int, targetScenes int, contentLength int) []int {
	if len(breakPoints) <= targetScenes {
		return breakPoints
	}

	// Calculate ideal positions for scenes
	idealInterval := contentLength / targetScenes
	var selected []int

	for i := 1; i < targetScenes; i++ {
		idealPos := i * idealInterval

		// Find the closest break point to the ideal position
		closest := breakPoints[0]
		minDiff := abs(closest - idealPos)

		for _, bp := range breakPoints {
			diff := abs(bp - idealPos)
			if diff < minDiff {
				minDiff = diff
				closest = bp
			}
		}

		// Avoid selecting the same break point twice
		if !contains(selected, closest) {
			selected = append(selected, closest)
		}
	}

	return selected
}

// splitByEqualLength provides a fallback method to split by equal lengths
func (s *SceneSplitter) splitByEqualLength(content string, targetScenes int) []SceneContent {
	runes := []rune(content)
	sceneLength := len(runes) / targetScenes

	var scenes []SceneContent

	for i := 0; i < targetScenes; i++ {
		start := i * sceneLength
		end := start + sceneLength

		if i == targetScenes-1 {
			end = len(runes) // Include remaining content in last scene
		}

		sceneText := strings.TrimSpace(string(runes[start:end]))
		if sceneText != "" {
			scenes = append(scenes, SceneContent{
				Number:     i + 1,
				Text:       sceneText,
				StartIndex: start,
				EndIndex:   end,
			})
		}
	}

	return scenes
}

// extractKeyPhrases identifies key phrases for image generation
func (s *SceneSplitter) extractKeyPhrases(text string) []string {
	var phrases []string

	// Common Korean descriptive patterns (simplified for better matching)
	patterns := []string{
		`[가-힣]+한\s+[가-힣]+`,  // Adjective + noun patterns (e.g., "아름다운 숲")
		`[가-힣]+의\s+[가-힣]+`,  // Possessive patterns (e.g., "소녀의 마음")
		`[가-힣]+에서\s*[가-힣]+`, // Location patterns (e.g., "숲에서 뛰어다녔")
		`[가-힣]+이\s+[가-힣]+`,  // Subject patterns (e.g., "토끼가 뛰었")
	}

	for _, pattern := range patterns {
		re := regexp.MustCompile(pattern)
		matches := re.FindAllString(text, -1)
		phrases = append(phrases, matches...)
	}

	// Remove duplicates and limit to top 3 key phrases
	uniquePhrases := make(map[string]bool)
	var result []string
	for _, phrase := range phrases {
		if !uniquePhrases[phrase] && len(result) < 3 {
			uniquePhrases[phrase] = true
			result = append(result, phrase)
		}
	}

	return result
}

// classifyScene determines the type of scene for better image generation
func (s *SceneSplitter) classifyScene(text string, index int, totalScenes int) SceneType {
	// First scene is usually opening
	if index == 0 {
		return OpeningScene
	}

	// Last scene is usually closing
	if index == totalScenes-1 {
		return ClosingScene
	}

	// Check for action indicators
	actionWords := []string{"달렸", "뛰었", "싸웠", "도망쳤", "날아갔", "부딪"}
	for _, word := range actionWords {
		if strings.Contains(text, word) {
			return ActionScene
		}
	}

	// Check for dialogue indicators
	dialogueMarkers := []string{"말했", "대답했", "물었", "소리쳤", "속삭였"}
	for _, marker := range dialogueMarkers {
		if strings.Contains(text, marker) {
			return DialogueScene
		}
	}

	// Check for climax indicators (usually in the latter half)
	if index > totalScenes/2 {
		climaxWords := []string{"마침내", "드디어", "결국", "갑자기"}
		for _, word := range climaxWords {
			if strings.Contains(text, word) {
				return ClimaxScene
			}
		}
	}

	// Default to transition scene
	return TransitionScene
}

// Utility functions

func (s *SceneSplitter) sortAndDeduplicate(breakPoints []int) []int {
	if len(breakPoints) == 0 {
		return breakPoints
	}

	// Simple bubble sort for small arrays
	for i := 0; i < len(breakPoints)-1; i++ {
		for j := 0; j < len(breakPoints)-i-1; j++ {
			if breakPoints[j] > breakPoints[j+1] {
				breakPoints[j], breakPoints[j+1] = breakPoints[j+1], breakPoints[j]
			}
		}
	}

	// Remove duplicates
	var unique []int
	prev := -1
	for _, bp := range breakPoints {
		if bp != prev {
			unique = append(unique, bp)
			prev = bp
		}
	}

	return unique
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

func contains(slice []int, item int) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
