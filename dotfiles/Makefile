IMAGE := dotfiles-test
DOTFILES_DIR := $(shell pwd)

.PHONY: build run test shell clean install

build:
	docker build -t $(IMAGE) .

run:
	docker run --rm -it \
		-v $(DOTFILES_DIR):/home/testuser/dotfiles:ro \
		$(IMAGE) fish

test:
	docker run --rm \
		-v $(DOTFILES_DIR):/home/testuser/dotfiles-src:ro \
		$(IMAGE) bash -c " \
		cp -a /home/testuser/dotfiles-src /home/testuser/dotfiles && \
		chezmoi init --source=/home/testuser/dotfiles --no-tty && \
		chezmoi diff --source=/home/testuser/dotfiles --no-tty || true && \
		tomei validate /home/testuser/dotfiles/dot_config/tomei/ && \
		echo 'All checks passed'"

shell:
	docker run --rm -it \
		-v $(DOTFILES_DIR):/home/testuser/dotfiles:ro \
		$(IMAGE) bash

clean:
	docker rmi -f $(IMAGE)

install:
	chezmoi init --apply --source=$(DOTFILES_DIR)
