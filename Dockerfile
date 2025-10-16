FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ffmpeg \
    unzip \
    git \
    ca-certificates \
    jq \
 && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://rclone.org/install.sh | bash

WORKDIR /workspace
ENTRYPOINT ["/bin/bash"]
