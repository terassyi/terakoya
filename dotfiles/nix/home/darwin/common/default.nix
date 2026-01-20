{ config, pkgs, lib, userConfig, ... }: {

  imports = if userConfig.gui == "mac" then [ ./gui.nix ] else [ ];

  # =============================================================================
  # macOS Specific Home-Manager Settings
  # =============================================================================
  # This module configures macOS system preferences using home-manager's
  # targets.darwin.defaults feature.
  #
  # These settings are applied via the `defaults` command and modify the
  # macOS preferences database (~/.Library/Preferences/).
  #
  # To apply changes manually:
  #   home-manager switch --flake .#terashima@darwin1
  #
  # After applying, some apps (Dock, Finder) will be restarted automatically.
  # =============================================================================

  targets.darwin.defaults = {

    # ===========================================================================
    # NSGlobalDomain - System-wide Settings
    # ===========================================================================
    # These settings apply globally across all applications.
    # Equivalent to: defaults write NSGlobalDomain <key> <value>
    # ===========================================================================
    NSGlobalDomain = {

      # -------------------------------------------------------------------------
      # Keyboard Settings
      # -------------------------------------------------------------------------
      # ApplePressAndHoldEnabled: When false, holding a key repeats it instead
      # of showing the accent character picker (useful for Vim users)
      ApplePressAndHoldEnabled = false;

      # InitialKeyRepeat: Delay before key repeat starts (in 15ms increments)
      # Range: 15-120, Lower = faster. Default is 25 (375ms)
      InitialKeyRepeat = 15; # 225ms delay

      # KeyRepeat: Speed of key repeat (in 15ms increments)
      # Range: 1-15, Lower = faster. Default is 6 (90ms)
      KeyRepeat = 2; # 30ms between repeats

      # -------------------------------------------------------------------------
      # Appearance Settings
      # -------------------------------------------------------------------------
      # AppleInterfaceStyle: "Dark" for dark mode, remove for light mode
      AppleInterfaceStyle = "Dark";

      # AppleShowAllExtensions: Show file extensions in Finder
      AppleShowAllExtensions = true;

      # -------------------------------------------------------------------------
      # Trackpad/Mouse Settings
      # -------------------------------------------------------------------------
      # Natural scrolling: content moves in the direction of finger movement
      # true = natural (iOS-like), false = traditional
      "com.apple.swipescrolldirection" = true;

      # -------------------------------------------------------------------------
      # Text Auto-Correction Settings
      # -------------------------------------------------------------------------
      # Disable all auto-correction features (useful for developers)
      NSAutomaticCapitalizationEnabled = false; # Don't auto-capitalize
      NSAutomaticDashSubstitutionEnabled = false; # Don't replace -- with —
      NSAutomaticPeriodSubstitutionEnabled =
        false; # Don't add period on double-space
      NSAutomaticQuoteSubstitutionEnabled = false; # Don't use smart quotes
      NSAutomaticSpellingCorrectionEnabled =
        false; # Don't auto-correct spelling
    };

    # ===========================================================================
    # Dock Settings
    # ===========================================================================
    # Configure the Dock appearance and behavior.
    # Equivalent to: defaults write com.apple.dock <key> <value>
    # ===========================================================================
    "com.apple.dock" = {
      # Auto-hide the Dock when not in use
      autohide = true;

      # Delay before Dock appears when hovering at screen edge (in seconds)
      # 0.0 = instant appearance
      autohide-delay = 0.0;

      # Animation duration for Dock show/hide (in seconds)
      # Lower = faster animation
      autohide-time-modifier = 0.3;

      # Dock position: "bottom", "left", or "right"
      orientation = "bottom";

      # Don't show recently used applications in the Dock
      show-recents = false;

      # Icon size in pixels (16-128)
      tilesize = 48;

      # Minimize window effect: "genie" or "scale"
      # "scale" is faster and less distracting
      mineffect = "scale";

      # Animate opening applications (bouncing icon)
      launchanim = true;
    };

    # ===========================================================================
    # Finder Settings
    # ===========================================================================
    # Configure Finder appearance and behavior.
    # Equivalent to: defaults write com.apple.finder <key> <value>
    # ===========================================================================
    "com.apple.finder" = {
      # Show hidden files (files starting with .)
      AppleShowAllFiles = true;

      # Show the path bar at the bottom of Finder windows
      ShowPathbar = true;

      # Show the status bar at the bottom of Finder windows
      ShowStatusBar = true;

      # Default view style for new Finder windows:
      # "Nlsv" = List view, "icnv" = Icon view, "clmv" = Column view, "glyv" = Gallery view
      FXPreferredViewStyle = "Nlsv";

      # Default search scope:
      # "SCcf" = Current folder, "SCsp" = Previous scope, "SCev" = Entire Mac
      FXDefaultSearchScope = "SCcf";

      # Don't warn when changing file extensions
      FXEnableExtensionChangeWarning = false;
    };

    # ===========================================================================
    # Screenshot Settings
    # ===========================================================================
    # Configure screenshot behavior.
    # Equivalent to: defaults write com.apple.screencapture <key> <value>
    # ===========================================================================
    "com.apple.screencapture" = {
      # Directory to save screenshots
      location = "~/Pictures/Screenshots";

      # Image format: "png", "jpg", "gif", "pdf", "tiff"
      type = "png";

      # Disable shadow around windows in screenshots
      disable-shadow = true;
    };

    # ===========================================================================
    # Keyboard Shortcuts
    # ===========================================================================
    # Modify system keyboard shortcuts.
    # Use this to disable Spotlight shortcut for Raycast/Alfred.
    # ===========================================================================
    "com.apple.symbolichotkeys" = {
      AppleSymbolicHotKeys = {
        # Shortcut ID 64 = Spotlight search (Cmd+Space)
        # Disable to use Raycast or Alfred instead
        "64" = { enabled = false; };
      };
    };
  };

  # =============================================================================
  # File System Setup
  # =============================================================================
  # Create necessary directories for screenshots
  home.file."Pictures/Screenshots/.keep".text = "";

  # =============================================================================
  # Activation Script
  # =============================================================================
  # Restart affected applications after applying settings.
  # This ensures changes take effect immediately without manual restart.
  # =============================================================================
  home.activation.applyMacOSDefaults =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Restart Dock to apply dock settings
      /usr/bin/killall Dock 2>/dev/null || true

      # Restart Finder to apply finder settings
      /usr/bin/killall Finder 2>/dev/null || true

      # Restart SystemUIServer to apply menu bar settings
      /usr/bin/killall SystemUIServer 2>/dev/null || true
    '';

}
