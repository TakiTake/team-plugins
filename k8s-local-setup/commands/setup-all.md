---
description: Interactive setup of complete local K8s development environment
allowed-tools: Read, Write, Bash(*), AskUserQuestion, Grep, Glob
model: sonnet
---

Complete setup of local Kubernetes development environment including Docker (lima), Kubernetes (kind), and Istio.

**Setup Flow:**
1. Docker layer (lima VM)
2. Kubernetes layer (kind cluster)
3. Istio layer (service mesh + ingress gateway)

**Prerequisites Check:**
- Homebrew installed
- Claude Code installed
- mise will be installed if missing

---

## Phase 1: Tool Installation (mise)

### 1.1 Check and Install mise

Check if mise is installed:
```bash
command -v mise
```

If not installed:
```bash
brew install mise
eval "$(mise activate $(basename $SHELL))"
```

### 1.2 Setup mise.toml and Install Tools

Check if `mise.toml` exists at project root:
```bash
test -f mise.toml && echo "exists" || echo "missing"
```

**If mise.toml exists:**
```bash
mise install
```

**If mise.toml is missing:**

Create `mise.toml` at project root:
```toml
[tools]
lima = "latest"
kind = "latest"
kubectl = "latest"
istioctl = "latest"
helm = "latest"
```

Then trust and install:
```bash
mise trust && mise install
```

### 1.3 Verify All Required Tools

Check that all required tools are installed:
```bash
mise current
```

Verify each tool is available:
```bash
lima --version
kind --version
kubectl version --client
istioctl version --remote=false
helm version
```

All tools must be installed before proceeding to configuration.

---

## Phase 2: Configuration Gathering

Ask user for all configuration upfront using AskUserQuestion tool with separate questions:

**Question 1: Lima Instance Name**
- Ask: "What should the lima instance be named?"
- Options: "docker" (default), or custom name
- Store the instance name for use in Phase 4

**Question 2: Lima VM Resources**
- VM Resources: Default (4-8-10), High (8-16-20), or Custom (CPU-MEMORY-STORAGE format)
- Store selected resource values

**Question 3: Kind Cluster Name**
- Ask: "What should the kind cluster be named?"
- Options: "kind" (default), or custom name
- Store the cluster name for use in Phase 5

**Question 4: Kind Cluster Configuration**
- Worker node count (default: 2)
- Fetch supported Kubernetes versions from kind GitHub releases (now that kind is installed)
- Count the number of versions:
  - **If more than 4 versions:**
    - Show only the top 4 newest versions in AskUserQuestion
    - Get older versions (5th and later): `OLDER_VERSIONS=$(echo "$BODY" | grep -E '^\s*-\s*v[0-9]+\.[0-9]+\.[0-9]+:' | tail -n +5)`
    - Extract version numbers from older versions for the note: `OLDER_VERSION_LIST=$(echo "$OLDER_VERSIONS" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -3 | tr '\n' ', ' | sed 's/,$//')`
    - Add note with actual older versions: "For older versions: {OLDER_VERSION_LIST}, etc., select 'Other' and type manually"
  - **If 4 or fewer versions:** Show all available versions
- Let user select preferred K8s version
- Host port mapping (default: 80 → container: 30080)
- Store selected configuration values

**Question 5: CRDs (Optional)**
- Ask if custom CRDs should be installed
- If yes, ask for CRD location (Git repo URL or local path)

**Confirmation:**
- Show complete configuration summary
- Ask user to confirm before proceeding

---

## Phase 3: Docker Setup (lima)

**Use the lima-docker skill for guidance.**

### 3.1 Download and Customize Template

Download docker-rootful template:
```bash
mkdir -p .config/local
curl -fsSL https://raw.githubusercontent.com/lima-vm/lima/master/templates/docker-rootful.yaml -o ./.config/local/lima.yaml
```

Update template with user-selected resources:
- Edit `cpus:` field
- Edit `memory:` field
- Edit `disk:` field

### 3.2 Check for Existing Instance

```bash
limactl list | grep docker
```

If instance exists, ask user:
- Skip setup (use existing)
- Delete and recreate
- Cancel

### 3.3 Create Lima Instance

```bash
limactl start --name={LIMA_INSTANCE_NAME} ./.config/local/lima.yaml
```

Parse output to extract Docker context commands and context name.

### 3.4 Configure Docker Context

Run commands from limactl output:
```bash
docker context create lima-docker --docker "host=unix://..."
docker context use lima-docker
```

### 3.5 Verify Docker

```bash
docker run --rm hello-world
```

Expected: "Hello from Docker!" output

### 3.6 Update Claude Settings

**Use claude-settings-management skill.**

Ask user for confirmation before updating `.claude/settings.local.json`:
```json
{
  "env": {
    "DOCKER_CONTEXT": "lima-docker"
  }
}
```

### 3.7 Save Configuration

Update `.claude/k8s-setup.local.md`:
```yaml
---
lima:
  vm_name: "{LIMA_INSTANCE_NAME}"
  cpu: 4
  memory: 8
  storage: 10
---
```

---

## Phase 4: Kubernetes Setup (kind)

**Use the kind-cluster-setup skill for guidance.**

### 4.1 Set KUBECONFIG Before Setup

**Critical:** Set KUBECONFIG before creating cluster.

Ask user for confirmation, then update `.claude/settings.local.json`:
```json
{
  "env": {
    "DOCKER_CONTEXT": "lima-docker",
    "KUBECONFIG": "./.config/local/kubeconfig"
  }
}
```

Export for current session:
```bash
export KUBECONFIG="./.config/local/kubeconfig"
```

### 4.2 Generate Kind Configuration

Create `./.config/local/kind.yaml`:
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

**Important:** All nodes (control-plane and workers) must have the same image attribute to prevent version mismatch issues. If image is omitted, kind uses the latest image automatically, which can cause compatibility problems.

Number of worker nodes based on user input.

### 4.3 Check for Existing Cluster

```bash
kind get clusters
```

If cluster named {KIND_CLUSTER_NAME} exists, ask user action.

### 4.4 Create Cluster

```bash
kind create cluster --name {KIND_CLUSTER_NAME} --config ./.config/local/kind.yaml --kubeconfig ./.config/local/kubeconfig
```

Wait for completion.

### 4.5 Verify Cluster

```bash
kubectl get nodes
kubectl cluster-info
```

All nodes should be Ready.

### 4.6 Apply CRDs (if specified)

If user provided CRD location:
```bash
# Validate first
kubectl apply --dry-run=server -k {CRD_LOCATION}

# Apply
kubectl apply -k {CRD_LOCATION}

# Verify
kubectl get crd
```

### 4.7 Save Configuration

Update `.claude/k8s-setup.local.md`:
```yaml
kind:
  cluster_name: "{KIND_CLUSTER_NAME}"
  workers: 2
  k8s_version: "1.31.14"
  k8s_image: "kindest/node:..."
  host_port: 80
  container_port: 30080

crd:
  location: "/path/to/crds"
```

---

## Phase 5: Istio Setup

**Use the istio-ingress skill for guidance.**

### 5.1 Precheck

```bash
istioctl x precheck
```

Should return: "No issues found when checking the cluster."

### 5.2 Generate Manifest with NodePort Configuration

Generate manifest with nodePort set to match kind's container port:

```bash
# Read container port from saved configuration
CONTAINER_PORT=$(grep "container_port:" .claude/k8s-setup.local.md | awk '{print $2}')

# Generate manifest with nodePort configured
istioctl manifest generate --set profile=demo \
  --set components.ingressGateways[0].k8s.service.ports[1].nodePort=${CONTAINER_PORT} \
  > ./.config/local/istio.yaml
```

### 5.3 Apply Manifest

```bash
kubectl apply -f ./.config/local/istio.yaml
```

Wait for pods to be ready:
```bash
kubectl wait --for=condition=available --timeout=300s deployment/istiod -n istio-system
kubectl wait --for=condition=available --timeout=300s deployment/istio-ingressgateway -n istio-system
```

### 5.4 Verify Ingress Gateway Service NodePort

Verify NodePort matches kind configuration:

```bash
kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
```

Expected output: Should match the container port from kind configuration (e.g., `30080`)

### 5.5 Create Default Gateway

```bash
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: default-gateway
  namespace: istio-system
spec:
  selector:
    istio: ingressgateway
  servers:
    - port:
        number: 8080
        name: http
        protocol: HTTP
      hosts:
        - "*.127.0.0.1.nip.io"
EOF
```

### 5.6 Deploy Test Application

Deploy nginx to verify routing:
```bash
kubectl create deployment nginx --image=nginx:latest
kubectl expose deployment nginx --port=80 --type=ClusterIP

kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: nginx
  namespace: default
spec:
  hosts:
    - "nginx.127.0.0.1.nip.io"
  gateways:
    - istio-system/default-gateway
  http:
    - match:
        - uri:
            prefix: /
      route:
        - destination:
            host: nginx
            port:
              number: 80
EOF
```

Wait for nginx pod:
```bash
kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s
```

### 5.7 Verify HTTP Access

```bash
curl --max-time 30 --connect-timeout 30 http://nginx.127.0.0.1.nip.io
```

Expected: HTTP 200 OK with nginx welcome page.

### 5.8 Cleanup Test Resources

```bash
kubectl delete virtualservice nginx
kubectl delete svc nginx
kubectl delete deployment nginx
```

### 5.9 Save Configuration

Update `.claude/k8s-setup.local.md`:
```yaml
istio:
  profile: "demo"
  ingress_nodeport: 30080
  ingress_port: 8080

last_setup_date: "2025-12-27"
```

---

## Phase 6: Final Verification

**Use verification-strategies skill for comprehensive verification.**

Run complete verification:
```bash
# Docker
docker ps

# Kubernetes
kubectl get nodes
kubectl cluster-info

# Istio
kubectl get pods -n istio-system
```

Present final status checklist:
```
✅ Docker (lima): Running, context active
✅ Kubernetes (kind): 3/3 nodes Ready
✅ Istio: Ingress gateway operational
✅ HTTP routing: nginx.127.0.0.1.nip.io → 200 OK
✅ Configuration: Saved to .claude/k8s-setup.local.md
✅ Environment: .claude/settings.local.json updated
```

---

## Phase 7: mise.local.toml Setup

**Use mise-usage skill for guidance.**

### 7.1 Create or Update mise.local.toml

Copy environment variables from `.claude/settings.local.json` to `mise.local.toml`:

```bash
# Read environment variables from Claude settings
DOCKER_CONTEXT_VALUE=$(jq -r '.env.DOCKER_CONTEXT // empty' .claude/settings.local.json)
KUBECONFIG_VALUE=$(jq -r '.env.KUBECONFIG // empty' .claude/settings.local.json)

# Create mise.local.toml with environment variables
cat > mise.local.toml <<EOF
[env]
DOCKER_CONTEXT = "$DOCKER_CONTEXT_VALUE"
KUBECONFIG = "$KUBECONFIG_VALUE"
EOF
```

### 7.2 Verify mise.local.toml

```bash
# Display created file
cat mise.local.toml

# Verify mise can read it
mise exec -- env | grep -E 'DOCKER_CONTEXT|KUBECONFIG'
```

Expected output:
```
[env]
DOCKER_CONTEXT = "lima-docker"
KUBECONFIG = "./.config/local/kubeconfig"
```

### 7.3 Inform User

Show message:
```
✅ Created mise.local.toml with environment variables:
   - DOCKER_CONTEXT: lima-docker
   - KUBECONFIG: ./.config/local/kubeconfig

These environment variables will now be available in your shell when using mise.
Run 'mise exec -- env' to verify.
```

---

## Setup Complete

Show summary:
```
Local Kubernetes Development Environment Setup Complete!

Stack:
- Docker: lima (docker context: lima-docker)
- Kubernetes: kind v{VERSION} (3 nodes)
- Istio: demo profile
- Routing: *.127.0.0.1.nip.io → Istio Gateway → Services

Configuration:
- .claude/settings.local.json: Environment variables for Claude Code
- mise.local.toml: Environment variables for shell (via mise)
- .claude/k8s-setup.local.md: Setup configuration

Next Steps:
1. Deploy your applications with namespace-scoped manifests
2. Create VirtualServices with pattern: {app-name}.127.0.0.1.nip.io
3. Access apps at: http://{app-name}.127.0.0.1.nip.io

Useful Commands:
- /k8s-local-setup:status - Check current setup
- /k8s-local-setup:verify-all - Verify all layers
- /k8s-local-setup:apply-crd - Apply custom CRDs
```

---

**Error Handling:**

If any step fails:
1. Report exact error
2. Show relevant logs
3. Suggest fixes based on error
4. Optionally trigger setup-troubleshooter agent for diagnosis
