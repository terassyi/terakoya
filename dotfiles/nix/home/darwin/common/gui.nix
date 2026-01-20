{ pkgs, ... }: {

  # =============================================================================
  # macOS GUI Applications
  # =============================================================================
  # GUI applications installed via nix on macOS.
  # These are applications that don't require frequent configuration changes.
  # =============================================================================

  home.packages = with pkgs;
    [

      # -------------------------------------------------------------------------
      # Communication & Collaboration
      # -------------------------------------------------------------------------
      # slack # Team communication
      # discord # Community chat
      # zoom-us # Video conferencing

      # -------------------------------------------------------------------------
      # Browsers
      # -------------------------------------------------------------------------
      # google-chrome # Chromium-based browser
      # firefox      # Privacy-focused browser

      # -------------------------------------------------------------------------
      # Media & Documents
      # vlc            # Media player
      # spotify      # Music streaming

      # -------------------------------------------------------------------------
      # Launchers & Productivity
      # -------------------------------------------------------------------------
      # raycast      # Spotlight replacement with extensions
      # rectangle # Window management with keyboard shortcuts

      # -------------------------------------------------------------------------
      # Development Tools
      # -------------------------------------------------------------------------
      # docker       # Docker Desktop - use rancher-desktop instead
      # colima       # Container runtimes on macOS (Docker/Containerd)
      # rancher # Rancher Desktop - Kubernetes and container management

      # -------------------------------------------------------------------------
      # Terminals
      # -------------------------------------------------------------------------
      # ghostty      # GPU-accelerated terminal (if available in nixpkgs)
      # alacritty    # Cross-platform terminal emulator
      # wezterm      # GPU-accelerated terminal

      # -------------------------------------------------------------------------
      # Cloud & Sync
      # -------------------------------------------------------------------------

    ];

}
