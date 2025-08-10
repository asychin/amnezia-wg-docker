#!/bin/bash

# Repository Setup Script
# This script replaces template variables in documentation with actual repository information
# Making the project fork-friendly

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

# Get repository information
get_repo_info() {
    print_status "Detecting repository information..."
    
    # Get remote URL
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [[ -z "$REMOTE_URL" ]]; then
        print_error "No git remote found. Please run this script from a git repository."
        exit 1
    fi
    
    # Extract owner/repo from different URL formats
    if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
        GITHUB_OWNER="${BASH_REMATCH[1]}"
        REPO_NAME="${BASH_REMATCH[2]}"
    else
        print_error "Could not parse GitHub repository URL: $REMOTE_URL"
        exit 1
    fi
    
    GITHUB_REPOSITORY="${GITHUB_OWNER}/${REPO_NAME}"
    
    # Default Docker repository (can be overridden)
    DOCKER_REPOSITORY="${DOCKER_REPOSITORY:-${GITHUB_OWNER}/${REPO_NAME}}"
    
    # Default maintainer email (can be overridden)
    MAINTAINER_EMAIL="${MAINTAINER_EMAIL:-${GITHUB_OWNER}@users.noreply.github.com}"
    
    print_success "Repository detected: $GITHUB_REPOSITORY"
    print_status "Docker repository: $DOCKER_REPOSITORY"
    print_status "Maintainer email: $MAINTAINER_EMAIL"
}

# Replace variables in file
replace_variables() {
    local file="$1"
    local temp_file="${file}.tmp"
    
    print_status "Processing $file..."
    
    sed -e "s|{{GITHUB_REPOSITORY}}|${GITHUB_REPOSITORY}|g" \
        -e "s|{{GITHUB_OWNER}}|${GITHUB_OWNER}|g" \
        -e "s|{{REPO_NAME}}|${REPO_NAME}|g" \
        -e "s|{{DOCKER_REPOSITORY}}|${DOCKER_REPOSITORY}|g" \
        -e "s|{{MAINTAINER_EMAIL}}|${MAINTAINER_EMAIL}|g" \
        -e "s|asychin/amneziawg-docker|${DOCKER_REPOSITORY}|g" \
        -e "s|ghcr\.io/asychin/amneziawg-docker|ghcr.io/${DOCKER_REPOSITORY}|g" \
        -e "s|https://github\.com/asychin/amneziawg-docker|https://github.com/${GITHUB_REPOSITORY}|g" \
        "$file" > "$temp_file"
    
    mv "$temp_file" "$file"
}

# Main execution
main() {
    print_status "Starting repository setup..."
    
    # Get repository information
    get_repo_info
    
    # List of files to process
    FILES_TO_PROCESS=(
        "README.md"
        "docs/en/README.md"
        "docs/ru/README.md"
        "docs/zh/README.md"
        "docs/en/pipeline.md"
        "docs/ru/pipeline.md"
        "docs/zh/pipeline.md"
        "docs/en/fork-setup.md"
    )
    
    # Process each file
    for file in "${FILES_TO_PROCESS[@]}"; do
        if [[ -f "$file" ]]; then
            replace_variables "$file"
            print_success "Updated $file"
        else
            print_warning "File not found: $file"
        fi
    done
    
    print_success "Repository setup completed!"
    print_status "All documentation files have been updated with your repository information."
}

# Check if script is being run from project root
if [[ ! -f "README.md" ]] || [[ ! -d ".git" ]]; then
    print_error "Please run this script from the project root directory."
    exit 1
fi

# Run main function
main "$@"