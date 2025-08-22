#!/bin/bash
#
# Docker & Docker Compose One-Click Installation Script
# 
# Description: Automatically install Docker and Docker Compose on Linux systems
# Supports: Debian/Ubuntu, CentOS/RHEL/Fedora
# Features:
#   - System environment detection
#   - Automatic package manager selection
#   - Docker CE installation with official repositories
#   - Docker Compose plugin and standalone installation
#   - China region detection and Aliyun mirror support
#   - User permission setup
#   - Installation verification
#
# Usage: ./install_docker.sh
# Author: zdev0x
# License: MIT
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Global variables for region-specific URLs
DOCKER_DOWNLOAD_URL=""
DOCKER_COMPOSE_DOWNLOAD_URL=""
USE_ALIYUN_MIRROR=false

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
            if ! curl -s --connect-timeout 3 https://download.docker.com >/dev/null 2>&1; then
                is_china=true
            fi
        fi
    fi
    
    if [ "$is_china" = true ]; then
        USE_ALIYUN_MIRROR=true
        DOCKER_DOWNLOAD_URL="https://mirrors.aliyun.com/docker-ce"
        DOCKER_COMPOSE_DOWNLOAD_URL="https://github.com/docker/compose/releases"
        print_status "Using Aliyun mirror (China)"
    else
        USE_ALIYUN_MIRROR=false
        DOCKER_DOWNLOAD_URL="https://download.docker.com"
        DOCKER_COMPOSE_DOWNLOAD_URL="https://github.com/docker/compose/releases"
        print_status "Using official source (Global)"
    fi
}

check_system() {
    print_status "Checking system environment..."
    
    if ! command -v curl >/dev/null 2>&1; then
        print_error "curl is not installed, please install curl first"
        exit 1
    fi
    
    if [ "$(id -u)" = "0" ]; then
        print_warning "Running as root user"
    else
        print_status "Current user: $(whoami)"
    fi
    
    print_status "System info: $(uname -a)"
    print_status "Distribution info:"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "  - OS: $NAME $VERSION"
        echo "  - ID: $ID"
    fi
}

update_system() {
    print_status "Updating system package manager..."
    
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    elif command -v yum >/dev/null 2>&1; then
        sudo yum update -y
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf update -y
        sudo dnf install -y dnf-plugins-core
    else
        print_error "Unsupported package manager"
        exit 1
    fi
}

install_docker() {
    print_status "Starting Docker installation..."
    
    if command -v docker >/dev/null 2>&1; then
        print_warning "Docker is already installed, version: $(docker --version)"
        return 0
    fi
    
    if [ -f /etc/debian_version ]; then
        install_docker_debian
    elif [ -f /etc/redhat-release ]; then
        install_docker_redhat
    else
        print_status "Using official installation script..."
        if [ "$USE_ALIYUN_MIRROR" = true ]; then
            print_status "Using Aliyun mirror for installation script..."
            curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/docker-install.sh | sh || {
                print_warning "Aliyun mirror failed, falling back to official script..."
                curl -fsSL https://get.docker.com | sh
            }
        else
            curl -fsSL https://get.docker.com | sh
        fi
    fi
    
    sudo systemctl start docker
    sudo systemctl enable docker
    
    if [ "$(id -u)" != "0" ]; then
        print_status "Adding current user to docker group..."
        sudo usermod -aG docker $USER
        print_warning "Please logout and login again to take effect, or run 'newgrp docker'"
    fi
}

install_docker_debian() {
    print_status "Installing Docker on Debian/Ubuntu system..."
    
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    if [ "$USE_ALIYUN_MIRROR" = true ]; then
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    else
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi
    
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_redhat() {
    print_status "Installing Docker on Red Hat series system..."
    
    sudo yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
    
    if [ "$USE_ALIYUN_MIRROR" = true ]; then
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi
    else
        if command -v dnf >/dev/null 2>&1; then
            sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi
    fi
}

install_docker_compose() {
    print_status "Checking Docker Compose..."
    
    if docker compose version >/dev/null 2>&1; then
        print_success "Docker Compose (Plugin) is installed: $(docker compose version)"
        return 0
    fi
    
    if command -v docker-compose >/dev/null 2>&1; then
        print_success "Docker Compose (Standalone) is installed: $(docker-compose --version)"
        return 0
    fi
    
    print_status "Installing Docker Compose standalone..."
    
    # For Docker Compose, always use GitHub releases as it's the most reliable source
    # China users will benefit from faster Docker CE installation via Aliyun mirror
    COMPOSE_VERSION=$(curl -s --connect-timeout 10 https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    
    if [ -z "$COMPOSE_VERSION" ]; then
        COMPOSE_VERSION="v2.24.5"  # Fallback version
        print_warning "Failed to fetch latest version, using fallback: $COMPOSE_VERSION"
    fi
    
    sudo curl -L --connect-timeout 30 --max-time 300 "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    if [ ! -f /usr/bin/docker-compose ]; then
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    fi
}

configure_docker() {
    print_status "Configuring Docker..."
    
    if [ ! -d /etc/docker ]; then
        sudo mkdir -p /etc/docker
    fi
    
    if [ ! -f /etc/docker/daemon.json ]; then
        print_status "Creating Docker daemon configuration file..."
        sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "live-restore": true
}
EOF
        sudo systemctl restart docker
    fi
}

verify_installation() {
    print_status "Verifying installation..."
    
    if ! command -v docker >/dev/null 2>&1; then
        print_error "Docker installation failed"
        exit 1
    fi
    
    if ! sudo docker run --rm hello-world >/dev/null 2>&1; then
        print_error "Docker run test failed"
        exit 1
    fi
    
    print_success "Docker installed successfully: $(docker --version)"
    
    if docker compose version >/dev/null 2>&1; then
        print_success "Docker Compose (Plugin) available: $(docker compose version)"
    elif command -v docker-compose >/dev/null 2>&1; then
        print_success "Docker Compose (Standalone) available: $(docker-compose --version)"
    else
        print_warning "Docker Compose not installed correctly"
    fi
}

show_usage_info() {
    print_success "Installation completed!"
    echo ""
    echo "Common commands:"
    echo "  docker --version                 # Check Docker version"
    echo "  docker info                      # View Docker system info"
    echo "  docker images                    # List images"
    echo "  docker ps                        # List running containers"
    echo "  docker compose --help            # Docker Compose help"
    echo ""
    echo "Examples:"
    echo "  docker run -it ubuntu:20.04 /bin/bash"
    echo "  docker compose up -d"
    echo ""
    if [ "$(id -u)" != "0" ]; then
        print_warning "Please logout and login again, or run 'newgrp docker' to enable user group permissions"
    fi
}

main() {
    echo "========================================"
    echo "    Docker & Docker Compose Installer"
    echo "========================================"
    echo ""
    
    check_system
    detect_region
    update_system
    install_docker
    install_docker_compose
    configure_docker
    verify_installation
    show_usage_info
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi