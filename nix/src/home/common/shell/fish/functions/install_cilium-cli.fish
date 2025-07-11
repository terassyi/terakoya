function install_cilium-cli -d 'install_cilium-cli <version>'
    # set ver (gh_release cilium cilium-cli latest)
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
    set tarball "cilium-$os-$arch.tar.gz"
    # https://github.com/cilium/cilium-cli/releases/download/v0.18.5/cilium-linux-amd64.tar.gz
    set url "https://github.com/cilium/cilium-cli/releases/download/v$ver/$tarball"

    echo "Downloading cilium-cli($ver) from $url"
    curl -Lo $tarball $url
    if test $status -ne 0
        echo "Failed to download files."
        return 1
    end

    echo "Removing any existing cilium-cli"
    rm -rf $HOME/tools/bin/cilium

    echo "Exstracting $tarball to ~/tools/bin"
    mkdir -p $HOME/tools/bin
    tar -C $HOME/tools/bin -xzf $tarball
    rm $tarball

    echo "Creating symlink"
    sudo ln -s $HOME/tools/bin/cilium /usr/local/bin/

    echo "Updating .versions.json"
    tools_version_update cilium cilium cilium-cli $ver $HOME/tools/bin/cilium

    cilium version
end
