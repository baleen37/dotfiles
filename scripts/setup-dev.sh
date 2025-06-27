#!/bin/bash

set -e

echo "🚀 Setting up development environment for ssulmeta-go..."
echo ""

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Error: Go is not installed"
    echo "Please install Go from https://golang.org/dl/"
    exit 1
fi

echo "✅ Go is installed: $(go version)"
echo ""

# Run make setup-dev
echo "📦 Installing development tools and setting up git hooks..."
make setup-dev

echo ""
echo "🎉 Development environment setup complete!"
echo ""
echo "📋 Quick start guide:"
echo "   1. Set environment variables:"
echo "      export OPENAI_API_KEY=your-api-key"
echo ""
echo "   2. Start local services:"
echo "      docker-compose up -d"
echo ""
echo "   3. Run the application:"
echo "      make dev"
echo ""
echo "   4. Run tests:"
echo "      make test"
echo ""
echo "Happy coding! 🚀"