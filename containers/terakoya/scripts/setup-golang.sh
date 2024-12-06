#!/bin/bash
set -x
set -e

if [ -z "$GO_VERSION" ]
then
	echo "$GO_VERSION is not specified. Install the default(now v1.23.4) version."
	GO_VERSION=1.23.4
fi
${SUDO} rm -rf /usr/local/go
curl -sSLf https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz | ${SUDO} tar -C /usr/local -xzf -
cat >>${HOME}/.bashrc <<'EOF'
export GOPATH=${HOME}/go
export PATH=/usr/local/go/bin:${GOPATH}/bin:${PATH}
EOF
