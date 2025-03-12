function install_kind -d 'install_kind <version>'
    # set ver (gh_release kubernetes-sigs kind latest)
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
    set tarball "$ver.$os-$arch.tar.gz"
    set url "https://kind.sigs.k8s.io/dl/v$ver/kind-$os-$arch"

    echo "Downloading kind($ver) from $url"
    curl -Lo kind $url
    if test $status -ne 0
        echo "Failed to download files."
        return 1
    end

    echo "Removing any existing kind"
    rm -rf $HOME/tools/bin/kind

    echo "Moving new kubectl to path"
    mkdir -p $HOME/tools/bin
    chmod +x kind
    mv kind $HOME/tools/bin/kind

    echo "Creating symlink"
    sudo ln -s $HOME/tools/bin/kind /usr/local/bin/

    echo "Updating .versions.json"
    tools_version_update kind kubernetes-sigs kind $ver $HOME/tools/bin/kind

    kind --version
end
