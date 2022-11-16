SUDO := sudo
MIRROR := http://ftp.riken.go.jp/Linux/ubuntu/
BIN_DIR := scripts

.PHONY: setup-basic-tools
setup-basic-tools:
	${SUDO} apt update -y 
	${SUDO} apt install -y curl

.PHONY: setup-golang
setup-golang:
	${BIN_DIR}/setup-golang.sh

	