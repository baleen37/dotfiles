package models

// Story represents a generated story with scenes
type Story struct {
	Title   string  `json:"title"`
	Content string  `json:"content"`
	Scenes  []Scene `json:"scenes"`
}

// Scene represents a single scene in the story
type Scene struct {
	Number      int     `json:"number"`
	Description string  `json:"description"`
	ImagePrompt string  `json:"image_prompt"`
	Duration    float64 `json:"duration"` // seconds
}
