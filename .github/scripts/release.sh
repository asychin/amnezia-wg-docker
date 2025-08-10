#!/bin/bash
# 🚀 Release script for AmneziaWG Docker Server
# Supports semantic versioning and automated releases

set -euo pipefail

# ============================================================================
# VARIABLES AND SETTINGS
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
VERSION_FILE="${PROJECT_ROOT}/VERSION"
CHANGELOG_FILE="${PROJECT_ROOT}/CHANGELOG.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

prompt() {
    echo -e "${CYAN}❓ $1${NC}"
}

# Check dependencies
check_dependencies() {
    local deps=("git" "docker" "jq")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Dependency '$dep' not found. Please install it before continuing."
        fi
    done
    
    # Check Git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Script must be run inside a Git repository"
    fi
    
    success "All dependencies checked"
}

# Get current version
get_current_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE"
    else
        # Try to get latest tag
        git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0"
    fi
}

# Validate semantic version
validate_version() {
    local version="$1"
    
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)*)?$ ]]; then
        error "Invalid version format: $version. Use semantic versioning (e.g., 1.0.0, 1.0.0-beta)"
    fi
}

# Increment version
increment_version() {
    local version="$1"
    local type="$2"
    
    # Remove v prefix if present
    version="${version#v}"
    
    # Parse version components
    local major minor patch prerelease
    if [[ "$version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(-.*)?$ ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"
        prerelease="${BASH_REMATCH[4]}"
    else
        error "Cannot parse version: $version"
    fi
    
    case "$type" in
        "patch")
            ((patch++))
            prerelease=""
            ;;
        "minor")
            ((minor++))
            patch=0
            prerelease=""
            ;;
        "major")
            ((major++))
            minor=0
            patch=0
            prerelease=""
            ;;
        "prerelease")
            if [[ -z "$prerelease" ]]; then
                prerelease="-rc.1"
            else
                # Increment prerelease number
                if [[ "$prerelease" =~ ^-(.+)\.([0-9]+)$ ]]; then
                    local pre_type="${BASH_REMATCH[1]}"
                    local pre_num="${BASH_REMATCH[2]}"
                    ((pre_num++))
                    prerelease="-${pre_type}.${pre_num}"
                else
                    prerelease="${prerelease}.1"
                fi
            fi
            ;;
        *)
            error "Unknown version type: $type"
            ;;
    esac
    
    echo "${major}.${minor}.${patch}${prerelease}"
}

# Generate changelog
generate_changelog() {
    local new_version="$1"
    local previous_tag="$2"
    
    log "Generating changelog for version $new_version..."
    
    # Get commit list
    local commits
    if [[ -n "$previous_tag" ]]; then
        commits=$(git log "${previous_tag}..HEAD" --pretty=format:"- %s (%h)" --no-merges)
    else
        commits=$(git log --pretty=format:"- %s (%h)" --no-merges)
    fi
    
    # Create changelog
    cat << EOF
## [${new_version}] - $(date +%Y-%m-%d)

### 🔄 Changes
$commits

### 🐳 Docker Images
- \`docker.io/${IMAGE_NAME:-asychin/amnezia-wg-docker}:${new_version}\`
- \`ghcr.io/${IMAGE_NAME:-asychin/amnezia-wg-docker}:${new_version}\`

EOF
}

# Update VERSION file
update_version_file() {
    local version="$1"
    echo "$version" > "$VERSION_FILE"
    success "VERSION file updated: $version"
}

# Create and push tag
create_and_push_tag() {
    local version="$1"
    local tag="v${version}"
    
    log "Creating tag $tag..."
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        error "There are uncommitted changes. Please commit them before creating a release."
    fi
    
    # Create commit with version update
    git add "$VERSION_FILE"
    git commit -m "🔖 Version $version" || true
    
    # Create tag
    git tag -a "$tag" -m "🚀 Release $version"
    
    # Push to repository
    prompt "Push tag $tag to remote repository? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        git push origin HEAD
        git push origin "$tag"
        success "Tag $tag pushed to repository"
    else
        warning "Tag created locally. Don't forget to push it with: git push origin $tag"
    fi
}

# Test build
test_build() {
    log "Testing Docker image build..."
    
    cd "$PROJECT_ROOT"
    
    # Update submodules
    git submodule update --init --recursive
    
    # Test build
    docker build -t amneziawg-release-test . || error "Error building Docker image"
    
    # Quick test
    docker run --rm amneziawg-release-test amneziawg-go --version || error "Error testing image"
    
    # Remove test image
    docker rmi amneziawg-release-test
    
    success "Build test completed successfully"
}

# ============================================================================
# MAIN LOGIC
# ============================================================================

show_help() {
    cat << EOF
🚀 Release script for AmneziaWG Docker Server

USAGE:
    $0 [OPTIONS] [VERSION_TYPE|VERSION]

ARGUMENTS:
    VERSION_TYPE    Type of version increment: patch, minor, major, prerelease
    VERSION         Specific version (e.g., 1.0.0, 1.0.0-beta)

OPTIONS:
    -h, --help      Show this help
    -c, --current   Show current version
    -t, --test      Test build only
    -n, --dry-run   Dry run (no tag creation)

EXAMPLES:
    $0 patch                    # Increment patch version (1.0.0 → 1.0.1)
    $0 minor                    # Increment minor version (1.0.0 → 1.1.0)
    $0 major                    # Increment major version (1.0.0 → 2.0.0)
    $0 prerelease              # Create prerelease (1.0.0 → 1.0.1-rc.1)
    $0 1.2.3                   # Set specific version
    $0 1.2.3-beta              # Set prerelease version
    $0 --current               # Show current version
    $0 --test                  # Test build only

EOF
}

main() {
    local dry_run=false
    local test_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--current)
                echo "Current version: $(get_current_version)"
                exit 0
                ;;
            -t|--test)
                test_only=true
                shift
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Check dependencies
    check_dependencies
    
    # If test only
    if [[ "$test_only" == true ]]; then
        test_build
        exit 0
    fi
    
    # Get current version
    local current_version
    current_version=$(get_current_version)
    log "Current version: $current_version"
    
    # Determine new version
    local new_version
    if [[ $# -eq 0 ]]; then
        error "No version type or specific version provided. Use --help for usage."
    elif [[ "$1" =~ ^(patch|minor|major|prerelease)$ ]]; then
        new_version=$(increment_version "$current_version" "$1")
    else
        new_version="$1"
        validate_version "$new_version"
    fi
    
    # Remove v prefix if present
    new_version="${new_version#v}"
    
    log "New version: $new_version"
    
    # Get previous tag for changelog
    local previous_tag
    previous_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    # Generate changelog
    local changelog
    changelog=$(generate_changelog "$new_version" "$previous_tag")
    
    echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                        RELEASE PLAN                         ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}📋 Current version:${NC} $current_version"
    echo -e "${CYAN}🚀 New version:${NC} $new_version"
    echo -e "${CYAN}🏷️ Tag:${NC} v$new_version"
    echo -e "${CYAN}📝 Changelog:${NC}"
    echo "$changelog"
    
    if [[ "$dry_run" == true ]]; then
        warning "Dry run - no changes will be applied"
        exit 0
    fi
    
    # Confirmation
    prompt "Continue with release creation? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        warning "Release cancelled"
        exit 0
    fi
    
    # Test build
    test_build
    
    # Update VERSION file
    update_version_file "$new_version"
    
    # Create and push tag
    create_and_push_tag "$new_version"
    
    echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                     RELEASE COMPLETED!                      ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${CYAN}🏷️ Version:${NC} $new_version"
    echo -e "${CYAN}🐳 Images will be available after GitHub Actions completes:${NC}"
    echo -e "   • docker.io/${IMAGE_NAME:-asychin/amnezia-wg-docker}:$new_version"
    echo -e "   • ghcr.io/${IMAGE_NAME:-asychin/amnezia-wg-docker}:$new_version"
    echo -e "${CYAN}🔗 Track progress:${NC} https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[\/:]//; s/.git$//')/actions"
}

# Run main function
main "$@"