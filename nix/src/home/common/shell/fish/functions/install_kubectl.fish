function install_kubectl -d 'install_kubectl <version>'
    set ver (gh_release kubernetes kubernetes latest)
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
    set url "https://dl.k8s.io/release/v$ver/bin/$os/$arch/kubectl"

    echo "Downloading kubectl($ver) from $url"
    curl -LO $url
    if test $status -ne 0
        echo "Failed to download files."
        return 1
    end

    echo "Removing any existing kubectl"
    rm -rf $HOME/tools/bin/kubectl

    echo "Moving new kubectl to path"
    mkdir -p $HOME/tools/bin
    chmod +x kubectl
    mv kubectl $HOME/tools/bin/kubectl

    echo "Creating symlink"
    sudo ln -s $HOME/tools/bin/kubectl /usr/local/bin/

    echo "Updating .versions.json"
    tools_version_update kubectl kubernetes kubernetes $ver $HOME/tools/bin/kubectl

    kubectl version
end
