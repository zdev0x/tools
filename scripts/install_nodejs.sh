#!/bin/bash
#
# Node.js One-Click Installation Script
# 
# Description: Automatically install Node.js and npm using NVM on Linux/macOS systems
# Supports: Linux (x64, arm64), macOS (x64, arm64)
# Features:
#   - Install specific Node.js version or latest LTS version
#   - NVM (Node Version Manager) installation and setup
#   - Multiple Node.js versions management
#   - China region detection and mirror acceleration
#   - Automatic environment variable setup
#   - Installation verification
#   - npm configuration optimization
#
# Usage: 
#   ./install_nodejs.sh                 # Install latest LTS version
#   ./install_nodejs.sh 18.19.0         # Install specific version
#   ./install_nodejs.sh --lts           # Install latest LTS version
#   ./install_nodejs.sh --help          # Show help
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
NODE_VERSION=""
INSTALL_LTS=false
FORCE_INSTALL=false
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
NVM_VERSION="v0.39.5"
USE_CHINA_MIRROR=false

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
Node.js Installation Script

USAGE:
    $0 [VERSION] [OPTIONS]

ARGUMENTS:
    VERSION     Node.js version to install (e.g., 18.19.0, 20.10.0)
                If not specified, installs the latest LTS version

OPTIONS:
    --help, -h          Show this help message
    --lts               Install latest LTS version (default behavior)
    --force             Force reinstall even if version exists
    --no-npm-config     Skip npm configuration optimization

EXAMPLES:
    $0                  # Install latest LTS version
    $0 18.19.0          # Install Node.js 18.19.0
    $0 --lts            # Install latest LTS version
    $0 20.10.0 --force  # Force install Node.js 20.10.0

ENVIRONMENT VARIABLES:
    NVM_DIR             NVM installation directory (default: ~/.nvm)
EOF
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
    if [ "$is_china" = false ] && [[ "$LANG" == *"zh_CN"* ]]; then
        is_china=true
    fi
    
    # Method 3: Test connectivity (timeout after 3 seconds)
    if [ "$is_china" = false ]; then
        if command -v curl >/dev/null 2>&1; then
            if ! curl -s --connect-timeout 3 https://nodejs.org >/dev/null 2>&1; then
                is_china=true
            fi
        fi
    fi
    
    if [ "$is_china" = true ]; then
        USE_CHINA_MIRROR=true
        print_status "Using China mirror acceleration"
    else
        USE_CHINA_MIRROR=false
        print_status "Using official source (Global)"
    fi
}

check_dependencies() {
    print_status "Checking system dependencies..."
    
    # Check for curl or wget
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        print_error "Neither curl nor wget found. Please install one of them."
        exit 1
    fi
    
    # Check for git (required by some npm packages)
    if ! command -v git >/dev/null 2>&1; then
        print_warning "Git not found. Some npm packages may require git."
        if command -v apt-get >/dev/null 2>&1; then
            print_status "Installing git..."
            sudo apt-get update && sudo apt-get install -y git
        elif command -v yum >/dev/null 2>&1; then
            print_status "Installing git..."
            sudo yum install -y git
        elif command -v dnf >/dev/null 2>&1; then
            print_status "Installing git..."
            sudo dnf install -y git
        fi
    fi
}

install_nvm() {
    print_status "Installing NVM (Node Version Manager)..."
    
    # Check if NVM is already installed
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        print_warning "NVM is already installed at $NVM_DIR"
        return 0
    fi
    
    # Download and install NVM
    local nvm_install_url
    if [ "$USE_CHINA_MIRROR" = true ]; then
        nvm_install_url="https://gitee.com/mirrors/nvm/raw/v${NVM_VERSION#v}/install.sh"
    else
        nvm_install_url="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"
    fi
    
    print_status "Downloading NVM from: $nvm_install_url"
    
    if command -v curl >/dev/null 2>&1; then
        curl -o- "$nvm_install_url" | bash
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$nvm_install_url" | bash
    fi
    
    # Verify NVM installation
    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        print_error "NVM installation failed"
        exit 1
    fi
    
    print_success "NVM installed successfully"
}

setup_nvm_environment() {
    print_status "Setting up NVM environment..."
    
    # Source NVM for current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    
    # Configure China mirror if needed
    if [ "$USE_CHINA_MIRROR" = true ]; then
        print_status "Configuring NVM with China mirrors..."
        export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
        export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs/
    fi
}

get_node_version() {
    if [ -n "$NODE_VERSION" ]; then
        echo "$NODE_VERSION"
        return
    fi
    
    print_status "Fetching latest LTS Node.js version..."
    
    # Source NVM first
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command -v nvm >/dev/null 2>&1; then
        local lts_version=$(nvm ls-remote --lts 2>/dev/null | tail -1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$lts_version" ]; then
            echo "${lts_version#v}"
        else
            echo "18.19.0"  # Fallback version
        fi
    else
        echo "18.19.0"  # Fallback version
    fi
}

install_nodejs() {
    local version=$1
    print_status "Installing Node.js $version..."
    
    # Source NVM
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command -v nvm >/dev/null 2>&1; then
        print_error "NVM not found. Please restart your terminal or source ~/.bashrc"
        exit 1
    fi
    
    # Check if version is already installed
    if nvm list | grep -q "v$version" && [ "$FORCE_INSTALL" != "true" ]; then
        print_warning "Node.js $version is already installed. Use --force to reinstall."
        nvm use "$version"
        return 0
    fi
    
    # Install Node.js
    if ! nvm install "$version"; then
        print_error "Failed to install Node.js $version"
        exit 1
    fi
    
    # Use the installed version
    nvm use "$version"
    
    # Set as default
    nvm alias default "$version"
    
    print_success "Node.js $version installed and set as default"
}

configure_npm() {
    if [ "$SKIP_NPM_CONFIG" = "true" ]; then
        return 0
    fi
    
    print_status "Configuring npm..."
    
    # Source NVM to ensure npm is available
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command -v npm >/dev/null 2>&1; then
        print_warning "npm not found, skipping npm configuration"
        return 0
    fi
    
    # Configure npm registry for China users
    if [ "$USE_CHINA_MIRROR" = true ]; then
        print_status "Configuring npm with China registry..."
        npm config set registry https://registry.npmmirror.com/
        npm config set disturl https://npmmirror.com/mirrors/node/
        npm config set electron_mirror https://npmmirror.com/mirrors/electron/
        npm config set sass_binary_site https://npmmirror.com/mirrors/node-sass/
        npm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs/
    fi
    
    # Set npm global directory to avoid permission issues
    local npm_global_dir="$HOME/.npm-global"
    mkdir -p "$npm_global_dir"
    npm config set prefix "$npm_global_dir"
    
    print_success "npm configured successfully"
}

setup_environment() {
    print_status "Setting up environment variables..."
    
    local profile_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    local env_setup="
# NVM environment setup
export NVM_DIR=\"\$HOME/.nvm\"
[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"
[ -s \"\$NVM_DIR/bash_completion\" ] && \\. \"\$NVM_DIR/bash_completion\"

# npm global packages
export PATH=\"\$HOME/.npm-global/bin:\$PATH\""

    if [ "$USE_CHINA_MIRROR" = true ]; then
        env_setup="$env_setup

# NVM China mirrors
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs/"
    fi
    
    for profile in "${profile_files[@]}"; do
        if [ -f "$profile" ]; then
            # Remove existing Node.js/NVM setup
            sed -i '/# NVM environment setup/,+10d' "$profile" 2>/dev/null || true
            sed -i '/# npm global packages/,+1d' "$profile" 2>/dev/null || true
            sed -i '/# NVM China mirrors/,+2d' "$profile" 2>/dev/null || true
            
            # Add new setup
            echo "$env_setup" >> "$profile"
            print_status "Updated $profile"
        fi
    done
}

verify_installation() {
    print_status "Verifying installation..."
    
    # Source NVM for verification
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! command -v node >/dev/null 2>&1; then
        print_error "Node.js installation verification failed"
        print_error "Please restart your terminal or run: source ~/.bashrc"
        return 1
    fi
    
    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm installation verification failed"
        return 1
    fi
    
    local node_version=$(node --version)
    local npm_version=$(npm --version)
    
    print_success "Node.js installed: $node_version"
    print_success "npm installed: v$npm_version"
    
    # Test npm installation
    print_status "Testing npm functionality..."
    if npm list -g --depth=0 >/dev/null 2>&1; then
        print_success "npm is working correctly"
    else
        print_warning "npm may have issues, but installation completed"
    fi
    
    # Show available Node.js versions
    if command -v nvm >/dev/null 2>&1; then
        print_status "Available Node.js versions via NVM:"
        nvm list
    fi
}

show_usage_info() {
    print_success "Node.js installation completed!"
    echo ""
    echo "Environment setup:"
    echo "  NVM_DIR=$NVM_DIR"
    echo "  npm global packages: $HOME/.npm-global"
    echo ""
    echo "Please restart your terminal or run:"
    echo "  source ~/.bashrc"
    echo ""
    echo "Common commands:"
    echo "  node --version              # Check Node.js version"
    echo "  npm --version               # Check npm version"
    echo "  nvm list                    # List installed Node.js versions"
    echo "  nvm install <version>       # Install specific Node.js version"
    echo "  nvm use <version>           # Switch to specific version"
    echo "  npm install -g <package>    # Install global package"
    echo ""
    echo "Examples:"
    echo "  nvm install 20.10.0         # Install Node.js 20.10.0"
    echo "  nvm use 18.19.0             # Switch to Node.js 18.19.0"
    echo "  npm install -g typescript   # Install TypeScript globally"
    echo ""
    if [ "$USE_CHINA_MIRROR" = true ]; then
        echo "China mirrors configured:"
        echo "  Node.js: https://npmmirror.com/mirrors/node/"
        echo "  npm: https://registry.npmmirror.com/"
    fi
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --lts)
                INSTALL_LTS=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --no-npm-config)
                SKIP_NPM_CONFIG=true
                shift
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                if [ -z "$NODE_VERSION" ]; then
                    NODE_VERSION="$1"
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
    echo "      Node.js Installation Script"
    echo "========================================"
    echo ""
    
    parse_arguments "$@"
    
    detect_region
    check_dependencies
    install_nvm
    setup_nvm_environment
    
    if [ -z "$NODE_VERSION" ] || [ "$INSTALL_LTS" = true ]; then
        NODE_VERSION=$(get_node_version)
    fi
    
    print_status "Installing Node.js version: $NODE_VERSION"
    
    install_nodejs "$NODE_VERSION"
    configure_npm
    setup_environment
    verify_installation
    show_usage_info
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi