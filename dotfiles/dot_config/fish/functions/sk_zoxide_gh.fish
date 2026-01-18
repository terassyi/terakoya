function sk_zoxide_gh
    set repo (fd --type=d --max-depth 2 . $GH_REPO_HOME | sk --prompt="" --header=REPO)
    if test -n "$repo"
        z $repo
    end
end
