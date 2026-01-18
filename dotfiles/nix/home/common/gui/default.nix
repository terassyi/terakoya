{ pkgs, userConfig, ... }: {

  # =============================================================================
  # Common GUI Applications (Cross-platform)
  # =============================================================================
  # These are applications installed on all platforms (Linux and macOS).
  # Platform-specific apps are in darwin/common/gui.nix and linux/common/gui.nix
  #
  # Note: These are applications that don't require frequent configuration changes.
  # Editors (VSCode, Neovim) are managed by chezmoi instead.
  # =============================================================================

  home.packages = with pkgs; [

    # -------------------------------------------------------------------------
    # Note: Most GUI apps are platform-specific
    # -------------------------------------------------------------------------
    # Common CLI tools that have GUI components are listed here.
    # Platform-specific GUI apps should go in:
    #   - darwin/common/gui.nix (macOS)
    #   - linux/common/gui.nix (Linux)

  ] ++ (if userConfig.gui == "gnome" then [
    # GNOME-specific applications
    gnome-tweaks     # GNOME customization
    dconf-editor     # dconf GUI editor
  ] else [ ]);

}
