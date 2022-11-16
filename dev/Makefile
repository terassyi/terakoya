SUDO := sudo
MIRROR := http://ftp.riken.go.jp/Linux/ubuntu/
BIN_DIR := scripts

.PHONY: setup-basic-tools
setup-basic-tools:
	${SUDO} apt update -y 
	${SUDO} apt install -y curl

.PHONY: setup-golang
setup-golang:
	GO_VERSION=${GO_VERSION} ${BIN_DIR}/setup-golang.sh

.PHONY: setup-rust
setup-rust:
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh 
	source "$$HOME/.cargo/env"
	
.PHONY: setup-docker
setup-docker:
	curl -fsSL https://get.docker.com -o get-docker.sh
	${SUDO} sh get-docker.sh
	${SUDO} adduser ${USER} docker
	
.PHONY: install-dotfiles
install-dotfiles:
	${SUDO} apt install -y tmux
	mkdir -p ${CURDIR}/${SHELL_NAME}/dotfiles
	sed -e "s/SHELL_NAME/${SHELL_NAME}/g" dotfiles/.tmux.conf > ${CURDIR}/${SHELL_NAME}/dotfiles/.tmux.conf
	ln -snfv ${CURDIR}/${SHELL_NAME}/dotfiles/.tmux.conf ~/

.PHONY: setup-bashrc
setup-bashrc:
	mkdir -p ${CURDIR}/bash/dotfiles
	ln -snfv ${CURDIR}/dotfiles/.bashrc ~/

.PHONY: setup-zshrc
setup-zshrc:
	mkdir -p ${CURDIR}/zsh/dotfiles
	ln -snfv ${CURDIR}/dotfiles/.zshrc ~/

.PHONY: setup-vim
setup-vim:
	ln -snfv ${CURDIR}/dotfiles/.vimrc ~/
