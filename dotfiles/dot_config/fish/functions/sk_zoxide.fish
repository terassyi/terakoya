function sk_zoxide
    set dir (fd --type=d | sk --prompt="" --header=DIR)
    if test -n "$dir"
        z $dir
    end
end
