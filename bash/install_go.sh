#!/bin/bash
#
# Go One-Click Installation Script
# 
# Description: Automatically install Go programming language on Linux/macOS systems
# Supports: Linux (x64, arm64), macOS (x64, arm64)
# Features:
#   - Install specific Go version or latest version
#   - Automatic architecture detection
#   - Environment variable setup
#   - Installation verification
#   - Clean removal of old versions
#
# Usage: 
#   ./install_go.sh                 # Install latest version
#   ./install_go.sh 1.21.5          # Install specific version
#   ./install_go.sh --help           # Show help
#
# Author: zdev0x
# License: MIT
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default settings
DEFAULT_INSTALL_DIR="/usr/local"
GO_INSTALL_DIR="${GO_INSTALL_DIR:-$DEFAULT_INSTALL_DIR}"
GO_VERSION=""
LATEST_VERSION=""
DOWNLOAD_BASE_URL=""
VERSION_URL=""

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

show_help() {
    cat <<EOF
Go Installation Script

USAGE:
    $0 [VERSION] [OPTIONS]

ARGUMENTS:
    VERSION     Go version to install (e.g., 1.21.5, 1.20.10)
                If not specified, installs the latest stable version

OPTIONS:
    --help, -h          Show this help message
    --dir DIR           Installation directory (default: /usr/local)
    --force             Force reinstall even if version exists

EXAMPLES:
    $0                  # Install latest version
    $0 1.21.5           # Install Go 1.21.5
    $0 1.20.10 --force  # Force install Go 1.20.10

ENVIRONMENT VARIABLES:
    GO_INSTALL_DIR      Installation directory (default: /usr/local)
EOF
}

detect_system() {
    print_status "Detecting system architecture..."
    
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        armv6l)
            ARCH="armv6l"
            ;;
        armv7l)
            ARCH="armv6l"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    case $OS in
        linux)
            OS="linux"
            ;;
        darwin)
            OS="darwin"
            ;;
        *)
            print_error "Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    print_status "Detected system: $OS-$ARCH"
}

detect_region() {
    print_status "Detecting optimal download source..."
    
    # Try to detect if in China
    local is_china=false
    
    # Method 1: Check timezone
    if [ -f /etc/timezone ]; then
        local timezone=$(cat /etc/timezone)
        if [[ "$timezone" == "Asia/Shanghai" || "$timezone" == "Asia/Chongqing" ]]; then
            is_china=true
        fi
    fi
    
    # Method 2: Check locale
    if [ -z "$is_china" ] && [[ "$LANG" == *"zh_CN"* ]]; then
        is_china=true
    fi
    
    # Method 3: Test connectivity (timeout after 3 seconds)
    if [ "$is_china" = false ]; then
        if command -v curl >/dev/null 2>&1; then
            if ! curl -s --connect-timeout 3 https://golang.org >/dev/null 2>&1; then
                is_china=true
            fi
        elif command -v wget >/dev/null 2>&1; then
            if ! wget --timeout=3 --tries=1 -q --spider https://golang.org >/dev/null 2>&1; then
                is_china=true
            fi
        fi
    fi
    
    if [ "$is_china" = true ]; then
        DOWNLOAD_BASE_URL="https://mirrors.aliyun.com/golang"
        VERSION_URL="https://mirrors.aliyun.com/golang/VERSION?m=text"
        print_status "Using Aliyun mirror (China)"
    else
        DOWNLOAD_BASE_URL="https://golang.org/dl"
        VERSION_URL="https://golang.org/VERSION?m=text"
        print_status "Using official source (Global)"
    fi
}

get_latest_version() {
    print_status "Fetching latest Go version..."
    
    if command -v curl >/dev/null 2>&1; then
        LATEST_VERSION=$(curl -s --connect-timeout 10 "$VERSION_URL" | head -1)
    elif command -v wget >/dev/null 2>&1; then
        LATEST_VERSION=$(wget --timeout=10 --tries=2 -qO- "$VERSION_URL" | head -1)
    else
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    if [ -z "$LATEST_VERSION" ]; then
        print_error "Failed to fetch latest Go version"
        exit 1
    fi
    
    # Remove 'go' prefix if present
    LATEST_VERSION=${LATEST_VERSION#go}
    print_status "Latest Go version: $LATEST_VERSION"
}

validate_version() {
    local version=$1
    
    if [[ ! $version =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?(rc[0-9]+|beta[0-9]+)?$ ]]; then
        print_error "Invalid version format: $version"
        print_error "Expected format: X.Y.Z (e.g., 1.21.5, 1.20.10)"
        exit 1
    fi
}

check_existing_installation() {
    local version=$1
    
    if [ -d "$GO_INSTALL_DIR/go" ]; then
        if command -v go >/dev/null 2>&1; then
            local current_version=$(go version | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
            print_warning "Go $current_version is already installed at $GO_INSTALL_DIR/go"
            
            if [ "$current_version" = "$version" ] && [ "$FORCE_INSTALL" != "true" ]; then
                print_status "Target version $version is already installed. Use --force to reinstall."
                exit 0
            fi
        fi
    fi
}

remove_old_installation() {
    if [ -d "$GO_INSTALL_DIR/go" ]; then
        print_status "Removing existing Go installation..."
        sudo rm -rf "$GO_INSTALL_DIR/go"
    fi
}

download_and_install() {
    local version=$1
    local download_url="$DOWNLOAD_BASE_URL/go${version}.${OS}-${ARCH}.tar.gz"
    local temp_file="/tmp/go${version}.${OS}-${ARCH}.tar.gz"
    
    print_status "Downloading Go $version for $OS-$ARCH..."
    print_status "URL: $download_url"
    
    if command -v curl >/dev/null 2>&1; then
        if ! curl -L --connect-timeout 30 --max-time 600 "$download_url" -o "$temp_file"; then
            print_error "Failed to download Go $version"
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget --timeout=30 --tries=3 "$download_url" -O "$temp_file"; then
            print_error "Failed to download Go $version"
            exit 1
        fi
    fi
    
    if [ ! -f "$temp_file" ]; then
        print_error "Download file not found: $temp_file"
        exit 1
    fi
    
    print_status "Installing Go $version to $GO_INSTALL_DIR..."
    
    # Extract to installation directory
    sudo tar -C "$GO_INSTALL_DIR" -xzf "$temp_file"
    
    # Clean up
    rm -f "$temp_file"
    
    print_success "Go $version installed successfully"
}

setup_environment() {
    local go_root="$GO_INSTALL_DIR/go"
    local go_path="$HOME/go"
    
    print_status "Setting up Go environment..."
    
    # Create GOPATH directory
    mkdir -p "$go_path"
    
    # Setup environment variables
    local profile_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    local env_setup="
# Go environment setup
export GOROOT=$go_root
export GOPATH=$go_path
export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH"
    
    for profile in "${profile_files[@]}"; do
        if [ -f "$profile" ]; then
            # Remove existing Go setup
            sed -i '/# Go environment setup/,+3d' "$profile" 2>/dev/null || true
            
            # Add new setup
            echo "$env_setup" >> "$profile"
            print_status "Updated $profile"
        fi
    done
    
    # Also update current session
    export GOROOT="$go_root"
    export GOPATH="$go_path"
    export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
}

verify_installation() {
    print_status "Verifying installation..."
    
    if ! command -v go >/dev/null 2>&1; then
        print_error "Go command not found. Please restart your terminal or run: source ~/.bashrc"
        return 1
    fi
    
    local installed_version=$(go version)
    print_success "Installation verified: $installed_version"
    
    # Test Go installation
    local test_dir="/tmp/go_test_$$"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    cat > main.go <<EOF
package main

import "fmt"

func main() {
    fmt.Println("Hello, Go!")
}
EOF
    
    if go run main.go >/dev/null 2>&1; then
        print_success "Go is working correctly"
    else
        print_warning "Go installation may have issues"
    fi
    
    # Clean up test
    cd - >/dev/null
    rm -rf "$test_dir"
}

show_usage_info() {
    print_success "Go installation completed!"
    echo ""
    echo "Environment setup:"
    echo "  GOROOT=$GO_INSTALL_DIR/go"
    echo "  GOPATH=$HOME/go"
    echo ""
    echo "Please restart your terminal or run:"
    echo "  source ~/.bashrc"
    echo ""
    echo "Common commands:"
    echo "  go version              # Check Go version"
    echo "  go env                  # Show Go environment"
    echo "  go mod init <name>      # Create new module"
    echo "  go build               # Build current package"
    echo "  go run main.go         # Run Go program"
    echo ""
    echo "Getting started:"
    echo "  mkdir -p ~/go/src/hello"
    echo "  cd ~/go/src/hello"
    echo "  echo 'package main; import \"fmt\"; func main() { fmt.Println(\"Hello, World!\") }' > main.go"
    echo "  go run main.go"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --dir)
                GO_INSTALL_DIR="$2"
                shift 2
                ;;
            --force)
                FORCE_INSTALL="true"
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$GO_VERSION" ]; then
                    GO_VERSION="$1"
                else
                    print_error "Too many arguments"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

main() {
    echo "========================================"
    echo "         Go Installation Script"
    echo "========================================"
    echo ""
    
    parse_arguments "$@"
    
    # Check for required tools
    if ! command -v tar >/dev/null 2>&1; then
        print_error "tar command not found"
        exit 1
    fi
    
    detect_system
    detect_region
    
    if [ -z "$GO_VERSION" ]; then
        get_latest_version
        GO_VERSION="$LATEST_VERSION"
    else
        validate_version "$GO_VERSION"
    fi
    
    print_status "Installing Go version: $GO_VERSION"
    
    check_existing_installation "$GO_VERSION"
    remove_old_installation
    download_and_install "$GO_VERSION"
    setup_environment
    verify_installation
    show_usage_info
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi