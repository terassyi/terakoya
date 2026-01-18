# Test environment for dotfiles setup
FROM ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies (fish will be installed by chezmoi script)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    xz-utils \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create a test user
RUN useradd -m -s /bin/bash terassyi && \
    echo "terassyi ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "dev" > /etc/hostname

# Install Nix in multi-user mode (as root)
# The installer will create nixbld group and users automatically
RUN curl -L https://nixos.org/nix/install | sh -s -- --daemon --yes

# Enable flakes and nix-command (system-wide)
RUN mkdir -p /etc/nix && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \
    echo "sandbox = false" >> /etc/nix/nix.conf

# Create entrypoint script that starts nix-daemon with sudo
RUN printf '#!/bin/bash\n\
# Start nix-daemon in background with root privileges\n\
sudo /nix/var/nix/profiles/default/bin/nix-daemon &\n\
\n\
# Wait for daemon to be ready\n\
sleep 1\n\
\n\
# Source nix environment\n\
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh\n\
\n\
# Execute the command passed to the container\n\
exec "$@"\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

# Copy dotfiles into the container
COPY --chown=terassyi:terassyi . /home/terassyi/dotfiles

# Switch to test user
USER terassyi
WORKDIR /home/terassyi/dotfiles

# Set environment for terassyi
ENV HOME=/home/terassyi
ENV PATH="/home/terassyi/.local/bin:/nix/var/nix/profiles/default/bin:${PATH}"
ENV USER=terassyi

# Use entrypoint to start nix-daemon
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
