{ ... }: {
  programs.wofi = {
    enable = true;
    settings = {
      allow_images = true;
      insensitive = true;
      normal_window = true;
      prompt = "Search...";
      width = "50%";
      height = "40%";
      key_up = "Ctrl-k";
      key_down = "Ctrl-j";
    };
    # https://github.com/lokesh-krishna/dotfiles/blob/main/tokyo-night/config/wofi/style.css
    style = ''
      window {
        margin: 0px;
        border: 2px solid #414868;
        border-radius: 5px;
        background-color: #24283b;
        font-family: monospace;
        font-size: 12px;
      }

      #input {
        margin: 5px;
        border: 1px solid #24283b;
        color: #c0caf5;
        background-color: #24283b;
      }

      #input image {
      	color: #c0caf5;
      }

      #inner-box {
        margin: 5px;
        border: none;
        background-color: #24283b;
      }

      #outer-box {
        margin: 5px;
        border: none;
        background-color: #24283b;
      }

      #scroll {
        margin: 0px;
        border: none;
      }

      #text {
        margin: 5px;
        border: none;
        color: #c0caf5;
      }

      #entry:selected {
      	background-color: #414868;
      	font-weight: normal;
      }

      #text:selected {
      	background-color: #414868;
      	font-weight: normal;
      }
    '';
  };
}
