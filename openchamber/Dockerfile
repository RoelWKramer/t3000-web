FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl jq ripgrep openssh-client ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
      | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" \
      > /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update && apt-get install -y --no-install-recommends kubectl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

RUN npm install -g opencode-ai @openchamber/web@1.18.1

RUN userdel node && useradd -m -d /home/openchamber -s /bin/bash -u 1000 openchamber
RUN mkdir -p /home/openchamber/.config/opencode \
    /home/openchamber/.config/openchamber \
    /home/openchamber/.local/share/opencode \
    /home/openchamber/.cache/helm \
    /home/openchamber/.config/helm \
    && chown -R openchamber:openchamber /home/openchamber

COPY skills/ /home/openchamber/.config/opencode/skills/
COPY tools/ /opt/opencode/tools/
COPY charts/ /opt/opencode/charts/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /opt/opencode/tools/*.sh \
    && chown -R openchamber:openchamber /home/openchamber/.config/opencode/skills /opt/opencode

USER openchamber
WORKDIR /home/openchamber

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
