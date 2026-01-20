.PHONY: help build test test-interactive clean lint
.PHONY: system-deps core fish tools setup-github apply apply-gnome bootstrap
.PHONY: nix nix-install nix-setup nix-apply
.PHONY: install setup chezmoi chezmoi-apply chezmoi-diff chezmoi-update

IMAGE_NAME := dotfiles
CONTAINER_NAME := dotfiles-run
DOTFILES_DIR := $(shell pwd)
BIN_DIR := $(HOME)/.local/bin

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo '=== Quick Start (recommended) ==='
	@echo '  install                   Install chezmoi and apply dotfiles (all-in-one)'
	@echo '  setup                     Same as install'
	@echo ''
	@echo '=== Chezmoi Commands ==='
	@echo '  chezmoi                   Install chezmoi only'
	@echo '  chezmoi-apply             Apply dotfiles with chezmoi'
	@echo '  chezmoi-diff              Show diff of pending changes'
	@echo '  chezmoi-update            Pull latest and apply'
	@echo ''
	@echo '=== Docker Testing ==='
	@echo '  build                     Build Docker test image'
	@echo '  test-interactive          Run interactive test container'
	@echo '  clean                     Remove Docker test resources'
	@echo ''
	@echo '=== Nix Commands ==='
	@echo '  nix-apply TARGET=<name>   Apply nix home-manager configuration'
	@echo ''
	@echo 'Nix apply examples:'
	@echo '  make nix-apply TARGET=terassyi@dev'
	@echo '  make nix-apply TARGET=terashima@darwin1'

# =============================================================================
# Quick Start (Recommended)
# =============================================================================

# Default target for nix configuration (can be overridden: make install TARGET=terassyi@dev)
TARGET ?=

install: ## Install chezmoi and apply all dotfiles (includes nix, mise, etc.)
	@mkdir -p $(BIN_DIR)
	@if [ ! -f "$(BIN_DIR)/chezmoi" ]; then \
		echo "→ Installing chezmoi to $(BIN_DIR)..."; \
		sh -c "$$(curl -fsLS get.chezmoi.io)" -- -b "$(BIN_DIR)"; \
	else \
		echo "✓ chezmoi already installed at $(BIN_DIR)/chezmoi"; \
	fi
	@echo "→ Applying dotfiles..."
	@NIX_CONFIG_NAME="$(TARGET)" $(BIN_DIR)/chezmoi init --apply --source="$(DOTFILES_DIR)"
	@echo ""
	@echo "✓ Setup complete!"
	@echo ""
	@echo "⚠ Please restart your shell or run: exec fish"

setup: install ## Alias for install

# =============================================================================
# Chezmoi Commands
# =============================================================================

chezmoi: $(BIN_DIR)/chezmoi ## Install chezmoi

chezmoi-apply: ## Apply dotfiles with chezmoi
	@if command -v chezmoi > /dev/null 2>&1; then \
		echo "→ Applying dotfiles..."; \
		chezmoi apply --source="$(DOTFILES_DIR)"; \
		echo "✓ Dotfiles applied"; \
	else \
		echo "→ Installing chezmoi and applying dotfiles..."; \
		sh -c "$$(curl -fsLS get.chezmoi.io)" -- init --apply --source="$(DOTFILES_DIR)"; \
		echo "✓ Dotfiles applied"; \
	fi

chezmoi-diff: ## Show diff of pending changes
	@if command -v chezmoi > /dev/null 2>&1; then \
		chezmoi diff --source="$(DOTFILES_DIR)"; \
	else \
		echo "⚠ chezmoi not installed. Run 'make chezmoi' first."; \
		exit 1; \
	fi

chezmoi-update: ## Pull latest changes and apply
	@if command -v chezmoi > /dev/null 2>&1; then \
		echo "→ Updating dotfiles..."; \
		chezmoi update --apply; \
		echo "✓ Dotfiles updated"; \
	else \
		echo "⚠ chezmoi not installed. Run 'make install' first."; \
		exit 1; \
	fi

# =============================================================================
# Docker Testing
# =============================================================================

$(BIN_DIR)/chezmoi: ## Install chezmoi to BIN_DIR
	@echo "→ Installing chezmoi..."
	@mkdir -p $(BIN_DIR)
	@sh -c "$$(curl -fsLS get.chezmoi.io)" -- -b "$(BIN_DIR)"
	@echo "✓ chezmoi installed to $(BIN_DIR)/chezmoi"

$(BIN_DIR)/mise: ## Install mise to BIN_DIR
	@echo "→ Installing mise..."
	@mkdir -p $(BIN_DIR)
	@curl https://mise.run | sh
	@echo "✓ mise installed to $(BIN_DIR)/mise"

core: $(BIN_DIR)/chezmoi $(BIN_DIR)/mise ## Install chezmoi, mise, and gh
	@echo "→ Setting up PATH and mise activation..."
	@if ! grep -q 'export PATH="$$HOME/.local/bin:$$PATH"' "$$HOME/.bashrc" 2>/dev/null; then \
		echo 'export PATH="$$HOME/.local/bin:$$PATH"' >> "$$HOME/.bashrc"; \
	fi
	@if ! grep -q 'eval "$$(mise activate bash)"' "$$HOME/.bashrc" 2>/dev/null; then \
		echo 'eval "$$(mise activate bash)"' >> "$$HOME/.bashrc"; \
	fi
	@echo "→ Installing go and gh via mise..."
	@export PATH="$(BIN_DIR):$$PATH"; \
	cd $(DOTFILES_DIR) && mise install go gh
	@echo "✓ Core tools installed (chezmoi, mise, go, gh)"
	@echo ""
	@echo "⚠ Please restart your shell or run:"
	@echo "  source ~/.bashrc"
	@echo ""
	@echo "Then continue with: make system-deps"

system-deps: $(BIN_DIR)/chezmoi ## Install system dependencies via chezmoi script
	@echo "→ Running chezmoi scripts to install system packages..."
	@export PATH="$(BIN_DIR):$$PATH"; \
	echo "  Syncing dotfiles to chezmoi source directory..."; \
	rm -rf "$$HOME/.local/share/chezmoi"; \
	mkdir -p "$$HOME/.local/share"; \
	cp -r $(DOTFILES_DIR) "$$HOME/.local/share/chezmoi"; \
	chezmoi init; \
	if [ -f "$$HOME/.config/chezmoi/chezmoistate.boltdb" ]; then \
		echo "  Resetting script state to run install script..."; \
		chezmoi state delete-bucket --bucket=entryState || true; \
		chezmoi state delete-bucket --bucket=scriptState || true; \
	fi; \
	chezmoi apply
	@echo "  Note: This runs .chezmoiscripts/run_once_before_install-packages.sh"
	@echo "✓ System dependencies check complete"

setup-github: ## Setup GitHub CLI authentication and export token
	@echo "→ Setting up GitHub CLI..."
	@if command -v gh > /dev/null 2>&1; then \
		if gh auth status > /dev/null 2>&1; then \
			echo "✓ Already authenticated with GitHub"; \
		else \
			echo "  Please authenticate with GitHub:"; \
			gh auth login; \
			echo "✓ GitHub CLI authenticated"; \
		fi; \
		echo ""; \
		echo "To avoid GitHub API rate limits, run:"; \
		echo '  export GITHUB_TOKEN="$$(gh auth token)"'; \
		echo '  export AQUA_GITHUB_TOKEN="$$GITHUB_TOKEN"'; \
	else \
		echo "⚠ gh not found. Run 'make core' first"; \
		exit 1; \
	fi

tools: $(BIN_DIR)/mise ## Install all tools via mise
	@echo "→ Installing all tools via mise..."
	@echo "  This may take 10-20 minutes..."
	@export PATH="$(BIN_DIR):$$PATH"; \
	cd $(DOTFILES_DIR) && mise install
	@echo "✓ All tools installed"

apply: $(BIN_DIR)/chezmoi ## Apply dotfiles configuration
	@echo "→ Applying dotfiles..."
	@export PATH="$(BIN_DIR):$$PATH"; \
	chezmoi init --apply --source="$(DOTFILES_DIR)"
	@echo "✓ Dotfiles applied"

fish: ## Set fish as default shell
	@FISH_PATH=$$(which fish); \
	if [ -z "$$FISH_PATH" ]; then \
		echo "⚠ fish not found. Run 'make system-deps' first"; \
		exit 1; \
	fi; \
	if [ "$$(uname -s)" = "Darwin" ]; then \
		if ! grep -q "$$FISH_PATH" /etc/shells; then \
			echo "→ Adding fish to /etc/shells..."; \
			echo "$$FISH_PATH" | sudo tee -a /etc/shells > /dev/null; \
		fi; \
	fi; \
	if [ "$$SHELL" != "$$FISH_PATH" ]; then \
		echo "→ Setting fish as default shell..."; \
		chsh -s "$$FISH_PATH"; \
		echo "✓ fish is now the default shell"; \
		echo "  Please restart your terminal or run: exec fish"; \
	else \
		echo "✓ fish is already the default shell"; \
	fi

apply-gnome: ## Apply GNOME dconf settings (Linux only)
	@if [ "$$(uname -s)" = "Linux" ] && command -v dconf > /dev/null 2>&1; then \
		echo "→ Applying GNOME settings..."; \
		dconf load / < $(DOTFILES_DIR)/dot_config/gnome/dconf-settings.ini; \
		echo "✓ GNOME settings applied"; \
		echo "⚠ Note: GNOME extensions need to be installed manually"; \
	elif [ "$$(uname -s)" = "Linux" ]; then \
		echo "⚠ dconf command not found. Skipping GNOME settings."; \
	else \
		echo "⚠ GNOME settings are only applicable on Linux"; \
	fi

# =============================================================================
# Nix Installation Targets
# =============================================================================

nix-install: ## Install Nix package manager
	@if command -v nix > /dev/null 2>&1; then \
		echo "✓ Nix is already installed"; \
		nix --version; \
	else \
		echo "→ Installing Nix..."; \
		if [ "$$(uname -s)" = "Darwin" ]; then \
			echo "  Installing in multi-user mode (macOS)"; \
			curl -L https://nixos.org/nix/install | sh; \
		else \
			echo "  Installing in multi-user mode (Linux)"; \
			curl -L https://nixos.org/nix/install | sh -s -- --daemon; \
		fi; \
		echo ""; \
		echo "✓ Nix installed successfully"; \
		echo ""; \
		echo "⚠ Please restart your shell or run:"; \
		echo "  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"; \
		echo ""; \
		echo "Then run: make nix-setup"; \
	fi

nix-setup: ## Setup Nix with flakes and home-manager (run after nix-install)
	@if command -v nix > /dev/null 2>&1; then \
		: ; \
	elif [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then \
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh; \
	else \
		echo "⚠ Nix not found. Run 'make nix-install' first."; \
		exit 1; \
	fi; \
	echo "→ Enabling flakes and nix-command..."; \
	mkdir -p ~/.config/nix; \
	if ! grep -q "experimental-features" ~/.config/nix/nix.conf 2>/dev/null; then \
		echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf; \
		echo "✓ Flakes enabled"; \
	else \
		echo "✓ Flakes already enabled"; \
	fi; \
	echo ""; \
	echo "→ Installing home-manager..."; \
	nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager; \
	nix-channel --update; \
	nix-shell '<home-manager>' -A install || true; \
	echo "✓ home-manager installed"; \
	echo ""; \
	echo "✓ Nix setup complete"; \
	echo ""; \
	echo "Available nix commands:"; \
	echo "  make nix-fonts    Install fonts"; \
	echo "  make nix-gnome    Apply GNOME settings (Linux)"; \
	echo "  make nix-mac      Apply macOS settings"; \
	echo ""; \
	echo "Or run home-manager directly:"; \
	echo "  cd nix && nix run home-manager -- switch --flake .#terassyi@dev"

nix: nix-install ## Install and setup Nix (all-in-one)
	@$(MAKE) nix-setup
	@echo ""
	@echo "✓ Nix installation and setup complete"

nix-apply: ## Apply nix home-manager configuration (TARGET=<name>)
	@if command -v nix > /dev/null 2>&1; then \
		echo "→ Applying nix home-manager configuration: $(TARGET)"; \
		cd $(DOTFILES_DIR)/nix && \
		nix run home-manager -- switch --flake .#$(TARGET); \
		echo "✓ Configuration applied: $(TARGET)"; \
	elif [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then \
		. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && \
		echo "→ Applying nix home-manager configuration: $(TARGET)" && \
		cd $(DOTFILES_DIR)/nix && \
		nix run home-manager -- switch --flake .#$(TARGET) && \
		echo "✓ Configuration applied: $(TARGET)"; \
	elif [ -f ~/.nix-profile/etc/profile.d/nix.sh ]; then \
		. ~/.nix-profile/etc/profile.d/nix.sh && \
		echo "→ Applying nix home-manager configuration: $(TARGET)" && \
		cd $(DOTFILES_DIR)/nix && \
		nix run home-manager -- switch --flake .#$(TARGET) && \
		echo "✓ Configuration applied: $(TARGET)"; \
	else \
		echo "⚠ nix not found. Run 'make nix' first."; \
		exit 1; \
	fi

bootstrap: install ## Alias for install (legacy compatibility)

build: ## Build the test Docker image
	docker build -t $(IMAGE_NAME) .

rebuild: ## Rebuild the test Docker image without cache
	docker build --no-cache -t $(IMAGE_NAME) .

test: build ## Run automated tests in Docker
	@echo "Running automated tests..."
	@if [ -n "$$GITHUB_TOKEN" ]; then \
		docker run --rm --name $(CONTAINER_NAME) --hostname dev \
			-e GITHUB_TOKEN="$$GITHUB_TOKEN" \
			-e AQUA_GITHUB_TOKEN="$$GITHUB_TOKEN" \
			$(IMAGE_NAME) /bin/bash -c "\
				cd /home/terassyi/dotfiles && \
				make install && \
				mise doctor && \
				chezmoi verify"; \
	else \
		docker run --rm --name $(CONTAINER_NAME) --hostname dev $(IMAGE_NAME) /bin/bash -c "\
			cd /home/terassyi/dotfiles && \
			make install && \
			mise doctor && \
			chezmoi verify"; \
	fi

test-interactive: build ## Start an interactive test environment
	@echo "Starting interactive test environment..."
	@echo "Run 'make install' to test the setup"
	@if [ -n "$$GITHUB_TOKEN" ]; then \
		echo "→ Using GITHUB_TOKEN for API authentication"; \
		docker run -it --rm --name $(CONTAINER_NAME) --hostname dev \
			-v $(DOTFILES_DIR):/home/terassyi/dotfiles \
			-e GITHUB_TOKEN="$$GITHUB_TOKEN" \
			-e AQUA_GITHUB_TOKEN="$$GITHUB_TOKEN" \
			$(IMAGE_NAME) /bin/bash; \
	else \
		echo "⚠ No GITHUB_TOKEN set. API rate limit may be reached."; \
		echo "  Set GITHUB_TOKEN to avoid rate limiting:"; \
		echo "  export GITHUB_TOKEN=your_token"; \
		docker run -it --rm --name $(CONTAINER_NAME) --hostname dev \
			-v $(DOTFILES_DIR):/home/terassyi/dotfiles \
			$(IMAGE_NAME) /bin/bash; \
	fi

test-fish: build ## Test fish shell configuration
	@echo "Testing fish shell configuration..."
	docker run --rm --name $(CONTAINER_NAME) --hostname dev $(IMAGE_NAME) /bin/bash -c "\
		cd /home/terassyi/dotfiles && \
		make install && \
		fish --version && \
		fish -n ~/.config/fish/config.fish"

clean: ## Clean up Docker containers and images
	docker rmi $(IMAGE_NAME) || true
	docker rm -f $(CONTAINER_NAME) || true

lint: ## Lint shell scripts
	@echo "Linting shell scripts..."
	shellcheck scripts/*.sh || true

validate: ## Validate configuration files
	@echo "Validating dotfiles configuration..."
	@if command -v chezmoi > /dev/null; then \
		chezmoi init --source=. --dry-run; \
	else \
		echo "chezmoi not installed, skipping validation"; \
	fi
