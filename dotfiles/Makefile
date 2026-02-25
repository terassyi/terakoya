IMAGE := dotfiles-test
DOTFILES_DIR := $(shell pwd)

.PHONY: build run test shell clean install

build:
	docker build -t $(IMAGE) .

run:
	docker run --rm -it \
		-v $(DOTFILES_DIR):/home/testuser/dotfiles \
		$(IMAGE) fish

test:
	docker run --rm \
		-v $(DOTFILES_DIR):/home/testuser/dotfiles \
		-e CI=true \
		$(IMAGE) bash -c " \
		chezmoi init --source=/home/testuser/dotfiles --no-tty && \
		chezmoi apply --source=/home/testuser/dotfiles --no-tty && \
		test -f ~/.config/fish/config.fish && \
		echo 'All checks passed'"

shell:
	docker run --rm -it \
		-v $(DOTFILES_DIR):/home/testuser/dotfiles \
		$(IMAGE) bash

clean:
	docker rmi -f $(IMAGE)

install:
	chezmoi init --apply --source=$(DOTFILES_DIR)
