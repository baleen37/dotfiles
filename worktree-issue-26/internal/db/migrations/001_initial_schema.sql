-- Initial schema for YouTube Shorts Generator (Simplified)

-- Channels table
CREATE TABLE IF NOT EXISTS channels (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    youtube_channel_id VARCHAR(100),
    prompt_template TEXT,
    tags TEXT[], -- Array of default tags for this channel
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Posts table (YouTube videos)
CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    channel_id INTEGER REFERENCES channels(id),
    
    -- Story data
    title VARCHAR(500),
    story_content TEXT NOT NULL,
    
    -- Generated assets paths
    audio_file_path VARCHAR(500),
    video_file_path VARCHAR(500),
    thumbnail_path VARCHAR(500),
    
    -- YouTube data
    youtube_video_id VARCHAR(100),
    youtube_url VARCHAR(500),
    description TEXT,
    tags TEXT[],
    
    -- Status tracking
    status VARCHAR(50) DEFAULT 'draft', -- draft, generating, ready, uploaded, failed
    error_message TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    generated_at TIMESTAMP WITH TIME ZONE,
    uploaded_at TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_posts_channel_id ON posts(channel_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for channels updated_at
CREATE TRIGGER update_channels_updated_at BEFORE UPDATE ON channels
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();