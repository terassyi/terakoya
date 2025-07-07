function install_containerlab -d 'install_containerlab <version>'
    # set ver (gh_release srl-labs containerlab latest)
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
    set tarball "containerlab_"$ver"_"$os"_"$arch".tar.gz"
    # https://github.com/srl-labs/containerlab/releases/download/v0.68.0/containerlab_0.68.0_linux_amd64.tar.gz
    set url "https://github.com/srl-labs/containerlab/releases/download/v$ver/$tarball"

    echo "Downloading containerlab($ver) from $url"
    curl -Lo $tarball $url
    if test $status -ne 0
        echo "Failed to download files."
        return 1
    end

    echo "Removing any existing containerlab"
    rm -rf $HOME/tools/bin/containerlab

    echo "Exstracting $tarball to ~/tools/bin"
    mkdir -p $HOME/tools/bin
    tar -C $HOME/tools/bin -xzf $tarball
    rm $tarball

    echo "Creating symlink"
    sudo ln -s $HOME/tools/bin/containerlab /usr/local/bin/

    echo "Updating .versions.json"
    tools_version_update containerlab srl-labs containerlab $ver $HOME/tools/bin/containerlab

    containerlab version
end
