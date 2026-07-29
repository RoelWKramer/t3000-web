FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl jq ripgrep openssh-client ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g opencode-ai @openchamber/web

RUN useradd -m -d /home/openchamber -s /bin/bash openchamber
RUN mkdir -p /home/openchamber/.config/opencode \
    /home/openchamber/.config/openchamber \
    /home/openchamber/.local/share/opencode \
    && chown -R openchamber:openchamber /home/openchamber

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER openchamber
WORKDIR /home/openchamber

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
