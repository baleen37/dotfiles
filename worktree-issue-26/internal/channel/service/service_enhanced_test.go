package service

import (
	"context"
	"errors"
	"ssulmeta-go/internal/channel/core"
	"ssulmeta-go/internal/channel/test"
	"strings"
	"testing"
	"time"
)

func TestChannelService_UpdateChannelInfo(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()

	// Create test channel
	_, err := service.CreateChannel(ctx, "ch_123", "Old Name", "Old Concept")
	if err != nil {
		t.Fatalf("Failed to create test channel: %v", err)
	}

	tests := []struct {
		name        string
		channelID   string
		newName     string
		newConcept  string
		wantErr     bool
		errContains string
	}{
		{
			name:       "successful update",
			channelID:  "ch_123",
			newName:    "New Name",
			newConcept: "New Concept",
			wantErr:    false,
		},
		{
			name:        "empty name",
			channelID:   "ch_123",
			newName:     "",
			newConcept:  "New Concept",
			wantErr:     true,
			errContains: "channel name cannot be empty",
		},
		{
			name:        "empty concept",
			channelID:   "ch_123",
			newName:     "New Name",
			newConcept:  "",
			wantErr:     true,
			errContains: "channel concept cannot be empty",
		},
		{
			name:        "non-existent channel",
			channelID:   "ch_nonexistent",
			newName:     "New Name",
			newConcept:  "New Concept",
			wantErr:     true,
			errContains: "not found",
		},
		{
			name:        "empty channel ID",
			channelID:   "",
			newName:     "New Name",
			newConcept:  "New Concept",
			wantErr:     true,
			errContains: "channel ID cannot be empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			channel, err := service.UpdateChannelInfo(ctx, tt.channelID, tt.newName, tt.newConcept)
			
			if (err != nil) != tt.wantErr {
				t.Errorf("UpdateChannelInfo() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			
			if err != nil && tt.errContains != "" {
				if !strings.Contains(err.Error(), tt.errContains) {
					t.Errorf("UpdateChannelInfo() error = %v, want error containing %s", err, tt.errContains)
				}
				return
			}
			
			if !tt.wantErr {
				if channel.Name != tt.newName {
					t.Errorf("Channel name = %s, want %s", channel.Name, tt.newName)
				}
				if channel.Concept != tt.newConcept {
					t.Errorf("Channel concept = %s, want %s", channel.Concept, tt.newConcept)
				}
				if channel.UpdatedAt.Before(time.Now().Add(-time.Minute)) {
					t.Error("UpdatedAt should be recent")
				}
			}
		})
	}
}

func TestChannelService_CreateChannel_EdgeCases(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()

	// Create a channel first
	_, err := service.CreateChannel(ctx, "ch_exists", "Existing Channel", "Existing concept")
	if err != nil {
		t.Fatalf("Failed to create initial channel: %v", err)
	}

	// Test creating duplicate channel
	_, err = service.CreateChannel(ctx, "ch_exists", "Another Name", "Another concept")
	if err == nil {
		t.Error("CreateChannel() should fail for duplicate ID")
	}
	if !strings.Contains(err.Error(), "already exists") {
		t.Errorf("CreateChannel() error = %v, want error about already exists", err)
	}
}

func TestChannelService_GetChannel_EdgeCases(t *testing.T) {
	service := NewChannelService(test.NewMockRepository())
	ctx := context.Background()

	// Test with empty ID
	_, err := service.GetChannel(ctx, "")
	if err == nil {
		t.Error("GetChannel() should fail for empty ID")
	}
	if !strings.Contains(err.Error(), "channel ID cannot be empty") {
		t.Errorf("GetChannel() error = %v, want error about empty ID", err)
	}
}

func TestChannelService_DeleteChannel_EdgeCases(t *testing.T) {
	service := NewChannelService(test.NewMockRepository())
	ctx := context.Background()

	// Test with empty ID
	err := service.DeleteChannel(ctx, "")
	if err == nil {
		t.Error("DeleteChannel() should fail for empty ID")
	}
	if !strings.Contains(err.Error(), "channel ID cannot be empty") {
		t.Errorf("DeleteChannel() error = %v, want error about empty ID", err)
	}
}

func TestChannelService_ChannelExists_EdgeCases(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()

	// Create a test channel
	_, _ = service.CreateChannel(ctx, "ch_123", "Test Channel", "Test concept")

	tests := []struct {
		name        string
		channelID   string
		wantExists  bool
		wantErr     bool
		errContains string
	}{
		{
			name:       "existing channel",
			channelID:  "ch_123",
			wantExists: true,
			wantErr:    false,
		},
		{
			name:       "non-existing channel",
			channelID:  "ch_nonexistent",
			wantExists: false,
			wantErr:    false,
		},
		{
			name:        "empty ID",
			channelID:   "",
			wantExists:  false,
			wantErr:     true,
			errContains: "channel ID cannot be empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			exists, err := service.ChannelExists(ctx, tt.channelID)
			
			if (err != nil) != tt.wantErr {
				t.Errorf("ChannelExists() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			
			if err != nil && tt.errContains != "" {
				if !strings.Contains(err.Error(), tt.errContains) {
					t.Errorf("ChannelExists() error = %v, want error containing %s", err, tt.errContains)
				}
				return
			}
			
			if !tt.wantErr && exists != tt.wantExists {
				t.Errorf("ChannelExists() = %v, want %v", exists, tt.wantExists)
			}
		})
	}
}

// Test repository error handling
func TestChannelService_RepositoryErrors(t *testing.T) {
	// Create a custom mock that returns errors
	errorRepo := &errorMockRepository{}
	service := NewChannelService(errorRepo)
	ctx := context.Background()

	t.Run("CreateChannel with repo error on Exists", func(t *testing.T) {
		errorRepo.failOn = "Exists"
		_, err := service.CreateChannel(ctx, "ch_123", "Test", "Test")
		if err == nil {
			t.Error("CreateChannel() should fail when repo.Exists fails")
		}
		if !strings.Contains(err.Error(), "failed to check if channel exists") {
			t.Errorf("CreateChannel() error = %v, want error about checking existence", err)
		}
	})

	t.Run("CreateChannel with repo error on Create", func(t *testing.T) {
		errorRepo.failOn = "Create"
		_, err := service.CreateChannel(ctx, "ch_123", "Test", "Test")
		if err == nil {
			t.Error("CreateChannel() should fail when repo.Create fails")
		}
		if !strings.Contains(err.Error(), "failed to save channel") {
			t.Errorf("CreateChannel() error = %v, want error about saving", err)
		}
	})

	t.Run("GetChannel with repo error", func(t *testing.T) {
		errorRepo.failOn = "GetByID"
		_, err := service.GetChannel(ctx, "ch_123")
		if err == nil {
			t.Error("GetChannel() should fail when repo.GetByID fails")
		}
		if !strings.Contains(err.Error(), "failed to get channel") {
			t.Errorf("GetChannel() error = %v, want error about getting channel", err)
		}
	})

	t.Run("UpdateChannelSettings with repo error", func(t *testing.T) {
		errorRepo.failOn = "Update"
		// First create a channel
		errorRepo.failOn = ""
		ch, _ := core.NewChannel("ch_123", "Test", "Test")
		errorRepo.channels["ch_123"] = ch
		
		// Now test update failure
		errorRepo.failOn = "Update"
		settings := core.ChannelSettings{
			MaxVideoDuration: 30,
			VideoWidth:       1920,
			VideoHeight:      1080,
			VideoFPS:         30,
			Language:         "en",
		}
		_, err := service.UpdateChannelSettings(ctx, "ch_123", settings)
		if err == nil {
			t.Error("UpdateChannelSettings() should fail when repo.Update fails")
		}
		if !strings.Contains(err.Error(), "failed to save updated channel") {
			t.Errorf("UpdateChannelSettings() error = %v, want error about saving", err)
		}
	})

	t.Run("UpdateChannelInfo with repo error", func(t *testing.T) {
		errorRepo.failOn = "Update"
		// First create a channel
		errorRepo.failOn = ""
		ch, _ := core.NewChannel("ch_123", "Test", "Test")
		errorRepo.channels["ch_123"] = ch
		
		// Now test update failure
		errorRepo.failOn = "Update"
		_, err := service.UpdateChannelInfo(ctx, "ch_123", "New Name", "New Concept")
		if err == nil {
			t.Error("UpdateChannelInfo() should fail when repo.Update fails")
		}
		if !strings.Contains(err.Error(), "failed to save updated channel") {
			t.Errorf("UpdateChannelInfo() error = %v, want error about saving", err)
		}
	})

	t.Run("ActivateChannel with repo error", func(t *testing.T) {
		errorRepo.failOn = "Update"
		// First create a channel
		errorRepo.failOn = ""
		ch, _ := core.NewChannel("ch_123", "Test", "Test")
		errorRepo.channels["ch_123"] = ch
		
		// Now test update failure
		errorRepo.failOn = "Update"
		_, err := service.ActivateChannel(ctx, "ch_123")
		if err == nil {
			t.Error("ActivateChannel() should fail when repo.Update fails")
		}
		if !strings.Contains(err.Error(), "failed to save activated channel") {
			t.Errorf("ActivateChannel() error = %v, want error about saving", err)
		}
	})

	t.Run("DeactivateChannel with repo error", func(t *testing.T) {
		errorRepo.failOn = "Update"
		// First create a channel
		errorRepo.failOn = ""
		ch, _ := core.NewChannel("ch_123", "Test", "Test")
		errorRepo.channels["ch_123"] = ch
		
		// Now test update failure
		errorRepo.failOn = "Update"
		_, err := service.DeactivateChannel(ctx, "ch_123")
		if err == nil {
			t.Error("DeactivateChannel() should fail when repo.Update fails")
		}
		if !strings.Contains(err.Error(), "failed to save deactivated channel") {
			t.Errorf("DeactivateChannel() error = %v, want error about saving", err)
		}
	})

	t.Run("DeleteChannel with repo error on Exists", func(t *testing.T) {
		errorRepo.failOn = "Exists"
		err := service.DeleteChannel(ctx, "ch_123")
		if err == nil {
			t.Error("DeleteChannel() should fail when repo.Exists fails")
		}
		if !strings.Contains(err.Error(), "failed to check if channel exists") {
			t.Errorf("DeleteChannel() error = %v, want error about checking existence", err)
		}
	})

	t.Run("DeleteChannel with repo error on Delete", func(t *testing.T) {
		errorRepo.failOn = "Delete"
		// First create a channel
		errorRepo.failOn = ""
		ch, _ := core.NewChannel("ch_123", "Test", "Test")
		errorRepo.channels["ch_123"] = ch
		
		// Now test delete failure
		errorRepo.failOn = "Delete"
		err := service.DeleteChannel(ctx, "ch_123")
		if err == nil {
			t.Error("DeleteChannel() should fail when repo.Delete fails")
		}
		if !strings.Contains(err.Error(), "failed to delete channel") {
			t.Errorf("DeleteChannel() error = %v, want error about deleting", err)
		}
	})

	t.Run("ListChannels with repo error", func(t *testing.T) {
		errorRepo.failOn = "List"
		_, err := service.ListChannels(ctx, false)
		if err == nil {
			t.Error("ListChannels() should fail when repo.List fails")
		}
		if !strings.Contains(err.Error(), "failed to list channels") {
			t.Errorf("ListChannels() error = %v, want error about listing", err)
		}
	})

	t.Run("ChannelExists with repo error", func(t *testing.T) {
		errorRepo.failOn = "Exists"
		_, err := service.ChannelExists(ctx, "ch_123")
		if err == nil {
			t.Error("ChannelExists() should fail when repo.Exists fails")
		}
		if !strings.Contains(err.Error(), "failed to check if channel exists") {
			t.Errorf("ChannelExists() error = %v, want error about checking existence", err)
		}
	})
}

// errorMockRepository is a mock repository that returns errors for specific methods
type errorMockRepository struct {
	failOn   string
	channels map[string]*core.Channel
}

func (r *errorMockRepository) Create(ctx context.Context, channel *core.Channel) error {
	if r.failOn == "Create" {
		return errors.New("repository error")
	}
	if r.channels == nil {
		r.channels = make(map[string]*core.Channel)
	}
	r.channels[channel.ID] = channel
	return nil
}

func (r *errorMockRepository) GetByID(ctx context.Context, id string) (*core.Channel, error) {
	if r.failOn == "GetByID" {
		return nil, errors.New("repository error")
	}
	if r.channels == nil {
		r.channels = make(map[string]*core.Channel)
	}
	ch, ok := r.channels[id]
	if !ok {
		return nil, errors.New("channel not found")
	}
	return ch, nil
}

func (r *errorMockRepository) Update(ctx context.Context, channel *core.Channel) error {
	if r.failOn == "Update" {
		return errors.New("repository error")
	}
	if r.channels == nil {
		r.channels = make(map[string]*core.Channel)
	}
	r.channels[channel.ID] = channel
	return nil
}

func (r *errorMockRepository) Delete(ctx context.Context, id string) error {
	if r.failOn == "Delete" {
		return errors.New("repository error")
	}
	if r.channels == nil {
		r.channels = make(map[string]*core.Channel)
	}
	delete(r.channels, id)
	return nil
}

func (r *errorMockRepository) List(ctx context.Context, activeOnly bool) ([]*core.Channel, error) {
	if r.failOn == "List" {
		return nil, errors.New("repository error")
	}
	if r.channels == nil {
		return []*core.Channel{}, nil
	}
	var result []*core.Channel
	for _, ch := range r.channels {
		if !activeOnly || ch.IsActive {
			result = append(result, ch)
		}
	}
	return result, nil
}

func (r *errorMockRepository) Exists(ctx context.Context, id string) (bool, error) {
	if r.failOn == "Exists" {
		return false, errors.New("repository error")
	}
	if r.channels == nil {
		r.channels = make(map[string]*core.Channel)
	}
	_, exists := r.channels[id]
	return exists, nil
}