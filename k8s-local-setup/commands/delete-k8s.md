---
description: Delete Kubernetes layer (cascading: also deletes Istio)
allowed-tools: Bash(*), AskUserQuestion
model: sonnet
---

Delete Kubernetes (kind) layer. **Cascading deletion:** Also deletes Istio.

**Warning:** This will delete:
- kind cluster "kind" and all resources
- All namespaces and applications
- Istio installation
- kubeconfig file (./.config/local/kubeconfig)
- KUBECONFIG from mise.local.toml

Ask user for confirmation before proceeding.

**Workflow:**
1. Show what will be deleted
2. Ask confirmation
3. Delete kind cluster: `kind delete cluster --name kind`
4. Remove kubeconfig: `rm ./.config/local/kubeconfig`
5. Remove KUBECONFIG from mise.local.toml:
   ```bash
   if [ -f mise.local.toml ]; then
     # Remove KUBECONFIG line from mise.local.toml
     sed -i '' '/^KUBECONFIG = /d' mise.local.toml
     # Clean up empty [env] section if needed
     if grep -A1 "^\[env\]$" mise.local.toml | grep -q "^\["; then
       sed -i '' '/^\[env\]$/d' mise.local.toml
     fi
   fi
   ```
6. Keep kind.yaml and istio.yaml in ./.config/local/

Report completion and suggest: `/k8s-local-setup:setup-k8s` to recreate
