# OpenCode Server

A self-hosted AI coding environment.

## Setup

```bash
cp .env.example .env
# Edit .env with your API keys and domain
docker compose up -d
```

Open `https://your-domain.com` in your browser.

## Usage

Ask OpenCode to clone repos, write code, commit, and push. Browse files, review diffs, and use the terminal from the web UI.

```bash
# Connect from terminal
opencode attach https://your-domain.com
```

## Docker Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Rebuild after changes
docker compose up -d --build

# Check status
docker compose ps
```
