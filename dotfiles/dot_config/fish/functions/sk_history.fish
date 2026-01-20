function sk_history
    history merge
    set cmd (history -z | sk --read0 --prompt="" --header=QUERY)
    if test -n "$cmd"
        commandline -- $cmd
        commandline -f repaint
    end
end
