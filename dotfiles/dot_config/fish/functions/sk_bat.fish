function sk_bat
    set file (fd --type=file | sk --prompt="" --header=FILE)
    if test -n "$file"
        commandline -- "bat $file"
        commandline -f repaint
    end
end
