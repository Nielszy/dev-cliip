#!/bin/bash

set -e

# Pinned versions
DOCKER_VERSION="5:28.5.0-1~debian.13~trixie"
MINIKUBE_VERSION="v1.37.0"
CONTAINERLAB_VERSION="0.70.2"
GH_VERSION="2.81.0"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "=================================="
echo "dev-cliip guest system dependency installer"
echo "=================================="
echo ""

# Check if running on ARM64 Debian
if [[ $(uname -m) != "aarch64" ]]; then
    echo -e "${RED}Error:${NC} This script is designed for ARM64 (aarch64) systems only."
    exit 1
fi

# Check if running Debian
if [[ ! -f /etc/debian_version ]]; then
    echo -e "${RED}Error:${NC} This script is designed for Debian systems only."
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Docker
echo "Checking Docker..."
if command_exists docker; then
    VERSION=$(docker --version)
    echo -e "${GREEN}✓${NC} Docker already installed: ${BLUE}$VERSION${NC}"

    # Check if user is in docker group
    if groups $USER | grep -q '\bdocker\b'; then
        echo -e "${GREEN}✓${NC} User $USER is already in docker group"
    else
        echo -e "${YELLOW}→${NC} Adding user $USER to docker group..."
        sudo usermod -aG docker $USER
    fi
else
    echo -e "${YELLOW}→${NC} Installing Docker..."

    # Remove old packages
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg 2>/dev/null || true
    done

    # Install prerequisites
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce=${DOCKER_VERSION} docker-ce-cli=${DOCKER_VERSION} containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker $USER

    echo -e "${GREEN}✓${NC} Docker installed successfully"
fi
echo ""

# minikube
echo "Checking minikube..."
if command_exists minikube; then
    VERSION=$(minikube version --short)
    echo -e "${GREEN}✓${NC} minikube already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing minikube ${MINIKUBE_VERSION}..."

    # Download specific minikube version
    curl -LO https://github.com/kubernetes/minikube/releases/download/${MINIKUBE_VERSION}/minikube-linux-arm64

    # Install minikube
    sudo install minikube-linux-arm64 /usr/local/bin/minikube
    rm minikube-linux-arm64

    echo -e "${GREEN}✓${NC} minikube installed successfully"
fi
echo ""

# Containerlab
echo "Checking Containerlab..."
if command_exists containerlab; then
    VERSION=$(containerlab version | grep "version:" | awk '{print $2}')
    echo -e "${GREEN}✓${NC} Containerlab already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing Containerlab ${CONTAINERLAB_VERSION}..."

    # Download and install specific version
    bash -c "$(curl -sL https://get.containerlab.dev)" -- -v ${CONTAINERLAB_VERSION}

    echo -e "${GREEN}✓${NC} Containerlab installed successfully"
fi
echo ""

# GitHub CLI (gh)
echo "Checking GitHub CLI..."
if command_exists gh; then
    VERSION=$(gh --version | head -n 1)
    echo -e "${GREEN}✓${NC} GitHub CLI already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing GitHub CLI ${GH_VERSION}..."

    # Add GitHub CLI repository
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    # Install specific gh version
    sudo apt-get update
    sudo apt-get install -y gh=${GH_VERSION}

    echo -e "${GREEN}✓${NC} GitHub CLI installed successfully"
fi
echo ""

echo "=================================="
echo -e "${GREEN}Installation complete!${NC}"
echo "=================================="
echo ""
echo "Installed tools summary:"
command_exists docker && echo "  • Docker: $(docker --version)"
command_exists minikube && echo "  • minikube: $(minikube version --short)"
command_exists containerlab && echo "  • Containerlab: $(containerlab version | grep 'version:' | awk '{print $2}')"
command_exists gh && echo "  • GitHub CLI: $(gh --version | head -n 1)"
echo ""

# Apply docker group membership if needed
if ! groups | grep -q '\bdocker\b' 2>/dev/null; then
    echo -e "${YELLOW}→${NC} Activating docker group membership..."
    exec newgrp docker
fi