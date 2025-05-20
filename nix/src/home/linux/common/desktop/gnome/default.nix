{ pkgs, lib, userConfig, ... }: {
  home.packages = with pkgs; [
    gnomeExtensions.dash-to-dock
    gnomeExtensions.gtile
    gnomeExtensions.user-themes
    gnomeExtensions.blur-my-shell
    gnomeExtensions.space-bar
    gnomeExtensions.system-monitor
    albert
  ];

  dconf.settings = {
    "org/gnome/shell" = {
      "disable-user-extensions" = false;
      "enabled-extensions" = [
        "dash-to-dock@micxgx.gmail.com"
        "gTile@vibou"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "blur-my-shell@aunetx"
        "space-bar@luchrioh"
        "system-monitor@gnome-shell-extensions.gcampax.github.com"
      ];
      "favorite-apps" = [
        "google-chrome.desktop"
        "com.mitchellh.ghostty.desktop"
        "code.desktop"
        "discord.desktop"
        "slack.desktop"
      ];
    };

    "org/gnome/desktop/interface" = {
      "overlay-scrolling" = false;
      # "cursor-theme" = "Yaru";
      "color-scheme" = "prefer-dark";
      "accent-color" = "teal";
    };
    "org/gnome/desktop/background" = {
      "color-shading-type" = "solid";
      "picture-uri" =
        "file://home/${userConfig.name}/.config/wallpapers/interstellar.jpg";
      "picture-uri-dark" =
        "file://home/${userConfig.name}/.config/wallpapers/interstellar.jpg";
      "primary-color" = "#000000000000";
      "second-color" = "#000000000000";
    };

    "org/gnome/desktop/input-sources" = {
      "current" = lib.gvariant.mkUint32 0;
      "sources" = [
        (lib.gvariant.mkTuple [ "xkb" "us" ])
        (lib.gvariant.mkTuple [ "xkb" "jp" ])
      ];
    };

    "org/gnome/desktop/wm/keybindings" = {
      "switch-input-source" = [ "<Control>space" ];
      "switch-input-source-backward" = [ "<Shift><Control>space" ];
    };

    "org/gnome/desktop/session" = { "idle-delay" = lib.gvariant.mkUint32 600; };

    "org/gnome/mutter" = { "edge-tiling" = true; };

    "org/gnome/shell/extensions/blur-my-shell" = { "settings-version" = 2; };
    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      "pipeline" = "pipeline_default_rounded";
    };
    "org/gnome/shell/extensions/blur-my-shell/lockscreen" = {
      "pipeline" = "pipeline_default";
    };
    "org/gnome/shell/extensions/blur-my-shell/overview" = {
      "pipeline" = "pipeline_default";
    };
    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      "pipeline" = "pipeline_default";
    };
    "org/gnome/shell/extensions/blur-my-shell/screenshot" = {
      "pipeline" = "pipeline_default";
    };

    "org/gnome/shell/extensions/space-bar/appearance" = {
      "inactive-workspace-text-color" = "rgb(154,153,150)";
      "workspace-margin" = 3;
      "workspace-bar-padding" = 3;
    };
    "org/gnome/shell/extensions/space-bar/behavior" = {
      "scroll-wheel" = "panel";
      "show-empty-workspaces" = false;
      "smart-workspace-names" = false;
      "toggle-overview" = false;
    };

    "org/gnome/shell/extensions/dash-to-dock" = {
      "dock-position" = "BOTTOM";
      "extend-height" = false;
      "animate-show-apps" = false;
      "apply-custom-theme" = false;
      # "autohide" = true;
      "background-opacity" = 0.8;
      "dash-max-icon-size" = 32;
      # "dock-fixed" = false;
      "hot-keys" = false;
      # "intellihide" = false;
      "intellihide-mode" = "FOCUS_APPLICATION_WINDOWS";
      "show-trash" = false;
      "transparency-mode" = "DYNAMIC";
    };

    "org/gnome/shell/extensions/gtile" = {
      "grid-rows" = 3;
      "grod-cols" = 3;
      "show-icon-in-panel" = true;
    };

  };

  xdg.configFile."wallpapers" = {
    source = ../wallpapers;
    recursive = true;
  };
}
