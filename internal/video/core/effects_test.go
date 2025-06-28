package core

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"ssulmeta-go/internal/video/ports"
)

func TestKenBurnsEffect_CalculateParameters(t *testing.T) {
	tests := []struct {
		name     string
		config   ports.KenBurnsConfig
		duration time.Duration
		want     ports.KenBurnsParams
		wantErr  bool
	}{
		{
			name: "zoom in effect",
			config: ports.KenBurnsConfig{
				StartZoom: 1.0,
				EndZoom:   1.2,
				StartX:    0.5,
				StartY:    0.5,
				EndX:      0.4,
				EndY:      0.4,
			},
			duration: 3 * time.Second,
			want: ports.KenBurnsParams{
				ZoomDelta: 0.2,
				XDelta:    -0.1,
				YDelta:    -0.1,
				Duration:  3 * time.Second,
				StartZoom: 1.0,
				EndZoom:   1.2,
				StartX:    0.5,
				StartY:    0.5,
				EndX:      0.4,
				EndY:      0.4,
			},
			wantErr: false,
		},
		{
			name: "zoom out with pan",
			config: ports.KenBurnsConfig{
				StartZoom: 1.3,
				EndZoom:   1.0,
				StartX:    0.3,
				StartY:    0.3,
				EndX:      0.7,
				EndY:      0.7,
			},
			duration: 2 * time.Second,
			want: ports.KenBurnsParams{
				ZoomDelta: -0.3,
				XDelta:    0.4,
				YDelta:    0.4,
				Duration:  2 * time.Second,
				StartZoom: 1.3,
				EndZoom:   1.0,
				StartX:    0.3,
				StartY:    0.3,
				EndX:      0.7,
				EndY:      0.7,
			},
			wantErr: false,
		},
		{
			name: "invalid zoom values",
			config: ports.KenBurnsConfig{
				StartZoom: 0.5, // Too small
				EndZoom:   1.2,
				StartX:    0.5,
				StartY:    0.5,
				EndX:      0.5,
				EndY:      0.5,
			},
			duration: 3 * time.Second,
			wantErr:  true,
		},
		{
			name: "invalid position values",
			config: ports.KenBurnsConfig{
				StartZoom: 1.0,
				EndZoom:   1.2,
				StartX:    1.5, // Out of bounds
				StartY:    0.5,
				EndX:      0.5,
				EndY:      0.5,
			},
			duration: 3 * time.Second,
			wantErr:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			effect := NewKenBurnsEffect()

			params, err := effect.CalculateParameters(tt.config, tt.duration)

			if tt.wantErr {
				assert.Error(t, err)
				return
			}

			require.NoError(t, err)

			// Use approximate equality for floating point comparisons
			assert.InDelta(t, tt.want.StartZoom, params.StartZoom, 0.001)
			assert.InDelta(t, tt.want.EndZoom, params.EndZoom, 0.001)
			assert.InDelta(t, tt.want.StartX, params.StartX, 0.001)
			assert.InDelta(t, tt.want.StartY, params.StartY, 0.001)
			assert.InDelta(t, tt.want.EndX, params.EndX, 0.001)
			assert.InDelta(t, tt.want.EndY, params.EndY, 0.001)
			assert.InDelta(t, tt.want.ZoomDelta, params.ZoomDelta, 0.001)
			assert.InDelta(t, tt.want.XDelta, params.XDelta, 0.001)
			assert.InDelta(t, tt.want.YDelta, params.YDelta, 0.001)
			assert.Equal(t, tt.want.Duration, params.Duration)
		})
	}
}

func TestKenBurnsEffect_GenerateFFmpegFilter(t *testing.T) {
	tests := []struct {
		name   string
		params ports.KenBurnsParams
		width  int
		height int
		want   string
	}{
		{
			name: "basic zoom in",
			params: ports.KenBurnsParams{
				StartZoom: 1.0,
				EndZoom:   1.2,
				StartX:    0.5,
				StartY:    0.5,
				EndX:      0.4,
				EndY:      0.4,
				Duration:  3 * time.Second,
			},
			width:  1080,
			height: 1920,
			want:   "zoompan=z='if(lte(on,0),1.0,1.0+(1.2-1.0)*on/3.0)':x='if(lte(on,0),540.0,540.0+(-108.0)*on/3.0)':y='if(lte(on,0),960.0,960.0+(-192.0)*on/3.0)':d=90:s=1080x1920",
		},
		{
			name: "zoom out with pan",
			params: ports.KenBurnsParams{
				StartZoom: 1.3,
				EndZoom:   1.0,
				StartX:    0.3,
				StartY:    0.3,
				EndX:      0.7,
				EndY:      0.7,
				Duration:  2 * time.Second,
			},
			width:  1080,
			height: 1920,
			want:   "zoompan=z='if(lte(on,0),1.3,1.3+(1.0-1.3)*on/2.0)':x='if(lte(on,0),324.0,324.0+(432.0)*on/2.0)':y='if(lte(on,0),576.0,576.0+(768.0)*on/2.0)':d=60:s=1080x1920",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			effect := NewKenBurnsEffect()

			filter := effect.GenerateFFmpegFilter(tt.params, tt.width, tt.height)

			assert.Equal(t, tt.want, filter)
		})
	}
}

func TestTransitionEffect_CalculateParameters(t *testing.T) {
	tests := []struct {
		name           string
		transitionType ports.TransitionType
		duration       time.Duration
		want           ports.TransitionParams
		wantErr        bool
	}{
		{
			name:           "crossfade transition",
			transitionType: ports.TransitionTypeCrossfade,
			duration:       500 * time.Millisecond,
			want: ports.TransitionParams{
				Type:     ports.TransitionTypeCrossfade,
				Duration: 500 * time.Millisecond,
				Offset:   0,
			},
			wantErr: false,
		},
		{
			name:           "fade in transition",
			transitionType: ports.TransitionTypeFadeIn,
			duration:       1 * time.Second,
			want: ports.TransitionParams{
				Type:     ports.TransitionTypeFadeIn,
				Duration: 1 * time.Second,
				Offset:   0,
			},
			wantErr: false,
		},
		{
			name:           "invalid duration",
			transitionType: ports.TransitionTypeCrossfade,
			duration:       0,
			wantErr:        true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			effect := NewTransitionEffect()

			params, err := effect.CalculateParameters(tt.transitionType, tt.duration)

			if tt.wantErr {
				assert.Error(t, err)
				return
			}

			require.NoError(t, err)
			assert.Equal(t, tt.want, *params)
		})
	}
}

func TestTransitionEffect_GenerateFFmpegFilter(t *testing.T) {
	tests := []struct {
		name   string
		params ports.TransitionParams
		want   string
	}{
		{
			name: "crossfade between two clips",
			params: ports.TransitionParams{
				Type:     ports.TransitionTypeCrossfade,
				Duration: 500 * time.Millisecond,
				Offset:   0,
			},
			want: "xfade=transition=fade:duration=0.5:offset=0",
		},
		{
			name: "fade in at start",
			params: ports.TransitionParams{
				Type:     ports.TransitionTypeFadeIn,
				Duration: 1 * time.Second,
				Offset:   0,
			},
			want: "fade=in:0:30", // Assuming 30fps
		},
		{
			name: "fade out at end",
			params: ports.TransitionParams{
				Type:     ports.TransitionTypeFadeOut,
				Duration: 1 * time.Second,
				Offset:   2 * time.Second,
			},
			want: "fade=out:60:30", // Starting at frame 60 (2 seconds * 30fps)
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			effect := NewTransitionEffect()

			filter := effect.GenerateFFmpegFilter(tt.params, 30) // 30 FPS

			assert.Equal(t, tt.want, filter)
		})
	}
}

func TestSubtitleOverlay_CalculateParameters(t *testing.T) {
	tests := []struct {
		name    string
		config  ports.SubtitleConfig
		want    ports.SubtitleParams
		wantErr bool
	}{
		{
			name: "bottom center subtitle",
			config: ports.SubtitleConfig{
				Text:      "Test subtitle",
				Position:  ports.SubtitlePositionBottom,
				FontSize:  48,
				FontColor: "#FFFFFF",
				BgColor:   "#000000",
				Duration:  3 * time.Second,
				StartTime: 1 * time.Second,
			},
			want: ports.SubtitleParams{
				Text:      "Test subtitle",
				X:         "(w-text_w)/2", // Center horizontally
				Y:         "h-text_h-50",  // Bottom with padding
				FontSize:  48,
				FontColor: "#FFFFFF",
				BgColor:   "#000000",
				Duration:  3 * time.Second,
				StartTime: 1 * time.Second,
			},
			wantErr: false,
		},
		{
			name: "top left subtitle",
			config: ports.SubtitleConfig{
				Text:      "Top left text",
				Position:  ports.SubtitlePositionTopLeft,
				FontSize:  36,
				FontColor: "#FFFF00",
				Duration:  2 * time.Second,
				StartTime: 0,
			},
			want: ports.SubtitleParams{
				Text:      "Top left text",
				X:         "50", // Left padding
				Y:         "50", // Top padding
				FontSize:  36,
				FontColor: "#FFFF00",
				BgColor:   "",
				Duration:  2 * time.Second,
				StartTime: 0,
			},
			wantErr: false,
		},
		{
			name: "empty text",
			config: ports.SubtitleConfig{
				Text:     "",
				Position: ports.SubtitlePositionBottom,
				FontSize: 48,
			},
			wantErr: true,
		},
		{
			name: "invalid font size",
			config: ports.SubtitleConfig{
				Text:     "Test",
				Position: ports.SubtitlePositionBottom,
				FontSize: 0,
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			effect := NewSubtitleOverlay()

			params, err := effect.CalculateParameters(tt.config)

			if tt.wantErr {
				assert.Error(t, err)
				return
			}

			require.NoError(t, err)
			assert.Equal(t, tt.want, *params)
		})
	}
}

func TestSubtitleOverlay_GenerateFFmpegFilter(t *testing.T) {
	tests := []struct {
		name   string
		params ports.SubtitleParams
		want   string
	}{
		{
			name: "basic subtitle with background",
			params: ports.SubtitleParams{
				Text:      "Test subtitle",
				X:         "(w-text_w)/2",
				Y:         "h-text_h-50",
				FontSize:  48,
				FontColor: "#FFFFFF",
				BgColor:   "#000000",
				Duration:  3 * time.Second,
				StartTime: 1 * time.Second,
			},
			want: "drawtext=text='Test subtitle':fontsize=48:fontcolor=#FFFFFF:box=1:boxcolor=#000000:x=(w-text_w)/2:y=h-text_h-50:enable='between(t,1.0,4.0)'",
		},
		{
			name: "subtitle without background",
			params: ports.SubtitleParams{
				Text:      "Simple text",
				X:         "50",
				Y:         "50",
				FontSize:  36,
				FontColor: "#FFFF00",
				BgColor:   "",
				Duration:  2 * time.Second,
				StartTime: 0,
			},
			want: "drawtext=text='Simple text':fontsize=36:fontcolor=#FFFF00:x=50:y=50:enable='between(t,0.0,2.0)'",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			effect := NewSubtitleOverlay()

			filter := effect.GenerateFFmpegFilter(tt.params)

			assert.Equal(t, tt.want, filter)
		})
	}
}

func TestWatermarkOverlay_CalculateParameters(t *testing.T) {
	tests := []struct {
		name    string
		config  ports.WatermarkConfig
		want    ports.WatermarkParams
		wantErr bool
	}{
		{
			name: "bottom right watermark",
			config: ports.WatermarkConfig{
				ImagePath: "/path/to/watermark.png",
				Position:  ports.WatermarkPositionBottomRight,
				Scale:     0.1,
				Opacity:   0.7,
			},
			want: ports.WatermarkParams{
				ImagePath: "/path/to/watermark.png",
				X:         "main_w-overlay_w-20", // Bottom right with padding
				Y:         "main_h-overlay_h-20",
				Scale:     0.1,
				Opacity:   0.7,
			},
			wantErr: false,
		},
		{
			name: "top left watermark",
			config: ports.WatermarkConfig{
				ImagePath: "/path/to/logo.png",
				Position:  ports.WatermarkPositionTopLeft,
				Scale:     0.15,
				Opacity:   1.0,
			},
			want: ports.WatermarkParams{
				ImagePath: "/path/to/logo.png",
				X:         "20", // Top left with padding
				Y:         "20",
				Scale:     0.15,
				Opacity:   1.0,
			},
			wantErr: false,
		},
		{
			name: "invalid image path",
			config: ports.WatermarkConfig{
				ImagePath: "",
				Position:  ports.WatermarkPositionBottomRight,
				Scale:     0.1,
				Opacity:   0.7,
			},
			wantErr: true,
		},
		{
			name: "invalid scale",
			config: ports.WatermarkConfig{
				ImagePath: "/path/to/watermark.png",
				Position:  ports.WatermarkPositionBottomRight,
				Scale:     1.5, // Too large
				Opacity:   0.7,
			},
			wantErr: true,
		},
		{
			name: "invalid opacity",
			config: ports.WatermarkConfig{
				ImagePath: "/path/to/watermark.png",
				Position:  ports.WatermarkPositionBottomRight,
				Scale:     0.1,
				Opacity:   1.5, // Out of range
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			effect := NewWatermarkOverlay()

			params, err := effect.CalculateParameters(tt.config)

			if tt.wantErr {
				assert.Error(t, err)
				return
			}

			require.NoError(t, err)
			assert.Equal(t, tt.want, *params)
		})
	}
}

func TestWatermarkOverlay_GenerateFFmpegFilter(t *testing.T) {
	tests := []struct {
		name   string
		params ports.WatermarkParams
		want   string
	}{
		{
			name: "watermark with transparency",
			params: ports.WatermarkParams{
				ImagePath: "/path/to/watermark.png",
				X:         "main_w-overlay_w-20",
				Y:         "main_h-overlay_h-20",
				Scale:     0.1,
				Opacity:   0.7,
			},
			want: "[0:v][1:v]overlay=main_w-overlay_w-20:main_h-overlay_h-20:format=auto:alpha=1",
		},
		{
			name: "opaque watermark",
			params: ports.WatermarkParams{
				ImagePath: "/path/to/logo.png",
				X:         "20",
				Y:         "20",
				Scale:     0.15,
				Opacity:   1.0,
			},
			want: "[0:v][1:v]overlay=20:20:format=auto:alpha=1",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			effect := NewWatermarkOverlay()

			filter := effect.GenerateFFmpegFilter(tt.params)

			assert.Equal(t, tt.want, filter)
		})
	}
}

func TestEffectChain_BuildComplexFilter(t *testing.T) {
	tests := []struct {
		name    string
		effects []ports.VideoEffect
		want    string
		wantErr bool
	}{
		{
			name: "ken burns with subtitle",
			effects: []ports.VideoEffect{
				{
					Type: ports.EffectTypeKenBurns,
					KenBurns: &ports.KenBurnsParams{
						StartZoom: 1.0,
						EndZoom:   1.2,
						StartX:    0.5,
						StartY:    0.5,
						EndX:      0.4,
						EndY:      0.4,
						Duration:  3 * time.Second,
					},
				},
				{
					Type: ports.EffectTypeSubtitle,
					Subtitle: &ports.SubtitleParams{
						Text:      "Test subtitle",
						X:         "(w-text_w)/2",
						Y:         "h-text_h-50",
						FontSize:  48,
						FontColor: "#FFFFFF",
						BgColor:   "#000000",
						Duration:  3 * time.Second,
						StartTime: 1 * time.Second,
					},
				},
			},
			want: "[0:v]zoompan=z='if(lte(on,0),1.0,1.0+(1.2-1.0)*on/3.0)':x='if(lte(on,0),540.0,540.0+(-108.0)*on/3.0)':y='if(lte(on,0),960.0,960.0+(-192.0)*on/3.0)':d=90:s=1080x1920[kb0];[kb0]drawtext=text='Test subtitle':fontsize=48:fontcolor=#FFFFFF:box=1:boxcolor=#000000:x=(w-text_w)/2:y=h-text_h-50:enable='between(t,1.0,4.0)'[out]",
		},
		{
			name: "crossfade transition only",
			effects: []ports.VideoEffect{
				{
					Type: ports.EffectTypeTransition,
					Transition: &ports.TransitionParams{
						Type:     ports.TransitionTypeCrossfade,
						Duration: 500 * time.Millisecond,
						Offset:   0,
					},
				},
			},
			want: "[0:v][1:v]xfade=transition=fade:duration=0.5:offset=0[out]",
		},
		{
			name:    "empty effects",
			effects: []ports.VideoEffect{},
			want:    "[0:v]copy[out]",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			chain := NewEffectChain()

			filter, err := chain.BuildComplexFilter(tt.effects, 1080, 1920, 30)

			if tt.wantErr {
				assert.Error(t, err)
				return
			}

			require.NoError(t, err)
			assert.Equal(t, tt.want, filter)
		})
	}
}
