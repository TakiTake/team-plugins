---
name: Kind Cluster Setup and Configuration
description: This skill should be used when the user needs to "create kind cluster", "configure kind cluster", "fetch kubernetes versions from kind releases", "setup port mapping for kind", "manage kind configuration", or work with kind for local Kubernetes.
version: 0.2.0
---

# Kind Cluster Setup and Configuration

Setup local Kubernetes clusters using kind (Kubernetes IN Docker) with customized configurations including node count, Kubernetes version, and port mappings.

## Purpose

kind creates Kubernetes clusters using Docker containers as nodes. This skill guides cluster creation, fetching supported Kubernetes versions from kind releases, configuring port mappings for Istio ingress, and managing cluster lifecycle.

## When to Use

Use this skill when:
- Creating kind clusters with specific Kubernetes versions
- Fetching supported k8s versions from kind GitHub releases
- Configuring kind with custom port mappings (host:80 → container:30080)
- Setting up multi-node clusters (control-plane + workers)
- Managing existing kind clusters

## Kubernetes Version Selection

### Fetching Supported Versions

kind releases specify supported Kubernetes versions and node images via GitHub API.

**GitHub API URL pattern:**
```
https://api.github.com/repos/kubernetes-sigs/kind/releases/tags/v{KIND_VERSION}
```

**Example:** For kind v0.31.0:
```
https://api.github.com/repos/kubernetes-sigs/kind/releases/tags/v0.31.0
```

### Getting kind Version

First, detect installed kind version:

```bash
KIND_VERSION=$(kind version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
echo $KIND_VERSION  # e.g., v0.31.0
```

### Fetching Release Data from GitHub API

Use Bash to fetch release data:

```bash
# Fetch release data from GitHub API
curl -s "https://api.github.com/repos/kubernetes-sigs/kind/releases/tags/${KIND_VERSION}"
```

This returns JSON with a `body` field containing release notes.

### Parsing K8s Versions from Release Body

The `body` field contains a section with pre-built images:

```
Images pre-built for this release:
- v1.35.0: `kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f`
- v1.34.3: `kindest/node:v1.34.3@sha256:08497ee19eace7b4b5348db5c6a1591d7752b164530a36f855cb0f2bdcbadd48`
- v1.33.7: `kindest/node:v1.33.7@sha256:d26ef333bdb2cbe9862a0f7c3803ecc7b4303d8cea8e814b481b09949d353040`
- v1.32.11: `kindest/node:v1.32.11@sha256:5fc52d52a7b9574015299724bd68f183702956aa4a2116ae75a63cb574b35af8`
- v1.31.14: `kindest/node:v1.31.14@sha256:6f86cf509dbb42767b6e79debc3f2c32e4ee01386f0489b3b2be24b0a55aac2b`
```

**Format:** `- {k8s_version}: \`{image_url}@sha256:{digest}\``

### Parsing Script

```bash
# Get kind version
KIND_VERSION=$(kind version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)

# Fetch release data
RELEASE_DATA=$(curl -s "https://api.github.com/repos/kubernetes-sigs/kind/releases/tags/${KIND_VERSION}")

# Extract body field
BODY=$(echo "$RELEASE_DATA" | jq -r '.body')

# Parse pre-built images section
# Extract lines matching pattern: - v1.X.Y: `kindest/node:...`
echo "$BODY" | grep -E '^\s*-\s*v[0-9]+\.[0-9]+\.[0-9]+:' | while read -r line; do
  # Extract version (e.g., v1.35.0)
  K8S_VERSION=$(echo "$line" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)

  # Extract image URL with digest (e.g., kindest/node:v1.35.0@sha256:...)
  IMAGE_URL=$(echo "$line" | grep -oP '`\K[^`]+')

  echo "$K8S_VERSION|$IMAGE_URL"
done
```

**Output format:**
```
v1.35.0|kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f
v1.34.3|kindest/node:v1.34.3@sha256:08497ee19eace7b4b5348db5c6a1591d7752b164530a36f855cb0f2bdcbadd48
v1.33.7|kindest/node:v1.33.7@sha256:d26ef333bdb2cbe9862a0f7c3803ecc7b4303d8cea8e814b481b09949d353040
```

### Caching Version Data

**Cache location:** `./.config/local/.cache/kind-versions-{KIND_VERSION}.json`

**Cache format:**
```json
{
  "kind_version": "0.31.0",
  "fetched_at": "2025-12-27",
  "versions": {
    "1.35.0": "kindest/node:v1.35.0@sha256:452d707d4862f52530247495d180205e029056831160e22870e37e3f6c1ac31f",
    "1.34.3": "kindest/node:v1.34.3@sha256:08497ee19eace7b4b5348db5c6a1591d7752b164530a36f855cb0f2bdcbadd48",
    "1.33.7": "kindest/node:v1.33.7@sha256:d26ef333bdb2cbe9862a0f7c3803ecc7b4303d8cea8e814b481b09949d353040"
  }
}
```

**Cache usage:**
```bash
# Check if cache exists for current kind version
KIND_VERSION=$(kind version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
CACHE_FILE="./.config/local/.cache/kind-versions-${KIND_VERSION}.json"

if [ -f "$CACHE_FILE" ]; then
  # Use cached data
  cat "$CACHE_FILE" | jq '.versions'
else
  # Fetch from GitHub and cache
fi
```

### Presenting Versions to User

**Important:** AskUserQuestion tool has a 4-option limit. Handle version count accordingly.

**Logic:**
1. Count total available Kubernetes versions
2. **If count > 4:** Show only the top 4 newest versions
3. **If count ≤ 4:** Show all available versions

**When showing top 4 only:**
```bash
# Count versions
VERSION_COUNT=$(echo "$BODY" | grep -cE '^\s*-\s*v[0-9]+\.[0-9]+\.[0-9]+:')

if [ $VERSION_COUNT -gt 4 ]; then
  # Take top 4 newest versions
  VERSIONS=$(echo "$BODY" | grep -E '^\s*-\s*v[0-9]+\.[0-9]+\.[0-9]+:' | head -4)

  # Get older versions (5th and later) for the note
  OLDER_VERSIONS=$(echo "$BODY" | grep -E '^\s*-\s*v[0-9]+\.[0-9]+\.[0-9]+:' | tail -n +5)

  # Extract just the version numbers from older versions (e.g., v1.31.14, v1.30.8)
  OLDER_VERSION_LIST=$(echo "$OLDER_VERSIONS" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -3 | tr '\n' ', ' | sed 's/,$//')

  # Use AskUserQuestion with note about actual older versions
  # Question text: "Which Kubernetes version? (For older versions: v1.31.14, v1.30.8, etc., select 'Other' and type manually)"
else
  # Show all versions
  VERSIONS=$(echo "$BODY" | grep -E '^\s*-\s*v[0-9]+\.[0-9]+\.[0-9]+:')
fi
```

**Example with >4 versions (showing top 4):**
```
Which Kubernetes version would you like to use?
(For older versions: v1.31.14, v1.30.8, etc., select 'Other' and type manually)

Options:
1. v1.35.0 (Latest) - Newest version with latest features
2. v1.34.2 - Recent stable version
3. v1.33.7 - Well-tested stable version
4. v1.32.11 - Older stable version for compatibility

Or select 'Other' to type a custom version
```

**Example with ≤4 versions (showing all):**
```
Which Kubernetes version would you like to use?

Options:
1. v1.35.0 (Latest)
2. v1.34.2
3. v1.33.7
4. v1.32.11
```

## Kind Cluster Configuration

### Configuration File

**Location:** `./.config/local/kind.yaml`
**Format:** YAML (kind config API v1alpha4)

### Basic Configuration Template

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: kindest/node:v{VERSION}@sha256:{DIGEST}
    extraPortMappings:
      - containerPort: 30080
        hostPort: 80
        listenAddress: "127.0.0.1"
        protocol: TCP
  - role: worker
    image: kindest/node:v{VERSION}@sha256:{DIGEST}
  - role: worker
    image: kindest/node:v{VERSION}@sha256:{DIGEST}
```

**Important:** All nodes (control-plane and workers) must have the same image attribute to prevent version mismatch. If image is omitted, kind automatically uses the latest image, which can cause compatibility issues between nodes.

### Customization Options

#### Node Count

**Default:** 1 control-plane + 2 workers

**Prompting user:**
```
How many worker nodes? (default: 2)
```

**Generating config:**
```bash
# Variables from user input
K8S_IMAGE="kindest/node:v1.31.14@sha256:6f86cf509dbb42767b6e79debc3f2c32e4ee01386f0489b3b2be24b0a55aac2b"
WORKER_COUNT=2

# 1 control-plane + N workers
cat > ./.config/local/kind.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    image: ${K8S_IMAGE}
    extraPortMappings:
      - containerPort: 30080
        hostPort: 80
        listenAddress: "127.0.0.1"
        protocol: TCP
EOF

# Add worker nodes with same image
for i in $(seq 1 $WORKER_COUNT); do
  echo "  - role: worker" >> ./.config/local/kind.yaml
  echo "    image: ${K8S_IMAGE}" >> ./.config/local/kind.yaml
done
```

#### Port Mapping

**Purpose:** Route host:80 → kind container:30080 for Istio ingress

**Configuration:**
```yaml
extraPortMappings:
  - containerPort: 30080  # NodePort on kind node
    hostPort: 80          # Port on Mac host
    listenAddress: "127.0.0.1"  # Only localhost
    protocol: TCP
```

**Customizable:** Ask user for host port (default: 80)

```
Configure port mapping:

Host port (traffic from Mac): [default: 80]
Container NodePort (kind node): [default: 30080]
```

#### Kubernetes Version

**Set image in config for ALL nodes:**
```yaml
nodes:
  - role: control-plane
    image: kindest/node:v1.31.14@sha256:6f86cf509dbb42767b6e79debc3f2c32e4ee01386f0489b3b2be24b0a55aac2b
  - role: worker
    image: kindest/node:v1.31.14@sha256:6f86cf509dbb42767b6e79debc3f2c32e4ee01386f0489b3b2be24b0a55aac2b
```

**Critical:** All nodes (control-plane and workers) must specify the same image to prevent version mismatch issues. Workers do NOT automatically inherit the control-plane version if image is omitted

## Creating Kind Cluster

### Prerequisites

**Before creating cluster:**
1. KUBECONFIG environment variable must be set in .claude/settings.local.json
2. `./.config/local/` directory must exist
3. kind configuration saved to `./.config/local/kind.yaml`

### Setting KUBECONFIG First

**Critical:** Set KUBECONFIG before `kind create cluster`:

```bash
# Update .claude/settings.local.json
jq '.env.KUBECONFIG = "./.config/local/kubeconfig"' .claude/settings.local.json > tmp.json
mv tmp.json .claude/settings.local.json

# Export for current session
export KUBECONFIG="./.config/local/kubeconfig"
```

### Creating Cluster

```bash
# Create cluster with config
kind create cluster \
  --name {KIND_CLUSTER_NAME} \
  --config ./.config/local/kind.yaml \
  --kubeconfig ./.config/local/kubeconfig
```

**Flags:**
- `--name`: Cluster name (default: `kind`)
- `--config`: Path to kind configuration
- `--kubeconfig`: Where to write kubeconfig (use KUBECONFIG value)

### Cluster Creation Output

```
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.31.14) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-kind"
```

**Verify:** kubectl context should be `kind-kind`

## Managing Existing Clusters

### Check Existing Clusters

```bash
# List all kind clusters
kind get clusters

# Check specific cluster
kind get clusters | grep -w kind
```

### Handling Existing Clusters

**If cluster already exists:**

```
Kind cluster 'kind' already exists.

Current configuration:
- Nodes: 3 (1 control-plane, 2 workers)
- Kubernetes: v1.31.14

Options:
1. Skip setup (use existing cluster)
2. Delete and recreate (will lose all data)
3. Cancel

Choice:
```

### Deleting Cluster

```bash
# Delete cluster
kind delete cluster --name kind

# Verify deletion
kind get clusters
```

## Verification

### Check Cluster Status

```bash
# Verify cluster exists
kind get clusters

# Check kubectl context
kubectl config current-context  # Should be: kind-kind

# Get cluster info
kubectl cluster-info --context kind-kind

# List nodes
kubectl get nodes
```

**Expected output:**
```
NAME                 STATUS   ROLES           AGE   VERSION
kind-control-plane   Ready    control-plane   1m    v1.31.14
kind-worker          Ready    <none>          1m    v1.31.14
kind-worker2         Ready    <none>          1m    v1.31.14
```

### Test Port Mapping

```bash
# Deploy test nginx with NodePort 30080
kubectl run nginx --image=nginx --port=80
kubectl expose pod nginx --type=NodePort --port=80 --target-port=80 --name=nginx-svc

# Get NodePort
kubectl get svc nginx-svc

# Test from host (should work after Istio setup)
curl http://localhost:80
```

## Integration with Plugin

### Saving Configuration

Update `.claude/k8s-setup.local.md`:

```yaml
---
kind:
  cluster_name: "{KIND_CLUSTER_NAME}"
  workers: 2
  k8s_version: "1.31.14"
  k8s_image: "kindest/node:v1.31.14@sha256:6f86cf509dbb42767b6e79debc3f2c32e4ee01386f0489b3b2be24b0a55aac2b"
  host_port: 80
  container_port: 30080
---
```

### CRD Application

After cluster creation and verification, apply CRDs if specified:

```bash
# Validate CRDs first (dry-run)
kubectl apply --dry-run=server -k /path/to/crds

# Apply CRDs
kubectl apply -k /path/to/crds

# Verify CRDs installed
kubectl get crd
```

## Complete Setup Workflow

1. **Check kind version** (`kind version`)
2. **Fetch supported k8s versions** (from GitHub or cache)
3. **Present versions to user** for selection
4. **Prompt for worker count** (default: 2)
5. **Prompt for port mapping** (default: 80→30080)
6. **Generate kind config** to `./.config/local/kind.yaml`
7. **Set KUBECONFIG** in .claude/settings.local.json
8. **Export KUBECONFIG** for current session
9. **Check for existing cluster** with same name
10. **Handle existing cluster** (skip/delete/cancel)
11. **Create cluster** with `kind create cluster`
12. **Verify cluster** (nodes, context, connectivity)
13. **Save configuration** to .claude/k8s-setup.local.md
14. **Apply CRDs** if specified

## Troubleshooting

### Cluster Creation Fails

```bash
# Check kind logs
kind export logs --name kind

# Delete and retry
kind delete cluster --name kind
kind create cluster --name {KIND_CLUSTER_NAME} --config ./.config/local/kind.yaml
```

### kubectl Can't Connect

**Symptom:** `kubectl get nodes` fails

**Solution:**
```bash
# Check KUBECONFIG
echo $KUBECONFIG

# Set kubectl context
kubectl config use-context kind-kind

# Or specify kubeconfig explicitly
kubectl --kubeconfig=./.config/local/kubeconfig get nodes
```

### Port Mapping Not Working

**Symptom:** Can't access services on host:80

**Solution:**
```bash
# Check port mapping in config
cat ./.config/local/kind.yaml | grep -A4 extraPortMappings

# Recreate cluster with correct config
kind delete cluster --name kind
kind create cluster --name {KIND_CLUSTER_NAME} --config ./.config/local/kind.yaml
```

### GitHub Rate Limit

**Symptom:** Can't fetch k8s versions from GitHub

**Solution:**
- Use cached version data if available
- Inform user of GitHub API rate limit
- Retry after waiting period
- Use specific k8s version directly without fetching

## Additional Resources

### Reference Files

- **`references/kind-config-api.md`** - Complete kind configuration API reference
- **`references/networking.md`** - Port mapping and networking details

### Official Documentation

kind website: https://kind.sigs.k8s.io/
kind releases: https://github.com/kubernetes-sigs/kind/releases

Focus on version compatibility, port mapping configuration, and KUBECONFIG management for reliable local Kubernetes clusters.
