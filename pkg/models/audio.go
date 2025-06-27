package models

import "time"

// AudioFile represents a generated audio file
type AudioFile struct {
	ID         string    `json:"id"`
	Path       string    `json:"path"`
	Format     string    `json:"format"`
	Duration   float64   `json:"duration"` // seconds
	SampleRate int       `json:"sample_rate"`
	FileSize   int64     `json:"file_size"`
	Text       string    `json:"text"`
	Language   string    `json:"language"`
	Voice      string    `json:"voice"`
	CreatedAt  time.Time `json:"created_at"`
}

// AudioSegment represents a segment of audio with timing information
type AudioSegment struct {
	SceneNumber int        `json:"scene_number"`
	Text        string     `json:"text"`
	StartTime   float64    `json:"start_time"` // seconds
	EndTime     float64    `json:"end_time"`   // seconds
	AudioFile   *AudioFile `json:"audio_file"`
}
