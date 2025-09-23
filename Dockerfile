FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    # Basic tools
    curl wget git vim nano sudo \
    # SSH server (for dev mode)
    openssh-server \
    # Build tools
    build-essential pkg-config libssl-dev \
    # Redis
    redis-server \
    # Java for Neo4j
    openjdk-17-jre-headless \
    # Process manager
    tini \
    # Network tools for entrypoint detection
    netcat \
    && rm -rf /var/lib/apt/lists/*

# Install Neo4j at build time for faster startup
RUN wget -O- https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor | tee /usr/share/keyrings/neo4j.gpg >/dev/null \
    && echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable latest" > /etc/apt/sources.list.d/neo4j.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y neo4j \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Node.js and Claude CLI (for dev mode)
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g @anthropic-ai/claude-code \
    && rm -rf /var/lib/apt/lists/*

# Create dev user
RUN useradd -m -s /bin/bash -G sudo devuser \
    && echo "devuser:devpass" | chpasswd \
    && echo "devuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup SSH
RUN mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && mkdir -p /home/devuser/.ssh \
    && chown -R devuser:devuser /home/devuser/.ssh

# Build the demo app
WORKDIR /build
COPY Cargo.toml .
COPY src ./src
RUN cargo build --release \
    && mv target/release/kalisi-demo /usr/local/bin/ \
    && rm -rf /build

# Copy static files
COPY static /app/static

# Copy scripts
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Generate self-signed cert for demo
RUN mkdir -p /certs \
    && openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /certs/key.pem -out /certs/cert.pem \
    -subj "/C=US/ST=Demo/L=Demo/O=KalisiDemo/CN=localhost"

# Data directories
RUN mkdir -p /data/redis /data/neo4j /data/app

# Expose ports
EXPOSE 8443 22

# Use tini as init
ENTRYPOINT ["/usr/bin/tini", "--", "/entrypoint.sh"]