# https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file#in-a-container
FROM ubuntu:24.04

ARG USER=terassyi
ARG UID=1000
ARG GID=$UID

# https://nixos.org/download/
ARG NIX_VERSION=2.26.1
ARG NIXPKGS_VERSION=24.05
ARG NIX_INSTALLER=https://releases.nixos.org/nix/nix-${NIX_VERSION}/install
ARG NIX_CHANNEL=https://github.com/NixOS/nixpkgs/archive/refs/tags/${NIXPKGS_VERSION}.tar.gz

SHELL ["bin/bash", "-c"]

RUN apt update && \
	apt install -y git \
  curl \
  sudo \
  xz-utils

RUN useradd $USER -m -s /bin/bash && \
  usermod --append --groups sudo $USER --shell /bin/bash && \
  usermod --append --groups root $USER --shell /bin/bash && \
  sed --in-place 's/%sudo.*ALL/%sudo   ALL=(ALL:ALL) NOPASSWD:ALL/' /etc/sudoers

RUN mkdir --parents /etc/nix/ && \
  echo "sandbox = relaxed" >> /etc/nix/nix.conf && \
  echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \    
  echo "cores = 32" >> /etc/nix/nix.conf && \
  echo "allow-import-from-derivation = true" >> /etc/nix/nix.conf && \
  echo "narinfo-cache-negative-ttl = 30" >> /etc/nix/nix.conf  && \
  echo "trusted-users = root vscode actions-runner" >> /etc/nix/nix.conf  && \
  echo "substitute = true" >> /etc/nix/nix.conf  && \
  echo "substituters = https://nix-community.cachix.org/ https://cache.nixos.org/ https://composable.cachix.org/ https://devenv.cachix.org/ https://cosmos.cachix.org https://nixpkgs-update.cachix.org" >> /etc/nix/nix.conf  && \
  echo "require-sigs = false" >> /etc/nix/nix.conf  && \
  echo "trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= cosmos.cachix.org-1:T5U9yg6u2kM48qAOXHO/ayhO8IWFnv0LOhNcq0yKuR8= cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= composable.cachix.org-1:J2TVJKH4U8xqYdN/0SpauoAxLuDYeheJtv22Vn3Hav8= nixpkgs-update.cachix.org-1:6y6Z2JdoL3APdu6/+Iy8eZX2ajf09e4EE9SnxSML1W8= devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" >> /etc/nix/nix.conf  && \
  echo "trusted-substituters = https://nix-community.cachix.org/ https://cache.nixos.org/ https://composable.cachix.org/ https://devenv.cachix.org/ https://cosmos.cachix.org https://nixpkgs-update.cachix.org/" >> /etc/nix/nix.conf  && \
  passwd --delete root

USER ${USER}
ENV USER=${USER}

# RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux \
#   --extra-conf "sandbox = false" \
#   --init none \
#   --no-confirm

RUN curl --location ${NIX_INSTALLER} > ~/install.sh && \
  chmod +x ~/install.sh  && \
  ~/install.sh

RUN source ~/.nix-profile/etc/profile.d/nix.sh && \
  nix-channel --add ${NIX_CHANNEL} nixpkgs && \
  nix-channel --update && \
  nix profile install nixpkgs#nil && \
  nix profile install nixpkgs#nixfmt

RUN echo "source ~/.nix-profile/etc/profile.d/nix.sh" >> ~/.profile && \
  echo "source ~/.nix-profile/etc/profile.d/nix.sh" >> ~/.bashrc

ENV PATH="${PATH}:$HOME/.nix-profile/bin"

WORKDIR /home/${USER}/terakoya
