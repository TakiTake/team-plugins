---
description: Delete Docker layer (cascading: also deletes k8s and Istio)
allowed-tools: Bash(*), AskUserQuestion
model: sonnet
---

Delete Docker (lima) layer. **Cascading deletion:** Also deletes Kubernetes and Istio.

**Warning:** This will delete:
- lima VM "docker" and all data
- kind cluster "kind"
- All Kubernetes resources
- kubeconfig file (./.config/local/kubeconfig)
- Docker context "lima-docker"
- DOCKER_CONTEXT from .claude/settings.local.json
- DOCKER_CONTEXT from mise.local.toml

Ask user for confirmation before proceeding.

**Workflow:**
1. Show what will be deleted
2. Ask confirmation
3. Delete Istio: `kubectl delete namespace istio-system`
4. Delete kind cluster: `kind delete cluster --name kind`
5. Remove kubeconfig: `rm ./.config/local/kubeconfig`
6. Stop lima: `limactl stop docker`
7. Delete lima: `limactl delete docker`
8. Remove Docker context: `docker context rm lima-docker`
9. Remove DOCKER_CONTEXT from .claude/settings.local.json:
   - Check if .claude/settings.local.json exists
   - If exists, use jq to remove DOCKER_CONTEXT: `jq 'del(.env.DOCKER_CONTEXT)' .claude/settings.local.json > tmp.json && mv tmp.json .claude/settings.local.json`
   - If .env becomes empty after removal, clean it up
10. Remove DOCKER_CONTEXT from mise.local.toml:
    ```bash
    if [ -f mise.local.toml ]; then
      # Remove DOCKER_CONTEXT line from mise.local.toml
      sed -i '' '/^DOCKER_CONTEXT = /d' mise.local.toml
      # Clean up empty [env] section if needed
      if grep -A1 "^\[env\]$" mise.local.toml | grep -q "^\["; then
        sed -i '' '/^\[env\]$/d' mise.local.toml
      fi
    fi
    ```
11. Keep config files (kind.yaml, istio.yaml, etc.) in ./.config/local/

Report completion and suggest: `/k8s-local-setup:setup-all` to recreate
