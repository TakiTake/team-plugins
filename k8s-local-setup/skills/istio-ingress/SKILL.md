---
name: Istio Ingress Gateway Setup
description: This skill should be used when the user needs to "install Istio", "configure Istio ingress gateway", "setup Istio with istioctl", "create Gateway resource", "configure VirtualService for nip.io", or manage Istio for local Kubernetes.
version: 0.1.0
---

# Istio Ingress Gateway Setup

Install and configure Istio service mesh with ingress gateway for routing external traffic to Kubernetes services using the *.127.0.0.1.nip.io pattern.

## Purpose

Istio provides service mesh capabilities including traffic management, security, and observability. This skill guides installing Istio using istioctl, configuring ingress gateway with NodePort, and creating Gateway resources for local development routing.

## When to Use

Use this skill when:
- Installing Istio on local kind cluster
- Configuring Istio ingress gateway with specific ports (30080 NodePort, 8080 port)
- Generating Istio manifests for GitOps
- Creating Gateway resources for *.127.0.0.1.nip.io routing
- Verifying Istio installation with precheck

## Istio Installation Profile

**Profile for local development:** `demo`

**Why demo profile:**
- Includes ingress gateway
- Suitable for local testing
- Not for production (includes debug tools)
- Easy to get started

**Alternative profiles:** default, minimal, preview (not recommended for local setup)

## Pre-Installation Verification

### Check Cluster Compatibility

Use `istioctl x precheck` before installation:

```bash
# Verify cluster meets Istio requirements
istioctl x precheck

# Expected output:
# ✅ No issues found when checking the cluster.
```

**Check for:**
- Kubernetes version compatibility
- Required permissions
- Cluster resource capacity

If precheck fails, address issues before proceeding.

## Istio Manifest Generation

### Generate Manifest with NodePort Configuration

Generate manifest with nodePort configured to match kind's container port:

```bash
# Read container port from kind configuration
CONTAINER_PORT=$(grep "container_port:" .claude/k8s-setup.local.md | awk '{print $2}')

# Generate manifest with demo profile and nodePort configured
istioctl manifest generate --set profile=demo \
  --set components.ingressGateways[0].k8s.service.ports[1].nodePort=${CONTAINER_PORT} \
  > ./.config/local/istio.yaml
```

**Benefits:**
- NodePort configured correctly from the start (no patching needed)
- Review configuration before applying
- Version control manifest
- GitOps-friendly
- Easy to modify before application

**Important:** The `--set components.ingressGateways[0].k8s.service.ports[1].nodePort=${CONTAINER_PORT}` option sets the nodePort for the http2 port (index [1]) of the first ingress gateway.

### Generated Manifest Structure

The generated manifest will include the configured nodePort:

```yaml
# ./.config/local/istio.yaml (excerpt)
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
  namespace: istio-system
spec:
  type: NodePort
  selector:
    app: istio-ingressgateway
  ports:
    - name: http2
      port: 80
      targetPort: 8080
      nodePort: 30080  # Set via --set option (matches kind's containerPort)
      protocol: TCP
```

## Ingress Gateway Configuration

### Port Configuration

**Requirements:**
- **NodePort:** Must match kind's containerPort (user-configurable, default: 30080)
- **Port:** 8080 (internal gateway port)
- **Host port:** User-configurable (default: 80, mapped via kind extraPortMappings)

**Traffic flow:**
```
Browser (http://app.127.0.0.1.nip.io)
  ↓
Host:{HOST_PORT} (Mac, e.g., 80)
  ↓
Kind NodePort:{CONTAINER_PORT} (kind container, e.g., 30080)
  ↓
Istio Gateway Service:8080 (pod)
  ↓
Application Service
  ↓
Pod
```

**Important:** The NodePort value is configured by the user during kind cluster setup (Question 4: Kind Cluster Configuration). The istio-ingressgateway Service must be patched to use the same NodePort value.

### Gateway Service Configuration

The istio-ingressgateway service should be configured as:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: istio-ingressgateway
  namespace: istio-system
spec:
  type: NodePort
  selector:
    app: istio-ingressgateway
  ports:
    - name: http2
      port: 80
      targetPort: 8080
      nodePort: 30080  # Must match kind's containerPort (user-configurable)
      protocol: TCP
```

**Note:** The `nodePort` value shown above (30080) is the default. It must match whatever container port the user configured during kind cluster setup.

## Installing Istio

### Apply Manifest

```bash
# Apply generated manifest
kubectl apply -f ./.config/local/istio.yaml
```

### Wait for Deployment

```bash
# Wait for Istio pods to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/istiod -n istio-system

kubectl wait --for=condition=available --timeout=300s \
  deployment/istio-ingressgateway -n istio-system
```

### Verify Installation

```bash
# Check Istio components
kubectl get pods -n istio-system

# Expected pods:
# - istiod-*
# - istio-ingressgateway-*
# - istio-egressgateway-* (if using demo profile)

# Check ingress gateway service
kubectl get svc istio-ingressgateway -n istio-system

# Verify NodePort matches container port
kubectl get svc istio-ingressgateway -n istio-system \
  -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'

# Expected output: Should match the container_port from .claude/k8s-setup.local.md (e.g., 30080)
```

## Gateway Resource Creation

### Default Gateway for *.127.0.0.1.nip.io

Create Gateway resource for wildcard domain:

```yaml
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
```

**Apply Gateway:**
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

### Understanding nip.io

**nip.io:** Wildcard DNS service that maps to IP addresses

**Pattern:** `{anything}.{ip}.nip.io` → resolves to `{ip}`

**Example:**
- `app.127.0.0.1.nip.io` → 127.0.0.1
- `api.127.0.0.1.nip.io` → 127.0.0.1
- `nginx.127.0.0.1.nip.io` → 127.0.0.1

**Benefits:**
- No /etc/hosts configuration needed
- Works for all app names
- Each app gets unique subdomain

## VirtualService Example

Applications use VirtualService to route through gateway:

```yaml
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
```

## Verification Testing

### Deploy Test Application

```bash
# Deploy nginx
kubectl create deployment nginx --image=nginx:latest

# Expose as ClusterIP service
kubectl expose deployment nginx --port=80 --target-port=80 --type=ClusterIP

# Create VirtualService
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

### Test Access

```bash
# Test HTTP access
curl http://nginx.127.0.0.1.nip.io

# Expected: nginx welcome page HTML
# Status: 200 OK

# Test with verbose output
curl -v http://nginx.127.0.0.1.nip.io

# Should show:
# < HTTP/1.1 200 OK
# < server: istio-envoy
```

### Cleanup Test Resources

```bash
# Remove test resources
kubectl delete virtualservice nginx
kubectl delete svc nginx
kubectl delete deployment nginx
```

## Complete Setup Workflow

1. **Verify cluster ready** (kind cluster exists and accessible)
2. **Run precheck** (`istioctl x precheck`)
3. **Generate manifest with nodePort configured** to `./.config/local/istio.yaml` (using --set option to match kind's container port)
4. **Review manifest** (optional customizations)
5. **Apply manifest** (`kubectl apply -f`)
6. **Wait for pods ready** (istiod, ingress gateway)
7. **Verify ingress gateway service** (NodePort matches configured container port)
8. **Create default Gateway** for *.127.0.0.1.nip.io
9. **Deploy test app** (nginx)
10. **Create test VirtualService**
11. **Verify HTTP 200** from nginx.127.0.0.1.nip.io
12. **Cleanup test resources**
13. **Save configuration** to .claude/k8s-setup.local.md

## Integration with Plugin

### Saving Configuration

Update `.claude/k8s-setup.local.md`:

```yaml
---
istio:
  profile: "demo"
  ingress_nodeport: 30080
  ingress_port: 8080
  gateway_namespace: "istio-system"
  gateway_name: "default-gateway"
---
```

## Uninstalling Istio

### Remove Istio Components

```bash
# Delete istio-system namespace and all components
kubectl delete namespace istio-system

# Or use istioctl
istioctl uninstall --purge -y
```

### Cleanup CRDs

```bash
# Remove Istio CRDs
kubectl delete crd $(kubectl get crd | grep istio.io | awk '{print $1}')
```

## Troubleshooting

### Pods Not Ready

**Symptom:** istiod or ingress gateway pods not starting

**Solution:**
```bash
# Check pod status
kubectl get pods -n istio-system

# Describe pod for events
kubectl describe pod <pod-name> -n istio-system

# Check logs
kubectl logs <pod-name> -n istio-system
```

### Gateway Not Routing

**Symptom:** curl returns connection refused or 404

**Solution:**
```bash
# Check gateway exists
kubectl get gateway -A

# Check gateway configuration
kubectl get gateway default-gateway -n istio-system -o yaml

# Check ingress gateway service
kubectl get svc istio-ingressgateway -n istio-system

# Verify NodePort
kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
```

### VirtualService Not Working

**Symptom:** HTTP 404 despite VirtualService created

**Solution:**
```bash
# Check VirtualService
kubectl get virtualservice

# Verify configuration
kubectl get virtualservice nginx -o yaml

# Check if service exists
kubectl get svc nginx

# Test direct service access (bypass Istio)
kubectl port-forward svc/nginx 8080:80
curl http://localhost:8080
```

### NodePort Not Accessible

**Symptom:** Can't reach NodePort 30080

**Solution:**
```bash
# Check kind port mapping
docker ps | grep kind

# Verify kind config has extraPortMappings
cat ./.config/local/kind.yaml | grep -A4 extraPortMappings

# Recreate cluster if port mapping missing
```

## Additional Resources

### Reference Files

- **`references/istio-architecture.md`** - Istio components and data plane
- **`references/gateway-api.md`** - Gateway and VirtualService configuration details

### Official Documentation

Istio docs: https://istio.io/latest/docs/
Istio gateway: https://istio.io/latest/docs/tasks/traffic-management/ingress/

Use WebFetch to access latest Istio documentation when needed.

Focus on manifest generation, ingress gateway configuration with NodePort, and nip.io wildcard routing for reliable local service mesh setup.
