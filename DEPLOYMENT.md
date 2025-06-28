# Deployment Guide

This guide covers deployment strategies and procedures for the ssulmeta-go YouTube Shorts generation system.

## Table of Contents

- [Deployment Overview](#deployment-overview)
- [Docker Deployment](#docker-deployment)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Cloud Deployments](#cloud-deployments)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Alerting](#monitoring--alerting)
- [Scaling Strategies](#scaling-strategies)
- [Disaster Recovery](#disaster-recovery)

## Deployment Overview

### Architecture Components

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Load Balancer │────▶│   Application   │────▶│    PostgreSQL   │
└─────────────────┘     │     Servers     │     └─────────────────┘
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐     ┌─────────────────┐
                        │      Redis      │     │   Object Store  │
                        └─────────────────┘     │   (Videos/Images)│
                                                └─────────────────┘
```

### Deployment Checklist

- [ ] Environment variables configured
- [ ] Database migrations completed
- [ ] Redis cache warmed up
- [ ] SSL certificates installed
- [ ] Monitoring configured
- [ ] Backup strategy implemented
- [ ] Load testing completed
- [ ] Rollback plan documented

## Docker Deployment

### Single Host Deployment

1. **Build Production Image**

```dockerfile
# Dockerfile.production
FROM golang:1.24-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o youtube-shorts-generator ./cmd/cli

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates ffmpeg
WORKDIR /root/

COPY --from=builder /app/youtube-shorts-generator .
COPY --from=builder /app/configs ./configs

EXPOSE 8080
CMD ["./youtube-shorts-generator"]
```

2. **Docker Compose Production**

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.production
    image: ssulmeta-go:latest
    container_name: ssulmeta-app
    environment:
      - APP_ENV=prod
      - DATABASE_URL=postgres://ssulmeta:${DB_PASSWORD}@postgres:5432/ssulmeta?sslmode=require
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
    env_file:
      - .env.production
    volumes:
      - ./storage:/app/storage
      - ./logs:/app/logs
      - ./gcp-credentials.json:/app/gcp-credentials.json:ro
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:15-alpine
    container_name: ssulmeta-postgres
    environment:
      - POSTGRES_DB=ssulmeta
      - POSTGRES_USER=ssulmeta
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_INITDB_ARGS=--encoding=UTF8
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql:ro
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ssulmeta"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: ssulmeta-redis
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD}
      --maxmemory 1gb
      --maxmemory-policy allkeys-lru
      --save 900 1
      --save 300 10
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "--pass", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  nginx:
    image: nginx:alpine
    container_name: ssulmeta-nginx
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - app
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

3. **Deploy**

```bash
# Load environment variables
export $(cat .env.production | xargs)

# Deploy
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f app
```

### Docker Swarm Deployment

```bash
# Initialize swarm
docker swarm init

# Create secrets
echo "your-db-password" | docker secret create db_password -
echo "your-redis-password" | docker secret create redis_password -

# Deploy stack
docker stack deploy -c docker-stack.yml ssulmeta

# Scale service
docker service scale ssulmeta_app=3
```

## Kubernetes Deployment

### Kubernetes Manifests

1. **Namespace**

```yaml
# k8s/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: ssulmeta
```

2. **ConfigMap**

```yaml
# k8s/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ssulmeta-config
  namespace: ssulmeta
data:
  APP_ENV: "prod"
  SERVER_PORT: "8080"
  LOG_LEVEL: "info"
```

3. **Secret**

```yaml
# k8s/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ssulmeta-secrets
  namespace: ssulmeta
type: Opaque
stringData:
  database-url: "postgres://user:pass@postgres:5432/ssulmeta?sslmode=require"
  redis-url: "redis://:password@redis:6379/0"
  openai-api-key: "sk-..."
  gcp-credentials: |
    {
      "type": "service_account",
      "project_id": "...",
      ...
    }
```

4. **Deployment**

```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ssulmeta-app
  namespace: ssulmeta
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ssulmeta
  template:
    metadata:
      labels:
        app: ssulmeta
    spec:
      containers:
      - name: ssulmeta
        image: your-registry/ssulmeta-go:latest
        ports:
        - containerPort: 8080
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: ssulmeta-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: ssulmeta-secrets
              key: redis-url
        - name: OPENAI_API_KEY
          valueFrom:
            secretKeyRef:
              name: ssulmeta-secrets
              key: openai-api-key
        - name: GOOGLE_APPLICATION_CREDENTIALS
          value: /app/gcp-credentials.json
        envFrom:
        - configMapRef:
            name: ssulmeta-config
        volumeMounts:
        - name: gcp-credentials
          mountPath: /app/gcp-credentials.json
          subPath: gcp-credentials.json
          readOnly: true
        - name: storage
          mountPath: /app/storage
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
      volumes:
      - name: gcp-credentials
        secret:
          secretName: ssulmeta-secrets
          items:
          - key: gcp-credentials
            path: gcp-credentials.json
      - name: storage
        persistentVolumeClaim:
          claimName: ssulmeta-storage-pvc
```

5. **Service**

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: ssulmeta-service
  namespace: ssulmeta
spec:
  selector:
    app: ssulmeta
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
  type: LoadBalancer
```

6. **Ingress**

```yaml
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ssulmeta-ingress
  namespace: ssulmeta
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
  - hosts:
    - api.ssulmeta.com
    secretName: ssulmeta-tls
  rules:
  - host: api.ssulmeta.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ssulmeta-service
            port:
              number: 80
```

### Helm Chart

```yaml
# helm/ssulmeta/values.yaml
replicaCount: 3

image:
  repository: your-registry/ssulmeta-go
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: api.ssulmeta.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: ssulmeta-tls
      hosts:
        - api.ssulmeta.com

resources:
  limits:
    cpu: 2000m
    memory: 2Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
  targetMemoryUtilizationPercentage: 80

postgresql:
  enabled: true
  auth:
    database: ssulmeta
    username: ssulmeta
  persistence:
    enabled: true
    size: 10Gi

redis:
  enabled: true
  auth:
    enabled: true
  persistence:
    enabled: true
    size: 1Gi
```

Deploy with Helm:

```bash
# Add repositories
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install
helm install ssulmeta ./helm/ssulmeta \
  --namespace ssulmeta \
  --create-namespace \
  --values ./helm/ssulmeta/values.prod.yaml

# Upgrade
helm upgrade ssulmeta ./helm/ssulmeta \
  --namespace ssulmeta \
  --values ./helm/ssulmeta/values.prod.yaml
```

## Cloud Deployments

### AWS Deployment

1. **ECS with Fargate**

```json
// task-definition.json
{
  "family": "ssulmeta",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "containerDefinitions": [
    {
      "name": "ssulmeta-app",
      "image": "your-ecr-repo/ssulmeta-go:latest",
      "portMappings": [
        {
          "containerPort": 8080,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "APP_ENV",
          "value": "prod"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:ssulmeta/db"
        },
        {
          "name": "OPENAI_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:region:account:secret:ssulmeta/openai"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/ssulmeta",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

2. **Terraform Configuration**

```hcl
# terraform/main.tf
provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name   = "ssulmeta-vpc"
  cidr   = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = true
}

resource "aws_ecs_cluster" "main" {
  name = "ssulmeta-cluster"
}

resource "aws_ecs_service" "app" {
  name            = "ssulmeta-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 3
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "ssulmeta-app"
    container_port   = 8080
  }
}
```

### Google Cloud Platform

```yaml
# app.yaml (App Engine)
runtime: go124
env: standard

instance_class: F4
automatic_scaling:
  min_instances: 2
  max_instances: 10
  target_cpu_utilization: 0.8

env_variables:
  APP_ENV: "prod"

vpc_access_connector:
  name: projects/PROJECT_ID/locations/REGION/connectors/vpc-connector

handlers:
- url: /.*
  script: auto
  secure: always
```

### Azure Container Instances

```bash
# Deploy to Azure
az container create \
  --resource-group ssulmeta-rg \
  --name ssulmeta-app \
  --image your-acr.azurecr.io/ssulmeta-go:latest \
  --cpu 2 \
  --memory 4 \
  --port 8080 \
  --environment-variables APP_ENV=prod \
  --secure-environment-variables DATABASE_URL=$DATABASE_URL
```

## CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.24'
    
    - name: Run tests
      run: |
        make test
        make arch-test

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
    - uses: actions/checkout@v3
    
    - name: Log in to Container Registry
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        file: ./Dockerfile.production
        push: true
        tags: |
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
    - name: Deploy to Kubernetes
      uses: azure/k8s-deploy@v4
      with:
        manifests: |
          k8s/deployment.yaml
          k8s/service.yaml
        images: |
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        kubeconfig: ${{ secrets.KUBE_CONFIG }}
```

### GitLab CI/CD

```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

test:
  stage: test
  image: golang:1.24
  script:
    - make test
    - make lint
    - make arch-test
  coverage: '/total:\s+\(statements\)\s+(\d+.\d+)%/'

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main

deploy:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl set image deployment/ssulmeta-app ssulmeta=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - kubectl rollout status deployment/ssulmeta-app
  environment:
    name: production
    url: https://api.ssulmeta.com
  only:
    - main
```

## Monitoring & Alerting

### Prometheus Configuration

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

rule_files:
  - "alerts.yml"

scrape_configs:
  - job_name: 'ssulmeta'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_app]
        action: keep
        regex: ssulmeta
```

### Alert Rules

```yaml
# alerts.yml
groups:
  - name: ssulmeta
    rules:
    - alert: HighErrorRate
      expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: High error rate detected
        
    - alert: HighLatency
      expr: histogram_quantile(0.95, http_request_duration_seconds_bucket) > 1
      for: 10m
      labels:
        severity: warning
        
    - alert: PodDown
      expr: up{job="ssulmeta"} == 0
      for: 1m
      labels:
        severity: critical
        
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.9
      for: 5m
      labels:
        severity: warning
```

### Grafana Dashboard

```json
{
  "dashboard": {
    "title": "SSulmeta Monitoring",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total[5m])"
          }
        ]
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{status=~\"5..\"}[5m])"
          }
        ]
      },
      {
        "title": "Response Time",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, http_request_duration_seconds_bucket)"
          }
        ]
      },
      {
        "title": "Video Generation Rate",
        "targets": [
          {
            "expr": "rate(videos_generated_total[1h])"
          }
        ]
      }
    ]
  }
}
```

## Scaling Strategies

### Horizontal Pod Autoscaling

```yaml
# k8s/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ssulmeta-hpa
  namespace: ssulmeta
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ssulmeta-app
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
```

### Database Scaling

```sql
-- Read replica configuration
CREATE PUBLICATION ssulmeta_pub FOR ALL TABLES;

-- On replica
CREATE SUBSCRIPTION ssulmeta_sub
  CONNECTION 'host=primary-db port=5432 dbname=ssulmeta'
  PUBLICATION ssulmeta_pub;
```

### Redis Clustering

```bash
# Create Redis cluster
redis-cli --cluster create \
  redis-1:6379 redis-2:6379 redis-3:6379 \
  redis-4:6379 redis-5:6379 redis-6:6379 \
  --cluster-replicas 1
```

## Disaster Recovery

### Backup Strategy

1. **Database Backups**

```bash
#!/bin/bash
# backup.sh
BACKUP_DIR="/backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="ssulmeta"

# Create backup
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME | gzip > $BACKUP_DIR/backup_$TIMESTAMP.sql.gz

# Upload to S3
aws s3 cp $BACKUP_DIR/backup_$TIMESTAMP.sql.gz s3://ssulmeta-backups/postgres/

# Cleanup old local backups (keep 7 days)
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete
```

2. **Application State Backup**

```yaml
# k8s/cronjob-backup.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
  namespace: ssulmeta
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: your-registry/backup-tool:latest
            command:
            - /bin/sh
            - -c
            - |
              # Backup database
              pg_dump $DATABASE_URL > /backup/db.sql
              # Backup Redis
              redis-cli --rdb /backup/redis.rdb
              # Backup files
              tar -czf /backup/storage.tar.gz /app/storage
              # Upload to S3
              aws s3 sync /backup s3://ssulmeta-backups/$(date +%Y%m%d)/
          restartPolicy: OnFailure
```

### Recovery Procedures

1. **Database Recovery**

```bash
# Download latest backup
aws s3 cp s3://ssulmeta-backups/postgres/latest.sql.gz .

# Restore database
gunzip -c latest.sql.gz | psql -h $DB_HOST -U $DB_USER -d $DB_NAME
```

2. **Application Recovery**

```bash
# Rollback deployment
kubectl rollout undo deployment/ssulmeta-app

# Or specific revision
kubectl rollout undo deployment/ssulmeta-app --to-revision=2
```

### Blue-Green Deployment

```bash
# Deploy green environment
kubectl apply -f k8s/deployment-green.yaml

# Test green environment
curl https://green.ssulmeta.com/health

# Switch traffic
kubectl patch service ssulmeta-service -p '{"spec":{"selector":{"version":"green"}}}'

# Remove blue environment
kubectl delete -f k8s/deployment-blue.yaml
```

## Security Hardening

### Network Policies

```yaml
# k8s/network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ssulmeta-netpol
  namespace: ssulmeta
spec:
  podSelector:
    matchLabels:
      app: ssulmeta
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: ssulmeta
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 5432  # PostgreSQL
    - protocol: TCP
      port: 6379  # Redis
    - protocol: TCP
      port: 443   # HTTPS (external APIs)
```

### Pod Security Policy

```yaml
# k8s/pod-security-policy.yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: ssulmeta-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

## Performance Optimization

### Caching Strategy

```yaml
# Redis caching configuration
redis:
  cache_ttl:
    channels: 300        # 5 minutes
    stories: 3600       # 1 hour
    metadata: 86400     # 24 hours
  max_memory: 2gb
  eviction_policy: allkeys-lru
```

### CDN Configuration

```nginx
# nginx.conf for CDN
location /static/ {
    proxy_cache_valid 200 30d;
    proxy_cache_valid 404 1m;
    add_header X-Cache-Status $upstream_cache_status;
    add_header Cache-Control "public, max-age=2592000";
}

location /videos/ {
    proxy_cache_valid 200 7d;
    add_header Cache-Control "public, max-age=604800";
    
    # Video streaming optimizations
    mp4;
    mp4_buffer_size 1m;
    mp4_max_buffer_size 5m;
}
```

## Maintenance Windows

### Rolling Updates

```bash
# Update with zero downtime
kubectl set image deployment/ssulmeta-app \
  ssulmeta=your-registry/ssulmeta-go:v2.0.0 \
  --record

# Monitor rollout
kubectl rollout status deployment/ssulmeta-app

# Pause if issues detected
kubectl rollout pause deployment/ssulmeta-app

# Resume after fixes
kubectl rollout resume deployment/ssulmeta-app
```

### Database Maintenance

```sql
-- Maintenance script
-- Run during low traffic
VACUUM ANALYZE;
REINDEX DATABASE ssulmeta;

-- Update statistics
ANALYZE;
```

## Cost Optimization

### Resource Limits

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "2000m"
```

### Spot Instances

```yaml
# EKS node group with spot instances
nodeGroups:
  - name: spot-node-group
    instanceTypes:
      - t3.medium
      - t3a.medium
    spot: true
    minSize: 2
    maxSize: 10
    desiredCapacity: 3
```

### Scheduled Scaling

```yaml
# k8s/scheduled-scaler.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scale-down
spec:
  schedule: "0 22 * * *"  # 10 PM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: kubectl
            image: bitnami/kubectl
            command:
            - kubectl
            - scale
            - deployment/ssulmeta-app
            - --replicas=2
```