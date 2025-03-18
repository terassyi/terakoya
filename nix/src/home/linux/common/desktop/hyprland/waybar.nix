{ ... }: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 5;
        mode = "dock";
        fixed-center = true;
        modules-center = [ "clock" ];
        modules-left = [ "hyprland/workspaces" "cpu" "temperature" "memory" ];
        modules-right =
          [ "hyprland/language" "network" "bluetooth" "pulseaudio" "battery" ];
        battery = {
          interval = 10;
          align = 0;
          rotate = 0;
          full-at = 100;
          design-capacity = false;
          states = {
            good = 80;
            warning = 40;
            critical = 20;
          };
          format = "<big>{icon}</big>  # {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-full = "{icon} Full";
          format-icons = [ "" "" "" "" "" ];
          format-time = "{H}h {M}mim";
          tooltip = true;
          tooltip-format = "{timeTo} {power}w";
        };
        bluetooth = {
          format = "";
          format-connected = " {num_connections}";
          tooltip-format = " {device_alias}";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = ''
            Name: {device_alias}
            Battery: {device_battery_percentage}%'';
          on-click = "blueman-manager";
        };
        clock = {
          format = "{:%b %d %H:%M}";
          format-alt = " {:%H:%M   %Y, %d %B, %A}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
        };
        cpu = {
          format = "󰍛 {usage}%";
          interval = 1;
        };
        "hyprland/language" = { format = "{short}"; };
        memory = {
          interval = 10;
          format = "󰾆 {used:0.1f}G";
          format-alt = "󰾆 {percentage}%";
          format-alt-click = "click";
          tooltip = true;
          tooltip-format = "{used:0.1f}GB/{total:0.1f}G";
          on-click-right = "foot --title btop sh -c 'btop'";
        };
        network = {
          format = "{ifname}";
          format-wifi = "ᯤ {essid} {signalStrength}%";
          format-ethernet = "🌐 {ifname}";
          format-disconnected = "Disconnected";
          tooltip-format = "{ifname}";
          tooltip-format-wifi =
            "ᯤ {essid} {signalStrength}% Up={bandwidthUpBits} Down={bandwidthDownBits} {frequency} MHz";
          tooltip-format-ethernet =
            "🌐 {ifname} Up={bandwidthUpBits} bps Down={bandwidthDownBits} bps";
          tooltip-format-disconnected = "Disconnected";
          on-click = "nm-connection-editor";
        };
        "hyprland/workspaces" = {
          all-outputs = true;
          format = "{name}";
          on-click = "activate";
          show-special = false;
          sort-by-number = true;
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "";
          format-icons = { default = [ "" "" " " ]; };
        };
        temperature = {
          interval = 10;
          tooltip = false;
          hwmon-path = "/sys/class/hwmon/hwmon1/temp1_input";
          critical-threshold = 60;
          format-critical = "{icon} {temperatureC}°C";
          format = "󰈸 {temperatureC}°C";
        };
      };
    };
    style = ''
      * {
        font-family: "NotoMono Nerd Font";
        font-weight: bold;
        min-height: 0;
        font-size: 100%;
        font-feature-settings: '"zero", "ss01", "ss02", "ss03", "ss04", "ss05", "cv31"';
        padding: 0px;
        margin-top: 1px;
        margin-bottom: 1px;
        margin-right: 1px;
        margin-left: 1px;
      }

      window#waybar {
        background: rgba(0, 0, 0, 0);
      }

      window#waybar.hidden {
        opacity: 0.8;
      }

      tooltip {
        background: #1e1e2e;
        border-radius: 8px;
      }

      tooltip label {
        color: #cad3f5;
        margin-right: 5px;
        margin-left: 5px;
      }

      .modules-right,
      .modules-center,
      .modules-left {
        background-color: rgba(0, 0, 0, 0.6);
        border: 0px solid #b4befe;
        border-radius: 8px;
      }

      #workspaces button {
        padding: 2px;
        color: #6e6a86;
        margin-right: 5px;
      }

      #workspaces button.active {
        color: #dfdfdf;
        border-radius: 3px 3px 3px 3px;
      }

      #workspaces button.focused {
        color: #d8dee9;
      }

      #workspaces button.urgent {
        color: #ed8796;
        border-radius: 8px;
      }

      #workspaces button:hover {
        color: #000000;
        border-radius: 3px;
      }

      #backlight,
      #battery,
      #bluetooth,
      #clock,
      #cpu,
      #language,
      #memory,
      #network,
      #tray,
      #pulseaudio,
      #temperature,
      #workspaces {
        color: #dfdfdf;
        padding: 0px 10px;
        border-radius: 8px;
      }

      #temperature.critical {
        background-color: #ff0000;
        opacity: 0.8;
      }

      @keyframes blink {
        to {
          color: #000000;
        }
      }

      #taskbar button.active {
        background-color: #001e43;
      }

      #battery.critical:not(.charging) {
        color: #f53c3c;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
        opacity: 0.8;
      }
    '';

  };
}
