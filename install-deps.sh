#!/bin/bash

# Installation script for vulnerability scanner dependencies
# Supports Ubuntu/Debian, CentOS/RHEL/Fedora

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        print_error "Cannot detect OS"
        exit 1
    fi
    
    print_status "Detected OS: $OS"
}

# Install for Ubuntu/Debian
install_debian() {
    print_status "Installing dependencies for Debian/Ubuntu..."
    
    sudo apt-get update
    
    # Install basic tools
    sudo apt-get install -y \
        nmap \
        curl \
        dnsutils \
        whois \
        jq \
        bc \
        git \
        wget
    
    # Install optional tools
    sudo apt-get install -y nikto whatweb || {
        print_warning "Some optional tools failed to install"
    }
    
    # Install Nuclei
    install_nuclei
    
    print_success "Debian/Ubuntu installation completed"
}

# Install for CentOS/RHEL/Fedora
install_redhat() {
    print_status "Installing dependencies for RedHat/CentOS/Fedora..."
    
    local pkg_mgr="yum"
    if command -v dnf &> /dev/null; then
        pkg_mgr="dnf"
    fi
    
    # Install basic tools
    sudo $pkg_mgr install -y \
        nmap \
        curl \
        bind-utils \
        whois \
        jq \
        bc \
        git \
        wget
    
    # Try to install EPEL for additional tools
    if [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        sudo $pkg_mgr install -y epel-release || {
            print_warning "Failed to install EPEL repository"
        }
    fi
    
    # Install Nuclei
    install_nuclei
    
    print_warning "Note: Nikto and WhatWeb may need manual installation on RedHat systems"
    
    print_success "RedHat/CentOS/Fedora installation completed"
}

# Install Nuclei
install_nuclei() {
    print_status "Installing Nuclei..."
    
    if command -v go &> /dev/null; then
        print_status "Installing Nuclei using Go..."
        GO111MODULE=on go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
        
        # Add Go bin to PATH if not already
        if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
            echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
            export PATH=$PATH:$HOME/go/bin
        fi
    else
        print_status "Go not found, downloading Nuclei binary..."
        
        # Download latest release
        local nuclei_version
        nuclei_version=$(curl -s https://api.github.com/repos/projectdiscovery/nuclei/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
        
        if [ -z "$nuclei_version" ]; then
            print_error "Failed to get Nuclei version"
            return 1
        fi
        
        local arch
        arch=$(uname -m)
        case $arch in
            x86_64)
                arch="amd64"
                ;;
            aarch64)
                arch="arm64"
                ;;
            *)
                print_error "Unsupported architecture: $arch"
                return 1
                ;;
        esac
        
        local download_url="https://github.com/projectdiscovery/nuclei/releases/download/${nuclei_version}/nuclei_${nuclei_version#v}_linux_${arch}.zip"
        
        wget -O /tmp/nuclei.zip "$download_url" || {
            print_error "Failed to download Nuclei"
            return 1
        }
        
        unzip -o /tmp/nuclei.zip -d /tmp/
        sudo mv /tmp/nuclei /usr/local/bin/
        sudo chmod +x /usr/local/bin/nuclei
        rm -f /tmp/nuclei.zip
    fi
    
    # Update nuclei templates
    if command -v nuclei &> /dev/null; then
        print_status "Updating Nuclei templates..."
        nuclei -update-templates || {
            print_warning "Failed to update Nuclei templates"
        }
        print_success "Nuclei installed successfully"
    else
        print_error "Nuclei installation failed"
    fi
}

# Install Go (if needed for Nuclei)
install_go() {
    if command -v go &> /dev/null; then
        print_status "Go is already installed"
        return 0
    fi
    
    print_status "Installing Go..."
    
    local go_version="1.21.5"
    local arch
    arch=$(uname -m)
    case $arch in
        x86_64)
            arch="amd64"
            ;;
        aarch64)
            arch="arm64"
            ;;
        *)
            print_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    wget -O /tmp/go.tar.gz "https://golang.org/dl/go${go_version}.linux-${arch}.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
    
    # Add Go to PATH
    if [[ ":$PATH:" != *":/usr/local/go/bin:"* ]]; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
        export PATH=$PATH:/usr/local/go/bin
    fi
    
    print_success "Go installed successfully"
}

# Verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    local required_tools=("nmap" "curl" "dig" "whois")
    local optional_tools=("nikto" "nuclei" "whatweb" "jq" "bc")
    
    local missing_required=()
    local missing_optional=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_required+=("$tool")
        else
            print_success "$tool is installed"
        fi
    done
    
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_optional+=("$tool")
        else
            print_success "$tool is installed"
        fi
    done
    
    if [ ${#missing_required[@]} -eq 0 ]; then
        print_success "All required tools are installed!"
    else
        print_error "Missing required tools: ${missing_required[*]}"
        return 1
    fi
    
    if [ ${#missing_optional[@]} -gt 0 ]; then
        print_warning "Missing optional tools: ${missing_optional[*]}"
        print_warning "Some features may not work properly"
    fi
}

# Main function
main() {
    print_status "Vulnerability Scanner Dependency Installer"
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please don't run this script as root"
        print_status "The script will ask for sudo permissions when needed"
        exit 1
    fi
    
    detect_os
    
    case "$OS" in
        *"Ubuntu"*|*"Debian"*)
            install_debian
            ;;
        *"CentOS"*|*"Red Hat"*|*"Fedora"*)
            install_redhat
            ;;
        *)
            print_error "Unsupported OS: $OS"
            print_status "Please install dependencies manually:"
            echo "  Required: nmap, curl, dig, whois"
            echo "  Optional: nikto, nuclei, whatweb, jq, bc"
            exit 1
            ;;
    esac
    
    verify_installation
    
    print_success "Installation completed!"
    print_status "You can now run the vulnerability scanner:"
    echo "  ./vulnerability-scanner.sh example.com"
}

# Show usage if help requested
if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
    cat << EOF
Vulnerability Scanner Dependency Installer

This script installs all required and optional dependencies for the
vulnerability scanner on supported Linux distributions.

Supported OS:
  - Ubuntu/Debian
  - CentOS/RHEL/Fedora

Usage: $0

The script will:
1. Detect your operating system
2. Install required tools (nmap, curl, dig, whois)
3. Install optional tools (nikto, nuclei, whatweb, jq, bc)
4. Verify all installations

Note: This script requires sudo privileges for package installation.
EOF
    exit 0
fi

main "$@"
