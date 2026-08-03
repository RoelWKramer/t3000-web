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

## Local Development

For Kubernetes development, **k3d** is used. The cluster is named `t3000`. Use `./build_local.sh` and `./deploy_local.sh` to build and deploy locally.

Never assume or suggest other cluster types (kind, minikube, Docker Desktop, etc.). If the user asks about them, answer the question but don't propose them unprompted.

## Security Rules

**NEVER read or access `.env` directly.** Always use `.env.example` as a reference for environment variable names and structure. The `.env` file contains secrets and should not be read or modified by AI agents.

**NEVER `git push` unless explicitly asked.** You may commit, but never push to a remote without the user requesting it.

## Commit Messages

Keep commit messages short. Format: `<type>: <short description>`

**Types:**
- `feat:` — new feature or capability
- `fix:` — bug fix
- `docs:` — documentation
- `refactor:` — code restructuring (no behavior change)
- `chore:` — maintenance (deps, config, cleanup)
- `build:` — Dockerfile, docker-compose, CI

**Rules:**
- Max 50 characters for the subject line
- Imperative mood ("add" not "added")
- No period at end of subject
- Optional body for complex changes (explain why, not what)

**Examples:**
```
feat: add gh CLI and openssh-client
fix: set terminal workdir to /home/openchamber
docs: add commit conventions to AGENTS.md
build: consolidate to single OpenChamber container
```
