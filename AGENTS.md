# Project Structure

Each container in this project has its own directory containing its Dockerfile and related configuration files.

## Directory Layout

```
openchamber/           # OpenChamber web UI + OpenCode AI agent container
├── Dockerfile
├── entrypoint.sh
└── config/
    └── opencode.json
```

## Local Development

For Kubernetes development, **k3d** is used. The cluster is named `t3000`. Use `./build_local.sh` and `./deploy_local.sh` to build and deploy locally.

Never assume or suggest other cluster types (kind, minikube, Docker Desktop, etc.). If the user asks about them, answer the question but don't propose them unprompted.

## Security Rules

**NEVER read or access `.env` directly.** Always use `.env.example` as a reference for environment variable names and structure. The `.env` file contains secrets and should not be read or modified by AI agents.

**NEVER `git commit` or `git push` unless explicitly asked.**

**NEVER have the Dockerfile copy or write files under `/home/openchamber`.** That directory is mounted via a Kubernetes PersistentVolume at runtime, so build-time files are hidden. Use `/opt/opencode/` for system files and `/etc/opencode/` for system config.

## Commit Messages

Keep commit messages short. Format: `<type>: <short description>`

**Types:**
- `feat:` — new feature or capability
- `fix:` — bug fix
- `docs:` — documentation
- `refactor:` — code restructuring (no behavior change)
- `chore:` — maintenance (deps, config, cleanup)
- `build:` — Dockerfile, CI

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
