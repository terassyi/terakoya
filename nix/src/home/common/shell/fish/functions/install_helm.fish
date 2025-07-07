function install_helm -d 'install_helm <version>'
    set ver (gh_release helm helm latest)
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
    set tarball "helm-v$ver-$os-$arch.tar.gz"
    set extracted_dir $os-$arch
    set url "https://get.helm.sh/$tarball"

    echo "Downloading helm($ver) from $url"
    curl -LO $url
    if test $status -ne 0
        echo "Failed to download files."
        return 1
    end

    echo "Removing any existing helm"
    rm -rf $HOME/tools/bin/helm

    echo "Extracting $tarball to ~/tools/helm"
    tar -xzf $tarball

    echo "Move helm binary"
    mv $extracted_dir/helm $HOME/tools/bin/helm

    echo "Creating symlink to /usr/local/bin/"
    sudo ln -s $HOME/tools/bin/helm /usr/local/bin

    echo "Cleaning up downloaded tarball"
    rm $tarball 
    rm -rf $extracted_dir

    echo "Updating .versions.json"
    tools_version_update helm helm helm $ver $HOME/tools/bin/helm

    helm version
end
