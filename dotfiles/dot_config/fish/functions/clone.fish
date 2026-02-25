function clone -d "clone <owner>/<name>"
    if test (count $argv) -eq 0
        echo "Specify owner/repo"
        return 1
    end
    set p $argv[1]
    if test (count (string split "/" $p)) -ne 2
        echo "Set default owner: terassyi"
        set p "terassyi/$p"
    end

    set full_path "$GH_REPO_HOME/$p"

    echo "Clone repository: $full_path"
    gh repo clone $p $full_path
end
