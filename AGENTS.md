# Project Structure

Each container in this project has its own directory containing its Dockerfile and related configuration files.

## Directory Layout

```
opencode-server/
├── openchamber/           # OpenChamber web UI + OpenCode AI agent container
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── config/
│       └── opencode.json
├── docker-compose.yml     # Orchestrates all services
├── Caddyfile              # Reverse proxy configuration
└── AGENTS.md              # This file
```

## Convention

When adding a new container:
1. Create a directory with the service name (e.g., `newservicename/`)
2. Place the Dockerfile and any related files in that directory
3. Reference it in docker-compose.yml using `build: ./newservicename`

This keeps the project root clean and makes it clear which files belong to which service.

## Security Rules

**NEVER read or access `.env` directly.** Always use `.env.example` as a reference for environment variable names and structure. The `.env` file contains secrets and should not be read or modified by AI agents.
