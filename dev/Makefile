SUDO := sudo
MIRROR := http://ftp.riken.go.jp/Linux/ubuntu/
BIN_DIR := scripts
WORK_DIR := ~/workspace

.PHONY: setup-basic-tools
setup-basic-tools:
	${SUDO} apt update -y 
	${SUDO} apt install -y curl build-essential cmake

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
	cp dotfiles/.tmux.conf ${CURDIR}/${SHELL_NAME}/dotfiles/
	sed -i -e "s/SHELL_NAME/${SHELL_NAME}/g" ${CURDIR}/${SHELL_NAME}/dotfiles/.tmux.conf
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
	
.PHONY: setup-zsh
setup-zsh:
	${SUDO} apt install -y zsh peco
	${SUDO} chsh -s /bin/zsh
	mkdir -p ~/.zplug
	git clone https://github.com/zplug/zplug ~/.zplug
	ln -snfv ${CURDIR}/dotfiles/.zshrc ~/

.PHONY: setup-starship
setup-starship:
	cargo install starship --locked
	mkdir -p ~/.config
	ln -snfv ${CURDIR}/dotfiles/.config/starship.toml ~/.config

.PHONY: setup-dev-routing
setup-dev-routing: setup-grpc
	mkdir -p ${WORK_DIR}
	${SUDO} apt install -y frr
	go install github.com/osrg/gobgp/gobgpd@latest
	git clone https://github.com/tinynetwork/tinet ${WORK_DIR}/tinet && cd ${WORK_DIR}/tinet
	docker run --rm -i -t -v ${CURDIR}:/v -w /v golang:1.12 go build
	${SUDO} mv tinet /usr/local/bin

.PHONY: setup-grpc
setup-grpc:
	${SUDO} apt install -y protobuf-compiler libprotobuf-dev
	go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
