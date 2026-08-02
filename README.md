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

```bash
# 1. Build the image
./build.sh

# 2. Push to the registry
./push.sh

# 3. Deploy to the cluster
./deploy.sh
```

Requires authentication with the container registry. Set `imagePullSecret` in `chart/values.yaml` if the cluster needs pull credentials.

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

The chart reads environment variables from a Kubernetes Secret named `openchamber-secrets` (configurable via `secretName` in values). Create it from `.env`:

```bash
kubectl create secret generic openchamber-secrets \
  --namespace openchamber \
  --from-env-file .env
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
