# OpenCode Server

A self-hosted AI coding environment.

## Usage

Ask OpenCode to clone repos, write code, commit, and push. Browse files, review diffs, and use the terminal from the web UI.

```bash
# Connect from terminal
opencode attach https://your-domain.com
```

## Kubernetes Deployment

A Helm chart is available at `chart/` to deploy on Kubernetes.

```bash
# Create secret from your .env file
kubectl create secret generic openchamber-secrets \
  --namespace openchamber \
  --from-env-file .env

# Install the chart
helm upgrade --install openchamber ./chart \
  --namespace openchamber \
  --create-namespace

# Expose the service (pick one)
# Option A: Port-forward for testing
kubectl port-forward --namespace openchamber svc/openchamber 3000:3000

# Option B: Create an ingress
# (you'll need an ingress controller + TLS cert for your domain)
```

### Remote Cluster Deployment

Prerequisites (set up by lifecycle 3 / infra team):
- `openchamber` namespace exists on the cluster
- `scw-registry` docker-registry secret is present in the namespace

```bash
# 1. Build the image
./build.sh

# 2. Push to the registry
./push.sh

# 3. Deploy to the cluster
./deploy.sh
```

The deploy script creates app secrets from `.env`, then installs the Helm chart with `imagePullSecret=scw-registry`.

### Local Development (skip remote registry)

Make sure you have a k3d cluster first:

```bash
k3d cluster create t3000
```

Then build and deploy with a local image:

```bash
# 1. Build the image locally
./build_local.sh

# 2. Deploy without pulling from a remote registry
./deploy_local.sh
```

### Configuration

Override any value with `--set`:

```bash
helm upgrade --install openchamber ./chart \
  --namespace openchamber \
  --set image.tag=v1.2.3 \
  --set persistence.size=5Gi
```

See `chart/values.yaml` for all available options.

### Secret

The chart reads environment variables from a Kubernetes Secret named `openchamber-secrets` (configurable via `secretName` in values). The `deploy.sh` script creates it automatically from `.env`. To create it manually:

```bash
kubectl create secret generic openchamber-secrets \
  --namespace openchamber \
  --from-env-file .env
```

For remote clusters, a `scw-registry` docker-registry pull secret must also exist in the namespace (created by lifecycle 3 / `t3000-infra/k8s/bootstrap/bootstrap.sh`). The chart references it via `imagePullSecret: scw-registry`.

## Container Design

The container uses a **system-vs-user config layering** pattern.

### Persistent home directory

`/home/openchamber` is mounted via a Kubernetes PersistentVolume so user data — git config, shell history, helm repos, personal OpenCode skills — survives pod restarts. Build-time files written there are hidden by the mount.

### System files (read-only, baked into image)

| Path | Contents |
|---|---|
| `/opt/opencode/skills/` | Pre-installed OpenCode skills |
| `/opt/opencode/tools/` | Shell tools (deploy-app.sh, etc.) |
| `/opt/opencode/charts/` | Helm charts |
| `/etc/opencode/skills-config.json` | OpenCode config that wires skills.paths |

OpenCode discovers both system and user skills — system via `OPENCODE_CONFIG` pointing to `/etc/opencode/skills-config.json`, and user skills automatically from `~/.config/opencode/skills/`.

### Rule

**Never copy files to `/home/openchamber/` in the Dockerfile.** They'll be invisible at runtime. Use `/opt/opencode/` for system files and `/etc/opencode/` for config.

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
