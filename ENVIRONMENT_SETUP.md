# Environment Setup Guide

This guide provides detailed instructions for setting up the development and production environments for the ssulmeta-go YouTube Shorts generation system.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Development Environment](#development-environment)
- [Production Environment](#production-environment)
- [Environment Variables](#environment-variables)
- [External Services Setup](#external-services-setup)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or Windows with WSL2
- **CPU**: 4+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 50GB+ free space for video processing

### Required Software

1. **Go 1.24+**
   ```bash
   # macOS
   brew install go
   
   # Linux
   wget https://go.dev/dl/go1.24.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.24.linux-amd64.tar.gz
   export PATH=$PATH:/usr/local/go/bin
   ```

2. **Docker & Docker Compose**
   ```bash
   # macOS
   brew install --cask docker
   
   # Linux
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker $USER
   ```

3. **ffmpeg**
   ```bash
   # macOS
   brew install ffmpeg
   
   # Ubuntu/Debian
   sudo apt update
   sudo apt install ffmpeg
   
   # CentOS/RHEL
   sudo yum install epel-release
   sudo yum install ffmpeg
   ```

4. **Redis CLI** (optional, for debugging)
   ```bash
   # macOS
   brew install redis
   
   # Linux
   sudo apt install redis-tools
   ```

5. **PostgreSQL Client** (optional, for debugging)
   ```bash
   # macOS
   brew install postgresql
   
   # Linux
   sudo apt install postgresql-client
   ```

## Development Environment

### Quick Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/ssulmeta-go.git
   cd ssulmeta-go
   ```

2. **Install development tools**
   ```bash
   make setup-dev
   ```
   This installs:
   - goimports (code formatting)
   - golangci-lint (code quality)
   - git pre-commit hooks

3. **Start infrastructure services**
   ```bash
   docker-compose up -d
   ```
   This starts:
   - PostgreSQL (port 5432)
   - Redis (port 6379)
   - Adminer (port 8081) - Database UI

4. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

5. **Run database migrations**
   ```bash
   make migrate-up
   ```

6. **Verify setup**
   ```bash
   make test
   make dev
   ```

### IDE Setup

#### VS Code

1. Install Go extension
2. Create `.vscode/settings.json`:
   ```json
   {
     "go.useLanguageServer": true,
     "go.lintTool": "golangci-lint",
     "go.lintOnSave": "workspace",
     "go.formatTool": "goimports",
     "go.formatOnSave": true,
     "[go]": {
       "editor.formatOnSave": true,
       "editor.codeActionsOnSave": {
         "source.organizeImports": true
       }
     }
   }
   ```

#### GoLand

1. Enable goimports on save: Preferences → Tools → File Watchers → Add goimports
2. Configure golangci-lint: Preferences → Tools → External Tools → Add golangci-lint

### Local Configuration

Create `configs/local.yaml`:
```yaml
app:
  name: ssulmeta-go
  env: local
  debug: true

database:
  host: localhost
  port: 5432
  user: ssulmeta
  password: ssulmeta123!
  dbname: ssulmeta
  sslmode: disable

redis:
  host: localhost
  port: 6379
  db: 0

server:
  host: localhost
  port: 8080
  read_timeout: 30s
  write_timeout: 30s

api:
  use_mock: false  # Set to true for testing without API keys
  openai:
    model: gpt-4
    temperature: 0.7
  image:
    provider: stable_diffusion
    width: 1080
    height: 1920
  tts:
    provider: google
    language_code: ko-KR

storage:
  base_path: ./storage
  temp_path: ./temp
  max_temp_age: 24  # hours

logging:
  level: debug
  format: json
```

## Production Environment

### Docker Deployment

1. **Build production image**
   ```bash
   docker build -t ssulmeta-go:latest .
   ```

2. **Create production compose file** (`docker-compose.prod.yml`):
   ```yaml
   version: '3.8'
   
   services:
     app:
       image: ssulmeta-go:latest
       environment:
         - APP_ENV=prod
         - DATABASE_URL=${DATABASE_URL}
         - REDIS_URL=${REDIS_URL}
         - OPENAI_API_KEY=${OPENAI_API_KEY}
         - GOOGLE_APPLICATION_CREDENTIALS=/app/gcp-creds.json
       volumes:
         - ./gcp-creds.json:/app/gcp-creds.json:ro
         - ./storage:/app/storage
       ports:
         - "8080:8080"
       restart: unless-stopped
       depends_on:
         - postgres
         - redis
     
     postgres:
       image: postgres:15-alpine
       environment:
         - POSTGRES_DB=ssulmeta
         - POSTGRES_USER=ssulmeta
         - POSTGRES_PASSWORD=${DB_PASSWORD}
       volumes:
         - postgres_data:/var/lib/postgresql/data
       restart: unless-stopped
     
     redis:
       image: redis:7-alpine
       command: redis-server --requirepass ${REDIS_PASSWORD}
       volumes:
         - redis_data:/data
       restart: unless-stopped
   
   volumes:
     postgres_data:
     redis_data:
   ```

3. **Deploy**
   ```bash
   docker-compose -f docker-compose.prod.yml up -d
   ```

### Kubernetes Deployment

See `k8s/` directory for Kubernetes manifests:
- `deployment.yaml` - Application deployment
- `configmap.yaml` - Configuration
- `secret.yaml` - Sensitive data
- `service.yaml` - Service exposure
- `ingress.yaml` - External access

### Production Configuration

Create `configs/prod.yaml`:
```yaml
app:
  name: ssulmeta-go
  env: prod
  debug: false

database:
  host: ${DB_HOST}
  port: 5432
  user: ${DB_USER}
  password: ${DB_PASSWORD}
  dbname: ssulmeta
  sslmode: require
  max_connections: 100
  max_idle_connections: 10

redis:
  host: ${REDIS_HOST}
  port: 6379
  password: ${REDIS_PASSWORD}
  db: 0

server:
  host: 0.0.0.0
  port: 8080
  read_timeout: 30s
  write_timeout: 30s

api:
  use_mock: false
  rate_limit: 100
  
storage:
  base_path: /data/storage
  temp_path: /data/temp
  max_temp_age: 12

logging:
  level: info
  format: json
  output: stdout
```

## Environment Variables

### Required Variables

```bash
# Application
APP_ENV=local                    # Environment: test, local, dev, prod
APP_LOG_LEVEL=info              # Log level: debug, info, warn, error

# Database
DATABASE_URL=postgres://user:pass@host:5432/dbname
DB_HOST=localhost
DB_PORT=5432
DB_USER=ssulmeta
DB_PASSWORD=ssulmeta123!
DB_NAME=ssulmeta

# Redis
REDIS_URL=redis://localhost:6379
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=              # Optional
REDIS_DB=0

# OpenAI API
OPENAI_API_KEY=sk-...       # Your OpenAI API key
OPENAI_MODEL=gpt-4          # Model to use
OPENAI_MAX_TOKENS=500

# Google Cloud (for TTS)
GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
GCP_PROJECT_ID=your-project-id

# YouTube OAuth2
YOUTUBE_CLIENT_ID=your-client-id.apps.googleusercontent.com
YOUTUBE_CLIENT_SECRET=your-client-secret
YOUTUBE_REDIRECT_URL=http://localhost:8080/auth/youtube/callback

# Storage
STORAGE_PATH=/data/storage
TEMP_PATH=/data/temp
MAX_TEMP_AGE=24             # Hours

# Server
SERVER_PORT=8080
SERVER_HOST=0.0.0.0
READ_TIMEOUT=30s
WRITE_TIMEOUT=30s
```

### Optional Variables

```bash
# Monitoring
METRICS_ENABLED=true
METRICS_PORT=9090
TRACING_ENABLED=true
JAEGER_ENDPOINT=http://localhost:14268/api/traces

# Feature Flags
ENABLE_SCHEDULER=false
ENABLE_WEBHOOK=false
ENABLE_ANALYTICS=false

# Performance
MAX_CONCURRENT_JOBS=5
JOB_TIMEOUT=300            # Seconds
HTTP_CLIENT_TIMEOUT=30s
DB_CONNECTION_POOL_SIZE=25
REDIS_POOL_SIZE=10
```

## External Services Setup

### OpenAI API

1. **Get API Key**
   - Visit https://platform.openai.com/api-keys
   - Create new secret key
   - Add to `.env`: `OPENAI_API_KEY=sk-...`

2. **Configure Usage Limits**
   - Set monthly spending limit
   - Monitor usage dashboard

### Google Cloud TTS

1. **Create Project**
   ```bash
   gcloud projects create ssulmeta-youtube --name="SSulmeta YouTube"
   gcloud config set project ssulmeta-youtube
   ```

2. **Enable APIs**
   ```bash
   gcloud services enable texttospeech.googleapis.com
   ```

3. **Create Service Account**
   ```bash
   gcloud iam service-accounts create ssulmeta-tts \
     --display-name="SSulmeta TTS Service"
   
   gcloud projects add-iam-policy-binding ssulmeta-youtube \
     --member="serviceAccount:ssulmeta-tts@ssulmeta-youtube.iam.gserviceaccount.com" \
     --role="roles/cloudtts.client"
   ```

4. **Download Credentials**
   ```bash
   gcloud iam service-accounts keys create gcp-credentials.json \
     --iam-account=ssulmeta-tts@ssulmeta-youtube.iam.gserviceaccount.com
   ```

5. **Set Environment Variable**
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/gcp-credentials.json"
   ```

### YouTube API

1. **Enable YouTube Data API v3**
   - Go to https://console.cloud.google.com/apis/library
   - Search for "YouTube Data API v3"
   - Click Enable

2. **Create OAuth2 Credentials**
   - Go to APIs & Services → Credentials
   - Create Credentials → OAuth client ID
   - Application type: Web application
   - Add authorized redirect URI: `http://localhost:8080/auth/youtube/callback`

3. **Configure OAuth2**
   Create `configs/oauth.yaml`:
   ```yaml
   youtube:
     client_id: your-client-id.apps.googleusercontent.com
     client_secret: your-client-secret
     redirect_url: http://localhost:8080/auth/youtube/callback
     scopes:
       - https://www.googleapis.com/auth/youtube.upload
       - https://www.googleapis.com/auth/youtube
   ```

### Stable Diffusion API

1. **Option 1: Use Replicate**
   ```bash
   # Get API token from https://replicate.com/account
   export REPLICATE_API_TOKEN=r8_...
   ```

2. **Option 2: Self-hosted**
   ```bash
   # Run Stable Diffusion WebUI
   docker run -d \
     --gpus all \
     -p 7860:7860 \
     -v $(pwd)/models:/models \
     stability-ai/stable-diffusion
   ```

## Database Setup

### Initialize Database

```sql
-- Create database
CREATE DATABASE ssulmeta;

-- Create user
CREATE USER ssulmeta WITH ENCRYPTED PASSWORD 'ssulmeta123!';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ssulmeta TO ssulmeta;

-- Connect to database
\c ssulmeta

-- Create schema
CREATE SCHEMA IF NOT EXISTS public;
```

### Run Migrations

```bash
# Install migrate tool
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Run migrations
migrate -path ./internal/db/migrations \
  -database "postgresql://ssulmeta:ssulmeta123!@localhost:5432/ssulmeta?sslmode=disable" \
  up
```

## Monitoring Setup

### Prometheus

1. **Add metrics endpoint**
   ```go
   import "github.com/prometheus/client_golang/prometheus/promhttp"
   
   mux.Handle("/metrics", promhttp.Handler())
   ```

2. **Configure Prometheus** (`prometheus.yml`):
   ```yaml
   scrape_configs:
     - job_name: 'ssulmeta'
       static_configs:
         - targets: ['localhost:8080']
   ```

### Grafana Dashboard

Import dashboard from `monitoring/grafana-dashboard.json` for:
- Request rate and latency
- Error rates
- Video generation metrics
- External API usage

### Logging

1. **Structured Logging**
   ```go
   logger.Info("video generated",
     slog.String("channel", "fairy_tale"),
     slog.String("video_id", "abc123"),
     slog.Duration("duration", 45*time.Second),
   )
   ```

2. **Log Aggregation** (ELK Stack)
   ```yaml
   filebeat.inputs:
     - type: container
       paths:
         - /var/lib/docker/containers/*/*.log
       processors:
         - add_docker_metadata: ~
   ```

## Security Considerations

### API Keys

1. **Never commit API keys**
   ```bash
   # Add to .gitignore
   .env
   *.key
   *-credentials.json
   ```

2. **Use secret management**
   - Development: `.env` files
   - Production: Kubernetes Secrets, Vault, AWS Secrets Manager

### Network Security

1. **Firewall Rules**
   ```bash
   # Allow only necessary ports
   ufw allow 8080/tcp  # API
   ufw allow 5432/tcp  # PostgreSQL (only from app servers)
   ufw allow 6379/tcp  # Redis (only from app servers)
   ```

2. **TLS/SSL**
   - Use HTTPS in production
   - Configure TLS for PostgreSQL
   - Enable Redis AUTH

### Authentication

1. **API Authentication** (if needed)
   ```go
   middleware.APIKey("X-API-Key", validateAPIKey)
   ```

2. **OAuth2 for YouTube**
   - Store tokens encrypted
   - Implement token refresh
   - Use state parameter for CSRF protection

## Performance Tuning

### Database

```yaml
# PostgreSQL tuning
shared_buffers: 256MB
effective_cache_size: 1GB
maintenance_work_mem: 64MB
work_mem: 4MB
max_connections: 100
```

### Redis

```conf
# redis.conf
maxmemory 1gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
```

### Application

```yaml
# Concurrency settings
max_concurrent_jobs: 5
worker_pool_size: 10
http_client_timeout: 30s
db_connection_pool: 25
```

## Troubleshooting

### Common Issues

1. **"cannot connect to PostgreSQL"**
   ```bash
   # Check if PostgreSQL is running
   docker-compose ps
   
   # Check logs
   docker-compose logs postgres
   
   # Test connection
   psql -h localhost -U ssulmeta -d ssulmeta
   ```

2. **"Redis connection refused"**
   ```bash
   # Check Redis status
   redis-cli ping
   
   # Check Redis logs
   docker-compose logs redis
   ```

3. **"ffmpeg not found"**
   ```bash
   # Verify installation
   ffmpeg -version
   
   # Add to PATH if needed
   export PATH=$PATH:/usr/local/bin
   ```

4. **"Google credentials not found"**
   ```bash
   # Check file exists
   ls -la $GOOGLE_APPLICATION_CREDENTIALS
   
   # Verify JSON format
   jq . $GOOGLE_APPLICATION_CREDENTIALS
   ```

### Debug Mode

```bash
# Enable debug logging
APP_LOG_LEVEL=debug ./youtube-shorts-generator

# Enable Go debugging
GODEBUG=gctrace=1 ./youtube-shorts-generator

# Profile CPU usage
go tool pprof http://localhost:8080/debug/pprof/profile

# Profile memory
go tool pprof http://localhost:8080/debug/pprof/heap
```

### Health Checks

```bash
# Basic health check
curl http://localhost:8080/health

# Detailed health check
curl http://localhost:8080/health?detailed=true

# Check specific service
curl http://localhost:8080/health/redis
curl http://localhost:8080/health/postgres
```

## Backup and Recovery

### Database Backup

```bash
# Backup
pg_dump -h localhost -U ssulmeta -d ssulmeta > backup.sql

# Restore
psql -h localhost -U ssulmeta -d ssulmeta < backup.sql

# Automated backup script
0 2 * * * /usr/bin/pg_dump -h localhost -U ssulmeta -d ssulmeta | gzip > /backups/ssulmeta-$(date +\%Y\%m\%d).sql.gz
```

### Redis Backup

```bash
# Manual backup
redis-cli BGSAVE

# Check backup status
redis-cli LASTSAVE

# Backup location
ls -la /var/lib/redis/dump.rdb
```

## Maintenance

### Log Rotation

```yaml
# /etc/logrotate.d/ssulmeta
/var/log/ssulmeta/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 ssulmeta ssulmeta
}
```

### Cleanup Jobs

```bash
# Clean temporary files older than 24 hours
find ./temp -type f -mtime +1 -delete

# Clean old video files
find ./storage -name "*.mp4" -mtime +30 -delete

# Vacuum PostgreSQL
psql -U ssulmeta -c "VACUUM ANALYZE;"
```

### Updates

```bash
# Update dependencies
go get -u ./...
go mod tidy

# Update Docker images
docker-compose pull
docker-compose up -d

# Apply database migrations
make migrate-up
```