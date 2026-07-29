FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl jq ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai @openchamber/web

RUN useradd -m -d /home/openchamber -s /bin/bash openchamber
USER openchamber
WORKDIR /home/openchamber

EXPOSE 3000

CMD ["openchamber", "serve", "--port", "3000", "--host", "0.0.0.0", "--foreground"]
