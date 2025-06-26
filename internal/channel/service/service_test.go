package service

import (
	"context"
	"ssulmeta-go/internal/channel/core"
	"ssulmeta-go/internal/channel/test"
	"testing"
)

func TestNewChannelService(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	
	if service == nil {
		t.Error("NewChannelService() should not return nil")
	}
}

func TestChannelService_CreateChannel(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()
	
	tests := []struct {
		name    string
		id      string
		chName  string
		concept string
		wantErr bool
		setup   func()
	}{
		{
			name:    "Valid channel creation",
			id:      "ch_123",
			chName:  "Tech Channel",
			concept: "Technology content",
			wantErr: false,
		},
		{
			name:    "Empty ID",
			id:      "",
			chName:  "Tech Channel",
			concept: "Technology content",
			wantErr: true,
		},
		{
			name:    "Empty name",
			id:      "ch_123",
			chName:  "",
			concept: "Technology content",
			wantErr: true,
		},
		{
			name:    "Empty concept",
			id:      "ch_123",
			chName:  "Tech Channel",
			concept: "",
			wantErr: true,
		},
		{
			name:    "Repository failure",
			id:      "ch_fail",
			chName:  "Tech Channel",
			concept: "Technology content",
			wantErr: true,
			setup: func() {
				repo.ShouldFailCreate = true
			},
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset repository
			repo.Reset()
			
			if tt.setup != nil {
				tt.setup()
			}
			
			channel, err := service.CreateChannel(ctx, tt.id, tt.chName, tt.concept)
			
			if tt.wantErr {
				if err == nil {
					t.Errorf("CreateChannel() error = nil, wantErr %v", tt.wantErr)
				}
				return
			}
			
			if err != nil {
				t.Errorf("CreateChannel() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			
			if channel.ID != tt.id {
				t.Errorf("Channel.ID = %v, want %v", channel.ID, tt.id)
			}
			
			if channel.Name != tt.chName {
				t.Errorf("Channel.Name = %v, want %v", channel.Name, tt.chName)
			}
			
			if channel.Concept != tt.concept {
				t.Errorf("Channel.Concept = %v, want %v", channel.Concept, tt.concept)
			}
		})
	}
}

func TestChannelService_GetChannel(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()
	
	// Create test channel via service to ensure it's in the mock repo
	_, _ = service.CreateChannel(ctx, "ch_123", "Tech Channel", "Technology content")
	
	tests := []struct {
		name    string
		id      string
		wantErr bool
		setup   func()
	}{
		{
			name:    "Existing channel",
			id:      "ch_123",
			wantErr: false,
		},
		{
			name:    "Non-existing channel",
			id:      "ch_nonexistent",
			wantErr: true,
		},
		{
			name:    "Repository failure",
			id:      "ch_123",
			wantErr: true,
			setup: func() {
				repo.ShouldFailGet = true
			},
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset mock behavior but keep data
			repo.ShouldFailGet = false
			
			if tt.setup != nil {
				tt.setup()
			}
			
			channel, err := service.GetChannel(ctx, tt.id)
			
			if tt.wantErr {
				if err == nil {
					t.Errorf("GetChannel() error = nil, wantErr %v", tt.wantErr)
				}
				return
			}
			
			if err != nil {
				t.Errorf("GetChannel() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			
			if channel.ID != tt.id {
				t.Errorf("Channel.ID = %v, want %v", channel.ID, tt.id)
			}
		})
	}
}

func TestChannelService_UpdateChannelSettings(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()
	
	// Create test channel
	_, _ = service.CreateChannel(ctx, "ch_123", "Tech Channel", "Technology content")
	
	validSettings := core.ChannelSettings{
		MaxVideoDuration: 60,
		VideoWidth:       1080,
		VideoHeight:      1920,
		VideoFPS:         30,
		Language:         "ko",
	}
	
	invalidSettings := core.ChannelSettings{
		MaxVideoDuration: 0, // Invalid
		VideoWidth:       1080,
		VideoHeight:      1920,
		VideoFPS:         30,
		Language:         "ko",
	}
	
	tests := []struct {
		name     string
		id       string
		settings core.ChannelSettings
		wantErr  bool
		setup    func()
	}{
		{
			name:     "Valid settings update",
			id:       "ch_123",
			settings: validSettings,
			wantErr:  false,
		},
		{
			name:     "Invalid settings",
			id:       "ch_123",
			settings: invalidSettings,
			wantErr:  true,
		},
		{
			name:     "Non-existing channel",
			id:       "ch_nonexistent",
			settings: validSettings,
			wantErr:  true,
		},
		{
			name:     "Repository get failure",
			id:       "ch_123",
			settings: validSettings,
			wantErr:  true,
			setup: func() {
				repo.ShouldFailGet = true
			},
		},
		{
			name:     "Repository update failure",
			id:       "ch_123",
			settings: validSettings,
			wantErr:  true,
			setup: func() {
				repo.ShouldFailUpdate = true
			},
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Reset mock behavior
			repo.ShouldFailGet = false
			repo.ShouldFailUpdate = false
			
			if tt.setup != nil {
				tt.setup()
			}
			
			channel, err := service.UpdateChannelSettings(ctx, tt.id, tt.settings)
			
			if tt.wantErr {
				if err == nil {
					t.Errorf("UpdateChannelSettings() error = nil, wantErr %v", tt.wantErr)
				}
				return
			}
			
			if err != nil {
				t.Errorf("UpdateChannelSettings() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			
			if channel.Settings != tt.settings {
				t.Errorf("Channel.Settings not updated correctly")
			}
		})
	}
}

func TestChannelService_ActivateDeactivateChannel(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()
	
	// Create test channel (initially active)
	_, _ = service.CreateChannel(ctx, "ch_123", "Tech Channel", "Technology content")
	
	// Test deactivation
	channel, err := service.DeactivateChannel(ctx, "ch_123")
	if err != nil {
		t.Errorf("DeactivateChannel() error = %v", err)
	}
	
	if channel.IsActive {
		t.Error("Channel should be deactivated")
	}
	
	// Test activation
	channel, err = service.ActivateChannel(ctx, "ch_123")
	if err != nil {
		t.Errorf("ActivateChannel() error = %v", err)
	}
	
	if !channel.IsActive {
		t.Error("Channel should be activated")
	}
	
	// Test with non-existing channel
	_, err = service.ActivateChannel(ctx, "ch_nonexistent")
	if err == nil {
		t.Error("ActivateChannel() should fail for non-existing channel")
	}
}

func TestChannelService_DeleteChannel(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()
	
	// Create test channel
	_, _ = service.CreateChannel(ctx, "ch_123", "Tech Channel", "Technology content")
	
	// Test successful deletion
	err := service.DeleteChannel(ctx, "ch_123")
	if err != nil {
		t.Errorf("DeleteChannel() error = %v", err)
	}
	
	// Verify channel is deleted by trying to get it
	_, err = service.GetChannel(ctx, "ch_123")
	if err == nil {
		t.Error("Channel should be deleted")
	}
	
	// Test deleting non-existing channel
	err = service.DeleteChannel(ctx, "ch_nonexistent")
	if err == nil {
		t.Error("DeleteChannel() should fail for non-existing channel")
	}
}

func TestChannelService_ListChannels(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()
	
	// Create test channels
	_, _ = service.CreateChannel(ctx, "ch_active", "Active Channel", "Active concept")
	_, _ = service.CreateChannel(ctx, "ch_inactive", "Inactive Channel", "Inactive concept")
	
	// Deactivate one channel
	_, _ = service.DeactivateChannel(ctx, "ch_inactive")
	
	// Test listing all channels
	allChannels, err := service.ListChannels(ctx, false)
	if err != nil {
		t.Errorf("ListChannels() error = %v", err)
	}
	
	if len(allChannels) != 2 {
		t.Errorf("ListChannels() returned %d channels, want 2", len(allChannels))
	}
	
	// Test listing only active channels
	activeChannels, err := service.ListChannels(ctx, true)
	if err != nil {
		t.Errorf("ListChannels() error = %v", err)
	}
	
	if len(activeChannels) != 1 {
		t.Errorf("ListChannels(activeOnly=true) returned %d channels, want 1", len(activeChannels))
	}
	
	if !activeChannels[0].IsActive {
		t.Error("Listed channel should be active")
	}
}

func TestChannelService_ChannelExists(t *testing.T) {
	repo := test.NewMockRepository()
	service := NewChannelService(repo)
	ctx := context.Background()
	
	// Create test channel
	_, _ = service.CreateChannel(ctx, "ch_123", "Tech Channel", "Technology content")
	
	// Test existing channel
	exists, err := service.ChannelExists(ctx, "ch_123")
	if err != nil {
		t.Errorf("ChannelExists() error = %v", err)
	}
	
	if !exists {
		t.Error("ChannelExists() should return true for existing channel")
	}
	
	// Test non-existing channel
	exists, err = service.ChannelExists(ctx, "ch_nonexistent")
	if err != nil {
		t.Errorf("ChannelExists() error = %v", err)
	}
	
	if exists {
		t.Error("ChannelExists() should return false for non-existing channel")
	}
}