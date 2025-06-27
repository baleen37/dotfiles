package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"ssulmeta-go/internal/channel"
	"ssulmeta-go/internal/config"
	"ssulmeta-go/internal/image"
	"ssulmeta-go/internal/story"
	"ssulmeta-go/internal/tts"
	"ssulmeta-go/internal/video"
	"ssulmeta-go/pkg/logger"
	"ssulmeta-go/pkg/models"
)

func main() {
	// Set environment
	if err := os.Setenv("APP_ENV", "test"); err != nil {
		log.Fatalf("Failed to set environment: %v", err)
	}

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Initialize logger
	if err := logger.Init(&cfg.Logging); err != nil {
		log.Fatalf("Failed to init logger: %v", err)
	}

	// Create output directory
	outputDir := filepath.Join("assets", "test_output", time.Now().Format("20060102_150405"))
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		log.Fatalf("Failed to create output directory: %v", err)
	}

	fmt.Printf("Output directory: %s\n\n", outputDir)

	// Test pipeline with fairy tale channel
	if err := runPipeline(cfg, "fairy_tale", outputDir); err != nil {
		logger.Error("Pipeline failed", "error", err)
		os.Exit(1)
	}

	fmt.Println("\n✅ Pipeline test completed successfully!")
	fmt.Printf("Check the output in: %s\n", outputDir)
}

func runPipeline(cfg *config.Config, channelName string, outputDir string) error {
	ctx := context.Background()

	// 1. Load channel config
	fmt.Println("📚 Step 1: Loading channel configuration...")
	channelCfg, err := channel.LoadChannelConfig(channelName)
	if err != nil {
		return fmt.Errorf("failed to load channel config: %w", err)
	}
	ch := channelCfg.ToModel()
	fmt.Printf("   Channel: %s\n", ch.Name)
	fmt.Printf("   Tags: %v\n", ch.Tags)

	// 2. Generate story
	fmt.Println("\n📝 Step 2: Generating story...")
	storySvc, err := story.NewServiceWithConfig(&cfg.API, &cfg.Story, cfg.HTTPClient.OpenAITimeout)
	if err != nil {
		return fmt.Errorf("failed to create story service: %w", err)
	}

	generatedStory, err := storySvc.GenerateStory(ctx, ch)
	if err != nil {
		return fmt.Errorf("failed to generate story: %w", err)
	}

	fmt.Printf("   Title: %s\n", generatedStory.Title)
	fmt.Printf("   Length: %d characters\n", len([]rune(generatedStory.Content)))
	fmt.Printf("   Scenes: %d\n", len(generatedStory.Scenes))

	// Save story to file
	storyFile := filepath.Join(outputDir, "story.txt")
	if err := saveStory(storyFile, generatedStory); err != nil {
		return fmt.Errorf("failed to save story: %w", err)
	}
	fmt.Printf("   Saved to: %s\n", storyFile)

	// 3. Generate images
	fmt.Println("\n🎨 Step 3: Generating images for scenes...")

	// Create image container
	imageContainer, err := image.NewContainer(cfg, logger.Get())
	if err != nil {
		return fmt.Errorf("failed to create image container: %w", err)
	}

	// Generate images with channel style
	images, err := imageContainer.Service.GenerateStoryImages(ctx, *generatedStory, channelCfg.GetSceneStyle())
	if err != nil {
		return fmt.Errorf("failed to generate images: %w", err)
	}

	for i, imgPath := range images {
		fmt.Printf("   Scene %d: %s\n", i+1, filepath.Base(imgPath))
	}

	// 4. Generate audio
	fmt.Println("\n🎙️ Step 4: Generating narration...")

	// Debug: Print scene descriptions
	fmt.Println("   Scene descriptions:")
	for i, scene := range generatedStory.Scenes {
		fmt.Printf("   Scene %d: %q\n", i+1, scene.Description)
	}

	ttsFactory := tts.NewServiceFactory("", outputDir, true) // Use mock mode
	ttsSvc := ttsFactory.CreateService()

	audioFiles, err := ttsSvc.GenerateNarration(ctx, generatedStory)
	if err != nil {
		return fmt.Errorf("failed to generate narration: %w", err)
	}

	if len(audioFiles) == 0 {
		return fmt.Errorf("no audio files generated")
	}

	// Use the first audio file for pipeline test
	audioPath := audioFiles[0].Path
	duration := audioFiles[0].Duration

	fmt.Printf("   Audio file: %s\n", filepath.Base(audioPath))
	fmt.Printf("   Duration: %.1f seconds\n", duration)

	// 5. Compose video
	fmt.Println("\n🎬 Step 5: Composing video...")
	videoSvc := video.NewMockComposer(outputDir)

	videoMeta, err := videoSvc.ComposeVideo(ctx, images, audioPath, generatedStory.Scenes)
	if err != nil {
		return fmt.Errorf("failed to compose video: %w", err)
	}

	fmt.Printf("   Video file: %s\n", filepath.Base(videoMeta.FilePath))
	fmt.Printf("   Resolution: %dx%d\n", videoMeta.Width, videoMeta.Height)
	fmt.Printf("   Duration: %.1f seconds\n", videoMeta.Duration)
	fmt.Printf("   FPS: %d\n", videoMeta.FPS)
	fmt.Printf("   Size: %.2f MB\n", float64(videoMeta.FileSizeBytes)/(1024*1024))

	// 6. Generate thumbnail
	fmt.Println("\n🖼️ Step 6: Generating thumbnail...")
	thumbnailPath, err := videoSvc.GenerateThumbnail(ctx, videoMeta.FilePath)
	if err != nil {
		return fmt.Errorf("failed to generate thumbnail: %w", err)
	}

	fmt.Printf("   Thumbnail: %s\n", filepath.Base(thumbnailPath))

	// 7. Prepare for upload (mock)
	fmt.Println("\n📤 Step 7: Preparing YouTube metadata...")
	youtubeMeta := prepareYouTubeMetadata(generatedStory, ch)

	fmt.Printf("   Title: %s\n", youtubeMeta.Title)
	fmt.Printf("   Tags: %v\n", youtubeMeta.Tags)
	fmt.Printf("   Description preview: %s...\n", youtubeMeta.Description[:min(100, len(youtubeMeta.Description))])

	// Save metadata
	if err := saveMetadata(filepath.Join(outputDir, "metadata.txt"), youtubeMeta); err != nil {
		return fmt.Errorf("failed to save metadata: %w", err)
	}

	return nil
}

func saveStory(path string, story *models.Story) error {
	content := fmt.Sprintf("제목: %s\n\n내용:\n%s\n\n장면:\n", story.Title, story.Content)

	for _, scene := range story.Scenes {
		content += fmt.Sprintf("\n장면 %d:\n", scene.Number)
		content += fmt.Sprintf("설명: %s\n", scene.Description)
		content += fmt.Sprintf("이미지 프롬프트: %s\n", scene.ImagePrompt)
		content += fmt.Sprintf("길이: %.1f초\n", scene.Duration)
	}

	return os.WriteFile(path, []byte(content), 0644)
}

func prepareYouTubeMetadata(story *models.Story, channel *models.Channel) *models.YouTubeMetadata {
	description := fmt.Sprintf("%s\n\n#shorts", story.Content)

	tags := append(channel.Tags, "shorts", "이야기", "스토리")

	return &models.YouTubeMetadata{
		Title:       story.Title,
		Description: description,
		Tags:        tags,
		CategoryID:  "24",      // Entertainment
		Privacy:     "private", // Start with private
	}
}

func saveMetadata(path string, meta *models.YouTubeMetadata) error {
	content := fmt.Sprintf("Title: %s\n\nDescription:\n%s\n\nTags: %v\n\nCategory: %s\nPrivacy: %s\n",
		meta.Title,
		meta.Description,
		meta.Tags,
		meta.CategoryID,
		meta.Privacy,
	)

	return os.WriteFile(path, []byte(content), 0644)
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
