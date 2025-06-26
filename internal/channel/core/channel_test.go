package core

import (
	"testing"
	"time"
)

func TestNewChannel(t *testing.T) {
	tests := []struct {
		name        string
		id          string
		channelName string
		concept     string
		wantErr     bool
		errMessage  string
	}{
		{
			name:        "Valid channel creation",
			id:          "ch_123",
			channelName: "Tech Shorts",
			concept:     "Latest technology trends explained in 60 seconds",
			wantErr:     false,
		},
		{
			name:        "Empty ID",
			id:          "",
			channelName: "Tech Shorts",
			concept:     "Latest technology trends",
			wantErr:     true,
			errMessage:  "channel ID cannot be empty",
		},
		{
			name:        "Empty channel name",
			id:          "ch_123",
			channelName: "",
			concept:     "Latest technology trends",
			wantErr:     true,
			errMessage:  "channel name cannot be empty",
		},
		{
			name:        "Empty concept",
			id:          "ch_123",
			channelName: "Tech Shorts",
			concept:     "",
			wantErr:     true,
			errMessage:  "channel concept cannot be empty",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			channel, err := NewChannel(tt.id, tt.channelName, tt.concept)
			
			if tt.wantErr {
				if err == nil {
					t.Errorf("NewChannel() error = nil, wantErr %v", tt.wantErr)
					return
				}
				if err.Error() != tt.errMessage {
					t.Errorf("NewChannel() error = %v, wantErr %v", err.Error(), tt.errMessage)
				}
				return
			}
			
			if err != nil {
				t.Errorf("NewChannel() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			
			if channel.ID != tt.id {
				t.Errorf("Channel.ID = %v, want %v", channel.ID, tt.id)
			}
			
			if channel.Name != tt.channelName {
				t.Errorf("Channel.Name = %v, want %v", channel.Name, tt.channelName)
			}
			
			if channel.Concept != tt.concept {
				t.Errorf("Channel.Concept = %v, want %v", channel.Concept, tt.concept)
			}
			
			if channel.IsActive != true {
				t.Errorf("Channel.IsActive = %v, want %v", channel.IsActive, true)
			}
			
			if channel.CreatedAt.IsZero() {
				t.Error("Channel.CreatedAt should not be zero")
			}
			
			if channel.UpdatedAt.IsZero() {
				t.Error("Channel.UpdatedAt should not be zero")
			}
		})
	}
}

func TestChannel_UpdateSettings(t *testing.T) {
	channel, _ := NewChannel("ch_123", "Tech Shorts", "Technology trends")
	
	tests := []struct {
		name       string
		settings   ChannelSettings
		wantErr    bool
		errMessage string
	}{
		{
			name: "Valid settings update",
			settings: ChannelSettings{
				MaxVideoDuration: 60,
				VideoWidth:       1080,
				VideoHeight:      1920,
				VideoFPS:         30,
				Language:         "ko",
			},
			wantErr: false,
		},
		{
			name: "Invalid video duration",
			settings: ChannelSettings{
				MaxVideoDuration: 0,
				VideoWidth:       1080,
				VideoHeight:      1920,
				VideoFPS:         30,
				Language:         "ko",
			},
			wantErr:    true,
			errMessage: "max video duration must be greater than 0",
		},
		{
			name: "Invalid video dimensions",
			settings: ChannelSettings{
				MaxVideoDuration: 60,
				VideoWidth:       0,
				VideoHeight:      1920,
				VideoFPS:         30,
				Language:         "ko",
			},
			wantErr:    true,
			errMessage: "video width and height must be greater than 0",
		},
		{
			name: "Invalid FPS",
			settings: ChannelSettings{
				MaxVideoDuration: 60,
				VideoWidth:       1080,
				VideoHeight:      1920,
				VideoFPS:         0,
				Language:         "ko",
			},
			wantErr:    true,
			errMessage: "video FPS must be greater than 0",
		},
		{
			name: "Empty language",
			settings: ChannelSettings{
				MaxVideoDuration: 60,
				VideoWidth:       1080,
				VideoHeight:      1920,
				VideoFPS:         30,
				Language:         "",
			},
			wantErr:    true,
			errMessage: "language cannot be empty",
		},
	}
	
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := channel.UpdateSettings(tt.settings)
			
			if tt.wantErr {
				if err == nil {
					t.Errorf("UpdateSettings() error = nil, wantErr %v", tt.wantErr)
					return
				}
				if err.Error() != tt.errMessage {
					t.Errorf("UpdateSettings() error = %v, wantErr %v", err.Error(), tt.errMessage)
				}
				return
			}
			
			if err != nil {
				t.Errorf("UpdateSettings() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}

func TestChannel_Deactivate(t *testing.T) {
	channel, _ := NewChannel("ch_123", "Tech Shorts", "Technology trends")
	
	// Initially should be active
	if !channel.IsActive {
		t.Error("Channel should be active initially")
	}
	
	// Deactivate channel
	channel.Deactivate()
	
	if channel.IsActive {
		t.Error("Channel should be deactivated")
	}
	
	// UpdatedAt should be updated
	if channel.UpdatedAt.Before(channel.CreatedAt) || channel.UpdatedAt.Equal(channel.CreatedAt) {
		t.Error("UpdatedAt should be after CreatedAt after deactivation")
	}
}

func TestChannel_Activate(t *testing.T) {
	channel, _ := NewChannel("ch_123", "Tech Shorts", "Technology trends")
	channel.Deactivate()
	
	// Should be inactive
	if channel.IsActive {
		t.Error("Channel should be inactive")
	}
	
	time.Sleep(1 * time.Millisecond) // Ensure time difference
	
	// Activate channel
	channel.Activate()
	
	if !channel.IsActive {
		t.Error("Channel should be activated")
	}
	
	// UpdatedAt should be updated again
	if channel.UpdatedAt.Before(channel.CreatedAt) || channel.UpdatedAt.Equal(channel.CreatedAt) {
		t.Error("UpdatedAt should be after CreatedAt after activation")
	}
}