FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git file fish sudo locales \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8

RUN useradd -m -s /usr/bin/fish testuser \
    && echo "testuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# chezmoi
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

# tomei
RUN curl -fsSL https://raw.githubusercontent.com/terassyi/tomei/main/install.sh -o /tmp/install-tomei.sh \
    && TOMEI_INSTALL_DIR=/usr/local/bin sh /tmp/install-tomei.sh \
    && rm /tmp/install-tomei.sh

USER testuser
WORKDIR /home/testuser
ENV LANG=en_US.UTF-8
ENV PATH="/home/testuser/.local/bin:${PATH}"

CMD ["fish"]
