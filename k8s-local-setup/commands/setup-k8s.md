---
description: Setup Kubernetes cluster using kind
allowed-tools: Bash(*), AskUserQuestion, Read, Write
model: sonnet
---

Setup local Kubernetes cluster using kind with customized configuration.

**Use kind-cluster-setup skill for detailed guidance.**

**Workflow:**
1. Verify Docker layer is ready
2. Prompt user for kind cluster name (default: "kind")
3. Set KUBECONFIG in .claude/settings.local.json BEFORE creating cluster (ask user)
4. Export KUBECONFIG="./.config/local/kubeconfig"
5. Fetch supported k8s versions from kind GitHub API (see kind-cluster-setup skill for details)
6. Prompt user for: worker count, k8s version (see note below), port mapping
   - **K8s version selection:**
     - Count available versions
     - If more than 4: Show only top 4 newest, get older versions with `tail -n +5`, extract version list, add to note
     - Note format: "For older versions: {actual_older_versions}, etc., select 'Other' and type manually"
7. Generate ./.config/local/kind.yaml with extraPortMappings (host:80 → container:30080)
8. Check for existing cluster with specified name
9. Create cluster: `kind create cluster --name {KIND_CLUSTER_NAME} --config ./.config/local/kind.yaml`
10. Verify: `kubectl get nodes` (all Ready)
11. If CRDs specified, apply them: `kubectl apply -k {CRD_LOCATION}`
12. Update mise.local.toml with KUBECONFIG:
    ```bash
    # Read KUBECONFIG from Claude settings
    KUBECONFIG_VALUE=$(jq -r '.env.KUBECONFIG // empty' .claude/settings.local.json)

    # Update or create mise.local.toml
    if [ -f mise.local.toml ]; then
      # File exists - update KUBECONFIG
      if grep -q "KUBECONFIG" mise.local.toml; then
        sed -i '' "s|KUBECONFIG = .*|KUBECONFIG = \"$KUBECONFIG_VALUE\"|" mise.local.toml
      else
        # Add KUBECONFIG to existing [env] section or create it
        if grep -q "\[env\]" mise.local.toml; then
          sed -i '' "/\[env\]/a\\
KUBECONFIG = \"$KUBECONFIG_VALUE\"
" mise.local.toml
        else
          echo -e "\n[env]\nKUBECONFIG = \"$KUBECONFIG_VALUE\"" >> mise.local.toml
        fi
      fi
    else
      # File doesn't exist - create it
      cat > mise.local.toml <<EOF
[env]
KUBECONFIG = "$KUBECONFIG_VALUE"
EOF
    fi
    ```
13. Save config to .claude/k8s-setup.local.md with cluster name

Report success and show next steps: `/k8s-local-setup:setup-istio`
