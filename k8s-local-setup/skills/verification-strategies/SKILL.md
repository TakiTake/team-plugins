---
name: Verification Strategies for K8s Local Setup
description: This skill should be used when the user needs to "verify Docker setup", "verify Kubernetes cluster", "verify Istio installation", "troubleshoot connectivity issues", "check application access", or comprehensively verify the local development stack.
version: 0.1.0
---

# Verification Strategies for K8s Local Setup

Comprehensive verification strategies for validating each layer of the local Kubernetes development stack (Docker, Kubernetes, Istio) like a senior full stack engineer.

## Purpose

Verification ensures each layer functions correctly before moving to the next. This skill provides systematic approaches to verify infrastructure layers from low to high, diagnose failures, and guide users to investigate connectivity issues when applications are inaccessible.

## When to Use

Use this skill when:
- Verifying Docker/lima layer after setup
- Checking Kubernetes cluster health
- Validating Istio ingress gateway functionality
- Troubleshooting application accessibility issues
- Performing layer-by-layer diagnostics
- Verifying complete stack end-to-end

## Verification Philosophy

### Senior Full Stack Engineer Approach

**Principle:** Verify bottom-up, from infrastructure to application

**Layers (low to high):**
1. **Docker** - Container runtime
2. **Kubernetes** - Orchestration platform
3. **Istio** - Service mesh and ingress
4. **Application** - User workloads

**Strategy:**
- Verify each layer independently
- Don't skip layers (e.g., don't test Istio if k8s broken)
- Use layer-specific tools
- Check connectivity, configuration, and functionality
- Apply 30-second timeouts for network operations

### Timeout Configuration

**Connection timeout:** 30 seconds
**Read timeout:** 30 seconds

**Rationale:**
- Sufficient for local network
- Prevents hanging on failures
- Quick feedback for debugging

## Layer 1: Docker Verification

### Objective

Verify Docker context points to lima and container operations work.

### Verification Steps

#### 1. Check Docker Context

```bash
# List Docker contexts
docker context ls

# Expected output should include lima context:
# NAME          DESCRIPTION    DOCKER ENDPOINT
# lima-docker   *              unix:///Users/.../.lima/docker/sock/docker.sock
```

**✅ Success criteria:**
- lima context exists
- lima context is active (marked with *)

#### 2. Check lima Instance Status

```bash
# Check lima instance is running
limactl list

# Expected output:
# NAME     STATUS    SSH
# docker   Running   Ready
```

**✅ Success criteria:**
- Instance status: Running
- SSH status: Ready

#### 3. Test Docker Operations

```bash
# Test basic docker command
docker ps

# Should list running containers (may be empty)
```

**✅ Success criteria:**
- Command executes without error
- Returns container list (even if empty)

#### 4. Run Hello World Container

```bash
# Pull and run test container
docker run --rm hello-world

# Expected output:
# Hello from Docker!
# This message shows that your installation appears to be working correctly.
```

**✅ Success criteria:**
- Container downloads successfully
- Container runs and outputs "Hello from Docker!"
- Container removes itself (--rm)

### Verification Checklist

```
Docker Layer Verification:
□ Docker context 'lima-docker' exists
□ Docker context 'lima-docker' is active
□ lima instance 'docker' is Running
□ lima instance SSH is Ready
□ docker ps command succeeds
□ docker run hello-world succeeds

Result: ✅ PASS / ❌ FAIL
```

### Fix Suggestions

**If Docker context not active:**
```bash
docker context use lima-docker
```

**If lima instance not running:**
```bash
limactl start docker
```

**If hello-world fails:**
```bash
# Check lima logs
limactl shell docker -- docker ps
limactl shell docker -- cat /var/log/docker.log
```

## Layer 2: Kubernetes Verification

### Objective

Verify kind cluster is running, kubectl can connect, and nodes are ready.

### Verification Steps

#### 1. Check kubectl Context

```bash
# Get current context
kubectl config current-context

# Expected: kind-kind
```

**✅ Success criteria:**
- Current context is `kind-kind`

#### 2. Check Cluster Info

```bash
# Get cluster information
kubectl cluster-info --request-timeout=30s

# Expected output:
# Kubernetes control plane is running at https://127.0.0.1:XXXXX
# CoreDNS is running at https://127.0.0.1:XXXXX/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

**✅ Success criteria:**
- Control plane is running
- CoreDNS is running
- No connection errors

#### 3. Check Node Status

```bash
# List nodes
kubectl get nodes

# Expected output (for 1 control-plane + 2 workers):
# NAME                 STATUS   ROLES           AGE   VERSION
# kind-control-plane   Ready    control-plane   5m    v1.31.14
# kind-worker          Ready    <none>          5m    v1.31.14
# kind-worker2         Ready    <none>          5m    v1.31.14
```

**✅ Success criteria:**
- All nodes present (1 control-plane + N workers)
- All nodes STATUS: Ready
- Kubernetes version matches configuration

#### 4. Check System Pods

```bash
# Check kube-system pods
kubectl get pods -n kube-system

# All pods should be Running or Completed
```

**✅ Success criteria:**
- coredns pods: Running
- kube-proxy pods: Running
- kindnet pods: Running
- No pods in CrashLoopBackOff or Error state

#### 5. Test Service Connectivity

```bash
# Check if can reach Kubernetes API
kubectl get --raw /healthz --request-timeout=30s

# Expected: ok
```

**✅ Success criteria:**
- Returns "ok"
- No timeout errors

### Verification Checklist

```
Kubernetes Layer Verification:
□ kubectl context is 'kind-kind'
□ Cluster info shows control plane running
□ All expected nodes are Ready
□ All kube-system pods are Running
□ Kubernetes API /healthz returns 'ok'
□ CoreDNS is operational

Result: ✅ PASS / ❌ FAIL
```

### Fix Suggestions

**If context wrong:**
```bash
kubectl config use-context kind-kind
```

**If nodes not ready:**
```bash
# Check node details
kubectl describe node kind-control-plane

# Check logs
kubectl logs -n kube-system -l component=kubelet
```

**If system pods failing:**
```bash
# Describe problematic pod
kubectl describe pod <pod-name> -n kube-system

# Check events
kubectl get events -n kube-system --sort-by='.lastTimestamp'
```

## Layer 3: Istio Verification

### Objective

Verify Istio is installed, ingress gateway is running, and can route HTTP traffic through nip.io domain.

### Verification Steps

#### 1. Check Istio Pods

```bash
# List Istio system pods
kubectl get pods -n istio-system

# Expected pods:
# - istiod-* (Istio control plane)
# - istio-ingressgateway-* (Ingress gateway)
```

**✅ Success criteria:**
- istiod pod(s): Running
- istio-ingressgateway pod(s): Running
- All pods ready (e.g., 1/1, 2/2)

#### 2. Check Ingress Gateway Service

```bash
# Get ingress gateway service
kubectl get svc istio-ingressgateway -n istio-system

# Expected:
# NAME                   TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
# istio-ingressgateway   NodePort   10.96.XX.XX     <none>        80:30080/TCP,443:XXXXX/TCP   5m
```

**✅ Success criteria:**
- Service type: NodePort
- Port 80 mapped to NodePort 30080
- Service has ClusterIP assigned

#### 3. Check Default Gateway

```bash
# List gateways
kubectl get gateway -A

# Expected:
# NAMESPACE       NAME              AGE
# istio-system    default-gateway   5m

# Check gateway details
kubectl get gateway default-gateway -n istio-system -o yaml
```

**✅ Success criteria:**
- default-gateway exists in istio-system
- Hosts include "*.127.0.0.1.nip.io"
- Selector matches ingress gateway

#### 4. Deploy Test Application

```bash
# Create nginx deployment
kubectl create deployment nginx --image=nginx:latest

# Expose as ClusterIP
kubectl expose deployment nginx --port=80 --type=ClusterIP

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

# Wait for nginx pod to be ready
kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s
```

#### 5. Test HTTP Access (Critical)

```bash
# Test HTTP access with timeout
curl --max-time 30 --connect-timeout 30 -v http://nginx.127.0.0.1.nip.io

# Expected output:
# < HTTP/1.1 200 OK
# < server: istio-envoy
# ...
# <!DOCTYPE html>
# <html>
# <head>
# <title>Welcome to nginx!</title>
```

**✅ Success criteria:**
- HTTP status: 200 OK
- Response includes nginx welcome page
- Server header shows istio-envoy
- No connection timeout
- No connection refused

#### 6. Cleanup Test Resources

```bash
# Remove test resources
kubectl delete virtualservice nginx
kubectl delete svc nginx
kubectl delete deployment nginx
```

### Verification Checklist

```
Istio Layer Verification:
□ istiod pod is Running
□ istio-ingressgateway pod is Running
□ istio-ingressgateway service is NodePort 30080
□ default-gateway exists and configured
□ Test nginx deployment created successfully
□ Test VirtualService created successfully
□ HTTP request to nginx.127.0.0.1.nip.io returns 200 OK
□ Response includes istio-envoy server header
□ Test resources cleaned up

Result: ✅ PASS / ❌ FAIL
```

### Fix Suggestions

**If Istio pods not running:**
```bash
# Check pod status
kubectl describe pod -n istio-system <pod-name>

# Reinstall Istio
kubectl delete namespace istio-system
kubectl apply -f ./.config/local/istio.yaml
```

**If HTTP request fails:**

**Connection refused:**
- Check ingress gateway service: `kubectl get svc -n istio-system`
- Verify NodePort 30080 assigned
- Check kind port mapping in ./.config/local/kind.yaml

**HTTP 404:**
- Verify VirtualService: `kubectl get virtualservice`
- Check Gateway hosts: `kubectl get gateway default-gateway -n istio-system -o yaml`
- Ensure nginx service exists: `kubectl get svc nginx`

**Connection timeout:**
- Check nginx pod is running: `kubectl get pods -l app=nginx`
- Test direct pod access: `kubectl port-forward pod/<nginx-pod> 8080:80`
- Verify Istio sidecar injection (if enabled)

## Comprehensive Verification (All Layers)

### Full Stack Test

Execute all layer verifications in sequence:

```bash
# 1. Verify Docker
echo "=== Layer 1: Docker ==="
docker run --rm hello-world

# 2. Verify Kubernetes
echo "=== Layer 2: Kubernetes ==="
kubectl get nodes
kubectl cluster-info

# 3. Verify Istio
echo "=== Layer 3: Istio ==="
# Deploy test app and test HTTP access (steps above)
```

### Output Format

Present results as checklist:

```
Local Kubernetes Development Stack Verification

=== Docker Layer ===
✅ Docker context: lima-docker (active)
✅ lima instance: Running
✅ Docker hello-world: Success

=== Kubernetes Layer ===
✅ kubectl context: kind-kind
✅ Nodes: 3/3 Ready (1 control-plane, 2 workers)
✅ System pods: All running
✅ API health: ok

=== Istio Layer ===
✅ istiod: Running
✅ Ingress gateway: Running (NodePort 30080)
✅ Default gateway: Configured
✅ HTTP test (nginx.127.0.0.1.nip.io): 200 OK

Overall Status: ✅ ALL LAYERS VERIFIED
```

## Troubleshooting Application Access

### When User Can't Access Application

If user reports application is inaccessible, perform systematic layer-by-layer diagnosis:

**Step 1: Verify Application Pod**
```bash
kubectl get pods -l app=<app-name>
# Check: Pod is Running and Ready
```

**Step 2: Verify Service**
```bash
kubectl get svc <service-name>
# Check: Service exists, has ClusterIP, correct ports
```

**Step 3: Verify VirtualService**
```bash
kubectl get virtualservice <virtualservice-name> -o yaml
# Check: Correct host, gateway reference, destination
```

**Step 4: Test Direct Pod Access**
```bash
kubectl port-forward pod/<pod-name> 8080:<app-port>
curl http://localhost:8080
# Check: Application responds directly
```

**Step 5: Test Service Access**
```bash
kubectl port-forward svc/<service-name> 8080:<service-port>
curl http://localhost:8080
# Check: Service routes to pod correctly
```

**Step 6: Test Ingress Gateway**
```bash
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
curl http://localhost:8080 -H "Host: app.127.0.0.1.nip.io"
# Check: Ingress gateway processes request
```

**Step 7: Test Full Path**
```bash
curl -v http://app.127.0.0.1.nip.io
# Check: Complete routing path works
```

### Investigation Flowchart

```
Can't access app.127.0.0.1.nip.io
  ↓
Is pod running? → NO → Fix pod (check logs, describe)
  ↓ YES
Does service exist? → NO → Create/fix service
  ↓ YES
Does VirtualService exist? → NO → Create VirtualService
  ↓ YES
Can access pod directly (port-forward)? → NO → Fix application
  ↓ YES
Can access via service (port-forward)? → NO → Fix service selector/ports
  ↓ YES
Can access via ingress (port-forward)? → NO → Fix VirtualService routing
  ↓ YES
Does nip.io resolve? → NO → Check DNS, use curl -H Host
  ↓ YES
Is kind port mapping configured? → NO → Recreate kind cluster with extraPortMappings
  ↓ YES
Check Istio logs and configuration
```

## Additional Resources

### Reference Files

- **`references/timeout-configuration.md`** - Timeout values for different operations
- **`references/debugging-techniques.md`** - Advanced debugging for each layer

### Quick Verification Commands

```bash
# Docker
docker run --rm hello-world

# Kubernetes
kubectl get nodes && kubectl cluster-info

# Istio
kubectl get pods -n istio-system && curl --max-time 30 http://nginx.127.0.0.1.nip.io
```

Focus on systematic layer-by-layer verification, clear success criteria, and actionable fix suggestions for reliable local development environment validation.
