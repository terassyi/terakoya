function install_kustomize -d 'install_kustomize <version>'
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
    set url "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v$ver/kustomize_v"$ver"_"$os"_"$arch".tar.gz"

    echo "Downloading kustomize($ver) from $url"
    curl -Lo kustomize.tar.gz $url
    if test $status -ne 0
        echo "Failed to download files."
        return 1
    end

    echo "Removing any existing kustomize"
    rm -rf $HOME/tools/bin/kustomize


    echo "Extracting the binary and moving new kustomize to path"
    mkdir -p $HOME/tools/bin
    tar -xzf kustomize.tar.gz -C $HOME/tools/bin
    rm kustomize.tar.gz

    echo "Creating symlink"
    sudo ln -s $HOME/tools/bin/kustomize /usr/local/bin/

    echo "Updating .versions.json"
    tools_version_update kustomize kubernetes-sigs kustomize $ver $HOME/tools/bin/kustomize

    kustomize version
end
