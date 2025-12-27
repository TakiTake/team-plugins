---
description: Delete entire local K8s environment
allowed-tools: Bash(*), AskUserQuestion
model: sonnet
---

Delete entire local Kubernetes development environment.

**Warning:** This will delete:
- Istio (service mesh)
- Kubernetes cluster (kind)
- Docker environment (lima)
- kubeconfig file (./.config/local/kubeconfig)
- Docker context (lima-docker)
- DOCKER_CONTEXT from .claude/settings.local.json
- DOCKER_CONTEXT from mise.local.toml
- All applications and data

Configuration files (kind.yaml, istio.yaml, etc.) in ./.config/local/ will be kept.

Ask user for explicit confirmation before proceeding.

**Workflow:**
1. Show comprehensive list of what will be deleted
2. Ask confirmation with clear warning
3. Run delete commands in order:
   - `/k8s-local-setup:delete-istio`
   - `/k8s-local-setup:delete-k8s`
   - `/k8s-local-setup:delete-docker`

Report completion and suggest: `/k8s-local-setup:setup-all` to recreate from saved configuration
