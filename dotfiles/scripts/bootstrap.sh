#!/usr/bin/env bash
# Bootstrap script for setting up a new machine with mise + chezmoi
# This script installs mise and chezmoi, then applies the dotfiles configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            error "Unsupported operating system"
            ;;
    esac
}

# Install mise
install_mise() {
    if command -v mise &> /dev/null; then
        info "mise is already installed"
        return
    fi

    info "Installing mise..."
    curl https://mise.run | sh

    # Add mise to PATH for current session
    export PATH="$HOME/.local/bin:$PATH"
}

# Install chezmoi
install_chezmoi() {
    if command -v chezmoi &> /dev/null; then
        info "chezmoi is already installed"
        return
    fi

    info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
}

# Install fish shell
install_fish() {
    if command -v fish &> /dev/null; then
        info "fish shell is already installed"
        return
    fi

    info "Installing fish shell..."
    OS=$(detect_os)
    
    if [ "$OS" = "macos" ]; then
        warn "Please install fish shell manually on macOS"
        warn "Visit: https://fishshell.com/ or use a package manager"
    else
        warn "Please install fish shell manually for your Linux distribution"
        warn "Ubuntu/Debian: sudo apt-get install fish"
        warn "Fedora: sudo dnf install fish"
        warn "Arch: sudo pacman -S fish"
    fi
}

# Install essential tools
install_essentials() {
    info "Essential tools will be installed via mise"
    info "This includes: bat, eza, fd, ripgrep, skim, delta, starship, zoxide, and more"
    info "Installing tools..."
    
    # Add mise to PATH if not already there
    export PATH="$HOME/.local/bin:$PATH"
    
    if command -v mise &> /dev/null; then
        mise install
    else
        warn "mise not found in PATH, tools will be installed after mise setup"
    fi
}

# Apply chezmoi configuration
apply_chezmoi() {
    info "Initializing chezmoi..."
    
    # Get the directory where this script is located
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
    
    if [ -d "$DOTFILES_DIR/.git" ]; then
        info "Applying dotfiles from $DOTFILES_DIR"
        chezmoi init --apply --source="$DOTFILES_DIR"
    else
        warn "Git repository not found in $DOTFILES_DIR"
        warn "Please clone your dotfiles repository and run this script again"
    fi
}

# Main setup flow
    # Apply configuration
    apply_chezmoi
    
    # Install tools via mise
    if command -v mise &> /dev/null; then
        info "Installing tools via mise..."
        cd "$DOTFILES_DIR"
        mise install
    fi
    
    info "Setup complete!"
    apply_chezmoi
    
    # Install tools via mise
    if command -v mise &> /dev/null; then
        info "Installing tools via mise..."
        cd "$HOME"
        mise install
    fi
    
    info "Setup complete!"
    info "Please restart your shell or run: exec fish"
    
    if [ "$(detect_os)" = "macos" ]; then
        info "To set fish as your default shell, run:"
        info "  sudo sh -c 'echo /opt/homebrew/bin/fish >> /etc/shells'"
        info "  chsh -s /opt/homebrew/bin/fish"
    else
        info "To set fish as your default shell, run:"
        info "  chsh -s $(which fish)"
    fi
}

main "$@"
    info "Setup complete!"
    info "Please restart your shell or run: exec fish"
    
    if [ "$(detect_os)" = "macos" ]; then
        info "To set fish as your default shell, run:"
        info "  sudo sh -c 'echo $(which fish) >> /etc/shells'"
        info "  chsh -s $(which fish)"
    else
        info "To set fish as your default shell, run:"
        info "  chsh -s $(which fish)"
    fi
}