---
name: deploy-app
description: Build and deploy an app to the t3000 Kubernetes cluster. Use ONLY when the user asks to deploy, ship, or push an app to Kubernetes. Handles kaniko build, image push, and Deployment/Service/Ingress creation.
---

# Deploy App

Build and deploy a containerized app to the t3000 cluster using kaniko
(in-cluster build) and Helm charts for runtime resources.

## Prerequisites

- The target Kubernetes namespace must exist and contain:
  - `scw-registry` secret (pull credentials)
  - `scw-registry-push` secret (push credentials)
- A `Dockerfile` must exist in the project directory.

## Usage

```
/opt/opencode/tools/deploy-app.sh [Dockerfile]
```

If no Dockerfile path is given, defaults to `./Dockerfile`.

## Environment variables

| Variable     | Default                          | Description                    |
|-------------|----------------------------------|--------------------------------|
| `NAMESPACE` | `default`                        | Kubernetes namespace           |
| `APP_NAME`  | current directory name           | App name                       |
| `IMAGE_TAG` | `latest`                         | Container image tag            |
| `HOST`      | `$NAMESPACE.apps.vynder.net`     | Ingress hostname               |
| `REPLICAS`  | `1`                              | Deployment replicas                |
| `REGISTRY`  | `rg.nl-ams.scw.cloud`            | Container registry endpoint |
| `PUSH_NS`   | `t3000-dev`                      | Registry push namespace     |

## Steps performed

1. Creates a ConfigMap containing the Dockerfile
2. Launches a kaniko build Job (image pushed to `$REGISTRY/$PUSH_NS/$NAMESPACE/$APP_NAME:$IMAGE_TAG`)
3. Waits for build completion and prints build logs
4. Deploys the app via Helm (Deployment, Service, Ingress)
5. Prints the app URL

## Notes

- Build runs inside the Kubernetes cluster via kaniko — no local Docker daemon required.
- The kaniko image is pinned by digest for reproducible builds.
- The Deployment references the `scw-registry` pull secret.
- Override `APP_NAME` to deploy under a different name than the directory.
