---
description: Show current local K8s development environment status
allowed-tools: Bash(*), Read
model: haiku
---

Display comprehensive status of local Kubernetes development environment including Docker, Kubernetes, and Istio layers.

---

## Status Collection

Gather status information from all layers:

### 1. Tool Versions

```bash
echo "=== Tool Versions ==="
mise current 2>/dev/null || echo "mise: not configured"
```

### 2. Docker Status

```bash
echo "=== Docker (lima) ==="

# Check lima instance
limactl list 2>/dev/null | grep docker || echo "lima instance: not found"

# Check Docker context
docker context ls 2>/dev/null | grep "*" || echo "No active context"

# Test Docker
docker ps >/dev/null 2>&1 && echo "Docker: ✅ Running" || echo "Docker: ❌ Not accessible"
```

### 3. Kubernetes Status

```bash
echo "=== Kubernetes (kind) ==="

# Check clusters
kind get clusters 2>/dev/null || echo "kind clusters: none"

# Check kubectl context
kubectl config current-context 2>/dev/null || echo "kubectl context: not set"

# Check nodes
kubectl get nodes 2>/dev/null || echo "kubectl: cannot connect to cluster"
```

### 4. Istio Status

```bash
echo "=== Istio ==="

# Check Istio pods
kubectl get pods -n istio-system 2>/dev/null || echo "istio-system namespace: not found"

# Check ingress gateway service
kubectl get svc istio-ingressgateway -n istio-system 2>/dev/null | grep -o "30080" && echo "NodePort 30080: ✅ Configured" || echo "NodePort 30080: ❌ Not configured"

# Check gateway
kubectl get gateway default-gateway -n istio-system 2>/dev/null >/dev/null && echo "Default gateway: ✅ Created" || echo "Default gateway: ❌ Not found"
```

### 5. Environment Variables

```bash
echo "=== Environment Variables ==="

# Check settings file
if [ -f .claude/settings.local.json ]; then
  cat .claude/settings.local.json | jq -r '.env | to_entries | .[] | "  \(.key): \(.value)"'
else
  echo "  .claude/settings.local.json: not found"
fi
```

### 6. Configuration Files

```bash
echo "=== Configuration Files ==="

# Check config files
for file in .config/local/{lima.yaml,kind.yaml,istio.yaml,kubeconfig}; do
  if [ -f "$file" ]; then
    echo "  ✅ $file"
  else
    echo "  ❌ $file (missing)"
  fi
done

# Check k8s-setup.local.md
if [ -f .claude/k8s-setup.local.md ]; then
  echo "  ✅ .claude/k8s-setup.local.md"
else
  echo "  ❌ .claude/k8s-setup.local.md (missing)"
fi
```

---

## Format and Display Status Table

Based on collected information, create a summary table:

```
┌─────────────────────────────────────────────────────────┐
│ Local K8s Development Environment Status                │
├─────────────────────┬───────────────────────────────────┤
│ Component           │ Status                            │
├─────────────────────┼───────────────────────────────────┤
│ mise                │ Configured / Not configured       │
│ lima (docker)       │ Running / Stopped / Not found     │
│ Docker context      │ lima-docker (active) / Other      │
│ kind cluster        │ Running (3 nodes) / Not found     │
│ kubectl context     │ kind-kind / Other / Not set       │
│ Istio (istiod)      │ Running / Not running             │
│ Istio gateway       │ Running (NodePort 30080) / Error  │
│ Default gateway     │ Created / Not found               │
├─────────────────────┼───────────────────────────────────┤
│ Environment         │                                   │
│  DOCKER_CONTEXT     │ lima-docker / Not set             │
│  KUBECONFIG         │ ./.config/local/kubeconfig        │
├─────────────────────┼───────────────────────────────────┤
│ Configuration Files │                                   │
│  lima.yaml          │ ✅ / ❌                            │
│  kind.yaml          │ ✅ / ❌                            │
│  istio.yaml         │ ✅ / ❌                            │
│  kubeconfig         │ ✅ / ❌                            │
│  k8s-setup.local.md │ ✅ / ❌                            │
└─────────────────────┴───────────────────────────────────┘
```

---

## Health Summary

Provide overall health assessment:

**All Healthy:**
```
Overall Status: ✅ HEALTHY
All layers operational and properly configured.
```

**Partially Healthy:**
```
Overall Status: ⚠️  PARTIAL
Some components need attention. Run /k8s-local-setup:verify-all for details.
```

**Not Healthy:**
```
Overall Status: ❌ UNHEALTHY
Environment not properly setup. Run /k8s-local-setup:setup-all to configure.
```

---

## Additional Information

If `.claude/k8s-setup.local.md` exists, read and display configuration:

```yaml
Configuration from .claude/k8s-setup.local.md:

lima:
  vm_name: docker
  cpu: 4
  memory: 8
  storage: 10

kind:
  cluster_name: kind
  workers: 2
  k8s_version: 1.31.14

istio:
  profile: demo
  ingress_nodeport: 30080

last_setup_date: 2025-12-27
```

---

## Troubleshooting Hints

Based on status, provide relevant hints:

**If Docker not running:**
```
Hint: Start lima instance with: limactl start docker
```

**If kubectl can't connect:**
```
Hint: Check KUBECONFIG: echo $KUBECONFIG
      Set context: kubectl config use-context kind-kind
```

**If Istio not running:**
```
Hint: Check Istio pods: kubectl get pods -n istio-system
      Restart if needed: kubectl rollout restart deployment -n istio-system
```

---

Present complete status report with table, health summary, configuration details, and troubleshooting hints.
