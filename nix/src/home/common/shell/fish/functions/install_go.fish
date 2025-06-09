function install_go -d 'install_go <version>'
    # set ver (gh_release golang go latest)
    if test (count $argv) -gt 0
        set ver $argv[1]
    end
    set arch (uname -m)
    if test $arch = aarch64
        set arch arm64
    else if test $arch = x86_64
        set arch amd64
    end
    set os (string lower (uname -s))
    set tarball "go$ver.$os-$arch.tar.gz"
    set url "https://go.dev/dl/$tarball"

    echo "Downloading go($ver) from $url"
    curl -LO $url
    if test $status -ne 0
        echo "Failed to download files."
        return 1
    end

    echo "Removing any existing go from ~/tools/go"
    rm -rf $HOME/tools/go

    echo "Extracting $tarball to ~/tools/go"
    tar -C $HOME/tools -xzf $tarball

    echo "Creating symlink to /usr/local/go"
    sudo ln -s $HOME/tools/go /usr/local/go

    echo "Cleaning up downloaded tarball"
    rm $tarball

    echo "Updating .versions.json"
    tools_version_update go golang go $ver $GOROOT/bin/go
end
