{ userConfig, ... }: {
  programs.hyprlock = {
    enable = true;
    settings = {
      background = {
        path = "/home/${userConfig.name}/.config/wallpapers/interstellar.jpg";
        blur_passes = 3;
        contrast = 0.8916;
        brightness = 0.8172;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      };
      general = {
        no_fade_in = false;
        grace = 0;
        disable_loading_bar = true;
      };
      input-field = {
        size = "250, 60";
        outline_thickness = 2;
        dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.2; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = true;
        outer_color = "rgba(0, 0, 0, 0)";
        inner_color = "rgba(0, 0, 0, 0.5)";
        font_color = "rgb(200, 200, 200)";
        fade_on_empty = false;
        capslock_color = -1;
        placeholder_text =
          ''<i><span foreground="##e6e9ef">Password</span></i>'';
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        hide_input = false;
        position = "0, -120";
        halign = "center";
        valign = "center";
      };
      label = [
        # Date
        {
          monitor = "";
          text =
            ''cmd[update:1000] echo "<span>$(LANG=c date '+%b %d %Y')</span>"'';
          color = "rgba(255, 255, 255, 0.8)";
          font_size = 40;
          font_family = "NotoMono Nerd Font";
          position = "0, -400";
          halign = "center";
          valign = "top";
        }
        # Time
        {
          monitor = "";
          text = ''cmd[update:1000] echo "<span>$(date '+%H:%M')</span>"'';
          color = "rgba(255, 255, 255, 0.8)";
          font_size = 120;
          font_family = "NotoMono Nerd Font";
          position = "0, -480";
          halign = "center";
          valign = "top";
        }
      ];
    };
  };
}
