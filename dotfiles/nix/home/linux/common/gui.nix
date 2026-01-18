{ pkgs, ... }: {

  # =============================================================================
  # Linux GUI Applications
  # =============================================================================
  # GUI applications installed via nix on Linux.
  # These are applications that don't require frequent configuration changes.
  # =============================================================================

  home.packages = with pkgs; [

    # -------------------------------------------------------------------------
    # Communication & Collaboration
    # -------------------------------------------------------------------------
    slack # Team communication
    discord # Community chat
    zoom-us # Video conferencing
    # teams        # Microsoft Teams (use teams-for-linux)

    # -------------------------------------------------------------------------
    # Browsers
    # -------------------------------------------------------------------------
    google-chrome # Chromium-based browser
    firefox # Privacy-focused browser
    # chromium     # Open-source Chromium

    # -------------------------------------------------------------------------
    # Media & Documents
    # -------------------------------------------------------------------------
    # vlc            # Media player
    # spotify      # Music streaming
    # mpv          # Lightweight media player
    # evince       # PDF viewer (GNOME)
    # okular       # PDF viewer (KDE)
    # gimp         # Image editor
    # inkscape     # Vector graphics editor

    # -------------------------------------------------------------------------
    # Screenshot & Screen Recording
    # -------------------------------------------------------------------------
    flameshot # Feature-rich screenshot tool
    # peek           # Simple animated GIF recorder
    # obs-studio   # Screen recording & streaming

    # -------------------------------------------------------------------------
    # Terminals
    # -------------------------------------------------------------------------
    # ghostty        # GPU-accelerated terminal
    # alacritty    # Cross-platform terminal emulator
    # wezterm      # GPU-accelerated terminal with multiplexer
    # kitty        # GPU-accelerated terminal

    # -------------------------------------------------------------------------
    # Launchers & Utilities
    # -------------------------------------------------------------------------
    albert # Application launcher (like macOS Spotlight)
    # rofi         # Window switcher and launcher (GNOME alt+tab alternative)
    # ulauncher    # Application launcher

    # -------------------------------------------------------------------------
    # File Management
    # -------------------------------------------------------------------------
    # nautilus     # GNOME file manager (usually pre-installed)
    # thunar       # Xfce file manager
    # pcmanfm      # Lightweight file manager
    # nemo         # Cinnamon file manager (fork of Nautilus)

    # -------------------------------------------------------------------------
    # System Monitoring & Management
    # -------------------------------------------------------------------------
    # gnome-system-monitor  # GUI system monitor
    # stacer       # System optimizer and monitor
    # gparted # Partition editor

    # -------------------------------------------------------------------------
    # Network & Security
    # -------------------------------------------------------------------------
    wireshark # Network protocol analyzer
    # remmina      # Remote desktop client (RDP, VNC, SSH)

    # -------------------------------------------------------------------------
    # Development Tools
    # -------------------------------------------------------------------------
    # dbeaver-bin  # Universal database tool
    # postman      # API development environment
    # insomnia     # REST/GraphQL client

    # -------------------------------------------------------------------------
    # Virtualization
    # -------------------------------------------------------------------------
    virt-manager # Virtual machine manager (for KVM/QEMU)

    # -------------------------------------------------------------------------
    # Office & Productivity
    # -------------------------------------------------------------------------
    # libreoffice  # Office suite
    # obsidian     # Knowledge base / Note taking

  ];

}
