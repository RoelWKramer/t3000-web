FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl jq ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai @openchamber/web

RUN useradd -m -d /home/openchamber -s /bin/bash openchamber
RUN mkdir -p /home/openchamber/.config/opencode /home/openchamber/.local/share/opencode /workspace

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER openchamber
WORKDIR /home/openchamber

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
