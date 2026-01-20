function sk_code_repo
    set repo (fd --type=d --max-depth 2 . $GH_REPO_HOME | sk --prompt="" --header=REPO)
    if test -n "$repo"
        code $repo
    end
end
