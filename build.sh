#!/bin/bash
# GitUpdateProject - Local Build Script
# This script mimics the GitHub Actions build process for local development

set -e

# Configuration
PROJECT_NAME="GitUpdateProject"
BUILD_DIR="build"
DIST_DIR="dist"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[BUILD]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check dependencies
check_dependencies() {
    print_status "Checking dependencies..."
    
    local missing_deps=0
    
    for cmd in zip tar git rsync; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd is not installed"
            missing_deps=1
        fi
    done
    
    if [ $missing_deps -eq 1 ]; then
        print_error "Please install missing dependencies and try again"
        exit 1
    fi
    
    print_info "All dependencies satisfied"
}

# Function to get version information
get_version_info() {
    print_status "Getting version information..."
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Get version from git tag or generate from commit
    if git describe --tags --exact-match HEAD 2>/dev/null; then
        VERSION=$(git describe --tags --exact-match HEAD)
    else
        VERSION="dev-$(git rev-parse --short HEAD)"
    fi
    
    BUILD_DATE=$(date -u +%Y-%m-%d)
    BUILD_TIME=$(date -u +%H:%M:%S)
    COMMIT_SHA=$(git rev-parse HEAD)
    BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
    
    print_info "Version: $VERSION"
    print_info "Build Date: $BUILD_DATE"
    print_info "Branch: $BRANCH_NAME"
}

# Function to clean previous builds
clean_build() {
    print_status "Cleaning previous builds..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_info "Removed $BUILD_DIR directory"
    fi
    
    if [ -d "$DIST_DIR" ]; then
        rm -rf "$DIST_DIR"
        print_info "Removed $DIST_DIR directory"
    fi
}

# Function to prepare source files
prepare_sources() {
    print_status "Preparing source files..."
    
    # Create directories
    mkdir -p "$BUILD_DIR/$PROJECT_NAME"
    mkdir -p "$DIST_DIR"
    
    # Copy all project files (excluding build and dist directories)
    print_info "Copying project files..."
    
    # Use tar with inline excludes to copy files safely
    tar --exclude="$BUILD_DIR" --exclude="$DIST_DIR" --exclude=".git" \
        --exclude="*.log" --exclude="REFACTORING_REPORT.md" \
        -cf - . | (cd "$BUILD_DIR/$PROJECT_NAME" && tar -xf -)
    
    # Remove additional development files from the build
    cd "$BUILD_DIR/$PROJECT_NAME"
    print_info "Removing development files..."
    
    rm -rf .github/workflows/ 2>/dev/null || true
    rm -f .gitignore 2>/dev/null || true
    rm -f -- *.log 2>/dev/null || true
    rm -f REFACTORING_REPORT.md 2>/dev/null || true
    
    cd "$SCRIPT_DIR"
    
    print_info "Source files prepared"
}

# Function to create version info
create_version_info() {
    print_status "Creating version information file..."
    
    cat > "$BUILD_DIR/$PROJECT_NAME/VERSION.txt" << EOF
GitUpdateProject Release Information
=====================================

Version: $VERSION
Build Date: $BUILD_DATE
Build Time: $BUILD_TIME
Commit SHA: $COMMIT_SHA
Branch: $BRANCH_NAME
Built on: Local Build System

Project Description:
Automated Git repository update system with integrated security pipeline.
Supports batch updating of multiple repositories with comprehensive logging,
progress tracking, and security vulnerability scanning.

Components:
- Core update scripts (updateGit.sh, updateGit_v2.sh)
- Modular library system (lib/)
- Security tools integration (Gitleaks, Semgrep, ShellCheck)
- Pre-commit hooks and CI/CD pipeline
- Cross-platform compatibility (Linux, macOS)

For installation and usage instructions, see README.md
EOF

    print_info "Version info created"
}

# Function to create distribution packages
create_packages() {
    print_status "Creating distribution packages..."
    
    cd "$BUILD_DIR"
    
    # Create ZIP archive
    print_info "Creating ZIP archive..."
    zip -r "../$DIST_DIR/$PROJECT_NAME-$VERSION.zip" "$PROJECT_NAME/" > /dev/null
    
    # Create TAR.GZ archive
    print_info "Creating TAR.GZ archive..."
    tar -czf "../$DIST_DIR/$PROJECT_NAME-$VERSION.tar.gz" "$PROJECT_NAME/"
    
    # Create TAR.XZ archive (better compression)
    print_info "Creating TAR.XZ archive..."
    tar -cJf "../$DIST_DIR/$PROJECT_NAME-$VERSION.tar.xz" "$PROJECT_NAME/"
    
    cd "$SCRIPT_DIR"
    
    print_info "Distribution packages created"
}

# Function to create checksums
create_checksums() {
    print_status "Creating checksums..."
    
    cd "$DIST_DIR"
    
    # Generate SHA256 checksums
    sha256sum ./*.zip ./*.tar.gz ./*.tar.xz > checksums.sha256
    
    # Generate MD5 checksums
    md5sum ./*.zip ./*.tar.gz ./*.tar.xz > checksums.md5
    
    cd "$SCRIPT_DIR"
    
    print_info "Checksums created"
}

# Function to create installation script
create_install_script() {
    print_status "Creating installation script..."
    
    cat > "$DIST_DIR/install.sh" << 'EOF'
#!/bin/bash
# GitUpdateProject - Quick Installation Script

set -e

PROJECT_NAME="GitUpdateProject"
INSTALL_DIR="/opt/$PROJECT_NAME"
BIN_DIR="/usr/local/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 GitUpdateProject Installation Script${NC}"
echo "=================================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${YELLOW}⚠️  Running as root - installation will be system-wide${NC}"
   SUDO=""
else
   echo -e "${YELLOW}🔒 Will use sudo for system installation${NC}"
   SUDO="sudo"
fi

# Detect archive type
if [ -f "$PROJECT_NAME"*.tar.gz ]; then
    ARCHIVE=$(ls $PROJECT_NAME*.tar.gz | head -1)
    EXTRACT_CMD="tar -xzf"
elif [ -f "$PROJECT_NAME"*.tar.xz ]; then
    ARCHIVE=$(ls $PROJECT_NAME*.tar.xz | head -1)
    EXTRACT_CMD="tar -xJf"
elif [ -f "$PROJECT_NAME"*.zip ]; then
    ARCHIVE=$(ls $PROJECT_NAME*.zip | head -1)
    EXTRACT_CMD="unzip"
else
    echo -e "${RED}❌ No suitable archive found!${NC}"
    exit 1
fi

echo -e "${GREEN}📦 Found archive: $ARCHIVE${NC}"

# Extract archive
echo -e "${GREEN}📂 Extracting archive...${NC}"
$EXTRACT_CMD "$ARCHIVE" > /dev/null

# Install
echo -e "${GREEN}📁 Installing to $INSTALL_DIR...${NC}"
$SUDO mkdir -p "$INSTALL_DIR"
$SUDO cp -r $PROJECT_NAME/* "$INSTALL_DIR/"
$SUDO chmod +x "$INSTALL_DIR"/*.sh
$SUDO chmod +x "$INSTALL_DIR"/lib/*.sh

# Create symlinks
echo -e "${GREEN}🔗 Creating system links...${NC}"
$SUDO ln -sf "$INSTALL_DIR/updateGit_v2.sh" "$BIN_DIR/updateGit"
$SUDO ln -sf "$INSTALL_DIR/install.sh" "$BIN_DIR/gitupdate-install"

echo -e "${GREEN}✅ Installation completed successfully!${NC}"
echo ""
echo -e "${YELLOW}📋 Usage:${NC}"
echo "  updateGit [directory]     - Update repositories in directory"
echo "  gitupdate-install         - Run full installation"
echo ""
echo -e "${YELLOW}📁 Installed to:${NC} $INSTALL_DIR"
echo -e "${YELLOW}🔗 Available commands:${NC} updateGit, gitupdate-install"
EOF

    chmod +x "$DIST_DIR/install.sh"
    
    print_info "Installation script created"
}

# Function to show build summary
show_summary() {
    print_status "Build Summary"
    echo ""
    print_info "Version: $VERSION"
    print_info "Build Date: $BUILD_DATE $BUILD_TIME"
    print_info "Commit: $COMMIT_SHA"
    print_info "Branch: $BRANCH_NAME"
    echo ""
    print_info "Generated files:"
    ls -la "$DIST_DIR"
    echo ""
    
    # Show file sizes
    print_info "Archive sizes:"
    du -h "$DIST_DIR"/*.zip "$DIST_DIR"/*.tar.* | sort -h
    echo ""
    
    print_status "Build completed successfully! 🎉"
    echo ""
    print_info "To test installation locally:"
    echo "  cd $DIST_DIR && ./install.sh"
    echo ""
    print_info "To verify checksums:"
    echo "  cd $DIST_DIR && sha256sum -c checksums.sha256"
}

# Main build process
main() {
    echo -e "${GREEN}🏗️  GitUpdateProject Local Build Script${NC}"
    echo "========================================"
    echo ""
    
    check_dependencies
    get_version_info
    clean_build
    prepare_sources
    create_version_info
    create_packages
    create_checksums
    create_install_script
    show_summary
}

# Handle script arguments
case "${1:-}" in
    clean)
        print_status "Cleaning build directories..."
        clean_build
        print_info "Clean completed"
        ;;
    version)
        get_version_info
        echo "Version: $VERSION"
        ;;
    help|--help|-h)
        echo "GitUpdateProject Build Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)  - Run full build process"
        echo "  clean      - Clean build directories"
        echo "  version    - Show version information"
        echo "  help       - Show this help message"
        ;;
    *)
        main
        ;;
esac
