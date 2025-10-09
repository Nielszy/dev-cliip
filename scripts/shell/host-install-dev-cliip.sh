#!/bin/bash

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "=================================="
echo "dev-cliip host system dependency installer"
echo "=================================="
echo ""

# Check if running on ARM64 Mac
if [[ $(uname -m) != "arm64" ]]; then
    echo -e "${RED}Error:${NC} This script is designed for Apple Silicon (ARM64) Macs only."
    exit 1
fi

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Homebrew
echo "Checking Homebrew..."
if command_exists brew; then
    VERSION=$(brew --version | head -n 1)
    echo -e "${GREEN}✓${NC} Homebrew already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    echo -e "${GREEN}✓${NC} Homebrew installed successfully"
fi
echo ""

# Lima
echo "Checking Lima..."
if command_exists limactl; then
    VERSION=$(limactl --version)
    echo -e "${GREEN}✓${NC} Lima already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing Lima..."
    brew install lima
    echo -e "${GREEN}✓${NC} Lima installed successfully"
fi
echo ""

# kubectl
echo "Checking kubectl..."
if command_exists kubectl; then
    VERSION=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | grep "Client Version" | cut -d' ' -f3)
    echo -e "${GREEN}✓${NC} kubectl already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing kubectl..."
    brew install kubectl
    echo -e "${GREEN}✓${NC} kubectl installed successfully"
fi
echo ""

# Helm
echo "Checking Helm..."
if command_exists helm; then
    VERSION=$(helm version --short)
    echo -e "${GREEN}✓${NC} Helm already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing Helm..."
    brew install helm
    echo -e "${GREEN}✓${NC} Helm installed successfully"
fi
echo ""

# cilium-cli
echo "Checking cilium-cli..."
if command_exists cilium; then
    VERSION=$(cilium version --client 2>/dev/null | grep "cilium-cli" | awk '{print $2}')
    echo -e "${GREEN}✓${NC} cilium-cli already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing cilium-cli..."
    brew install cilium-cli
    echo -e "${GREEN}✓${NC} cilium-cli installed successfully"
fi
echo ""

# Flux CLI
echo "Checking Flux CLI..."
if command_exists flux; then
    VERSION=$(flux version --client 2>/dev/null | grep "flux:" | awk '{print $2}')
    echo -e "${GREEN}✓${NC} Flux CLI already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing Flux CLI..."
    brew install fluxcd/tap/flux
    echo -e "${GREEN}✓${NC} Flux CLI installed successfully"
fi
echo ""

# kubeseal
echo "Checking kubeseal..."
if command_exists kubeseal; then
    VERSION=$(kubeseal --version 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "version unknown")
    echo -e "${GREEN}✓${NC} kubeseal already installed: ${BLUE}$VERSION${NC}"
else
    echo -e "${YELLOW}→${NC} Installing kubeseal ${KUBESEAL_VERSION}..."
    brew install kubeseal@${KUBESEAL_VERSION} || brew install kubeseal
    echo -e "${GREEN}✓${NC} kubeseal installed successfully"
fi
echo ""

echo "=================================="
echo -e "${GREEN}Installation complete!${NC}"
echo "=================================="
echo ""
echo "Installed tools summary:"
command_exists brew && echo "  • Homebrew: $(brew --version | head -n 1)"
command_exists limactl && echo "  • Lima: $(limactl --version)"
command_exists kubectl && echo "  • kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | grep 'Client Version' | cut -d' ' -f3)"
command_exists helm && echo "  • Helm: $(helm version --short)"
command_exists cilium && echo "  • cilium-cli: $(cilium version --client 2>/dev/null | grep 'cilium-cli' | awk '{print $2}')"
command_exists flux && echo "  • Flux CLI: $(flux version --client 2>/dev/null | grep 'flux:' | awk '{print $2}')"
command_exists kubeseal && echo "  • kubeseal: $(kubeseal --version 2>&1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo 'version unknown')"