#!/bin/bash

# Act Testing Helper Script
# This script provides convenient commands for testing the dotfiles CI locally with act

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    print_status "Checking Docker daemon..."
    if ! docker --context desktop-linux ps >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    fi
    print_success "Docker daemon is running"
}

# Check if act is installed
check_act() {
    print_status "Checking act installation..."
    if ! command -v act &> /dev/null; then
        print_error "act is not installed. Please install it first:"
        echo "  brew install act"
        exit 1
    fi
    print_success "act $(act --version) is installed"
}

# Validate environment for act execution
validate_environment() {
    print_status "Validating environment..."

    # Check disk space (need at least 5GB free) - cross-platform compatible
    local available_space
    if command -v df >/dev/null 2>&1; then
        # Try different df commands based on platform
        if df -BG . >/dev/null 2>&1; then
            # Linux/GNU df with -G flag
            available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
        else
            # macOS/BSD df - convert KB to GB
            available_space_kb=$(df -k . | awk 'NR==2 {print $4}')
            available_space=$((available_space_kb / 1024 / 1024))
        fi

        if [ "$available_space" -lt 5 ]; then
            print_error "Insufficient disk space. Need at least 5GB free, but only ${available_space}GB available."
            exit 1
        fi
        print_success "Disk space: ${available_space}GB available"
    else
        print_warning "Could not check disk space - df command not available"
    fi

    # Check Docker memory allocation (macOS specific)
    if command -v docker >/dev/null 2>&1; then
        local docker_memory
        docker_memory=$(docker system df --format "{{.Type}}: {{.Size}}" 2>/dev/null | head -1)
        print_status "Docker memory check: $docker_memory"
    fi

    # Check network connectivity
    if ! ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        print_warning "Network connectivity issues detected. Act may fail without internet access."
    else
        print_success "Network connectivity: OK"
    fi

    # Verify act configuration
    if [ ! -f ".actrc" ]; then
        print_warning "No .actrc configuration found in current directory"
    else
        print_success "Found .actrc configuration"
    fi

    # Check CI workflow file exists
    if [ ! -f ".github/workflows/ci.yml" ]; then
        print_error "CI workflow file not found: .github/workflows/ci.yml"
        exit 1
    fi
    print_success "CI workflow file found"
}

# Run act with proper environment
run_act() {
    local matrix_filter="$1"
    local description="$2"

    print_status "Running act: $description"
    print_status "Using DOCKER_HOST: ${DOCKER_HOST:-unix://${HOME}/.docker/run/docker.sock}"
    print_warning "Note: Git authentication errors are expected without proper GitHub tokens"
    print_warning "The important thing is that Docker, Node.js, and basic job execution work"

    # Set DOCKER_HOST to use Docker Desktop socket with environment variable fallback
    export DOCKER_HOST="${DOCKER_HOST:-unix://${HOME}/.docker/run/docker.sock}"

    # Display act configuration
    print_status "Using act configuration:"
    if [ -f ".actrc" ]; then
        cat .actrc | sed 's/^/  /'
    else
        print_warning "No .actrc file found"
    fi

    print_status "Starting act execution..."
    local start_time=$(date +%s)

    # Run act with proper error handling
    if [ -n "$matrix_filter" ]; then
        if ! act -j ci -s GITHUB_TOKEN=ghp_dummytoken --matrix "$matrix_filter" --workflows .github/workflows/ci.yml; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            print_error "Act execution failed for matrix filter: $matrix_filter (duration: ${duration}s)"
            exit 1
        fi
    else
        if ! act -j ci -s GITHUB_TOKEN=ghp_dummytoken --workflows .github/workflows/ci.yml; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            print_error "Act execution failed for all jobs (duration: ${duration}s)"
            exit 1
        fi
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    print_success "Act execution completed successfully (duration: ${duration}s)"
}

# Main script
main() {
    echo "🐳 Act Testing Helper for dotfiles CI"
    echo "======================================"

    case "${1:-help}" in
        "check")
            check_docker
            check_act
            validate_environment
            ;;
        "linux")
            check_docker
            check_act
            validate_environment
            run_act "name:Linux x64" "Linux x64 job only"
            ;;
        "linux-arm")
            check_docker
            check_act
            validate_environment
            run_act "name:Linux ARM" "Linux ARM job only"
            ;;
        "all")
            check_docker
            check_act
            validate_environment
            run_act "" "All CI jobs (Darwin will be skipped)"
            ;;
        "test")
            print_status "Running Node.js crypto.randomUUID test..."
            export DOCKER_HOST="${DOCKER_HOST:-unix://${HOME}/.docker/run/docker.sock}"

            # Create test workflow
            local test_workflow="/tmp/test-act.yml"
            echo 'name: Test
on: workflow_dispatch
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: |
          node -e "console.log(\"Node.js version:\", process.version)"
          node -e "console.log(\"crypto.randomUUID available:\", typeof crypto.randomUUID === \"function\")"
          node -e "console.log(\"crypto.randomUUID test:\", crypto.randomUUID())"' > "$test_workflow"

            # Run test with error handling
            if ! act -j test -s GITHUB_TOKEN=void --workflows "$test_workflow"; then
                print_error "Node.js test failed"
                rm -f "$test_workflow"
                exit 1
            fi

            rm -f "$test_workflow"
            print_success "Node.js test completed successfully"
            ;;
        "help"|*)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  check      - Check if Docker and act are properly configured"
            echo "  linux      - Run Linux x64 CI job only"
            echo "  linux-arm  - Run Linux ARM CI job only"
            echo "  all        - Run all CI jobs (Darwin will be skipped)"
            echo "  test       - Test Node.js crypto.randomUUID functionality"
            echo "  help       - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 check"
            echo "  $0 linux"
            echo "  $0 test"
            ;;
    esac
}

main "$@"
