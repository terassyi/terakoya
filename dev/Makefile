SUDO := sudo
MIRROR := http://ftp.riken.go.jp/Linux/ubuntu/
BIN_DIR := scripts
WORK_DIR := ~/workspace

GO_BGP := 3.8.0

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
	git clone https://github.com/zplug/zplug ~/.zplug || true
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
	curl -sSLf https://github.com/osrg/gobgp/releases/download/v${GO_BGP}/gobgp_${GO_BGP}_linux_amd64.tar.gz | ${SUDO} tar -C /usr/local/bin -xzf -
	${SUDO} chmod +x /usr/local/bin/gobgp
	${SUDO} chmod +x /usr/local/bin/gobgpd
	git clone https://github.com/tinynetwork/tinet ${WORK_DIR}/tinet && cd ${WORK_DIR}/tinet || true
	docker run --rm -i -t -v ${WORK_DIR}/tinet:/v -w /v golang:1.19 go build
	${SUDO} mv ${WORK_DIR}/tinet/tinet /usr/local/bin

.PHONY: setup-grpc
setup-grpc:
	${SUDO} apt install -y protobuf-compiler libprotobuf-dev
	go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
