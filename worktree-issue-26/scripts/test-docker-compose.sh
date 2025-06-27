#!/bin/bash
# Test script for Docker Compose configuration

set -e

echo "Testing Docker Compose configuration..."

# Check if docker-compose.yml exists
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml not found"
    exit 1
fi

# Validate docker-compose.yml syntax
echo "Validating docker-compose.yml syntax..."
docker-compose config > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ docker-compose.yml syntax is valid"
else
    echo "❌ docker-compose.yml syntax is invalid"
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f "Dockerfile" ]; then
    echo "❌ Dockerfile not found"
    exit 1
else
    echo "✅ Dockerfile found"
fi

# Test Redis service configuration
echo "Checking Redis service configuration..."
if docker-compose config | grep -q "redis:7-alpine"; then
    echo "✅ Redis service configured correctly"
else
    echo "❌ Redis service not configured correctly"
    exit 1
fi

# Test app service configuration
echo "Checking app service configuration..."
if docker-compose config | grep -q "REDIS_URL"; then
    echo "✅ App service environment configured correctly"
else
    echo "❌ App service environment not configured correctly"
    exit 1
fi

echo "✅ All Docker Compose tests passed!"