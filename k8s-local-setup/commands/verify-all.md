---
description: Comprehensive verification of all environment layers
allowed-tools: Bash(*), Read
model: sonnet
---

Perform comprehensive verification of Docker, Kubernetes, and Istio layers following the verification-strategies skill.

**Use verification-strategies skill for detailed guidance on each verification step.**

---

## Verification Approach

Verify layers bottom-up (low to high):
1. Docker layer
2. Kubernetes layer
3. Istio layer

Stop at first failing layer and provide diagnostics.

Timeout for all network operations: 30 seconds

---

## Layer 1: Docker Verification

### Check Docker Context

```bash
docker context ls | grep "*"
```

**✅ Success criteria:** lima-docker context is active (marked with *)

### Check lima Instance

```bash
limactl list | grep docker
```

**✅ Success criteria:** Status=Running, SSH=Ready

### Test Docker Operations

```bash
docker ps
```

**✅ Success criteria:** Command succeeds (even if no containers)

### Run Hello World

```bash
docker run --rm hello-world
```

**✅ Success criteria:** Output includes "Hello from Docker!"

### Checklist Output

```
Docker Layer Verification:
□ Docker context 'lima-docker' is active
□ lima instance 'docker' is Running
□ lima instance SSH is Ready
□ docker ps command succeeds
□ docker run hello-world succeeds

Result: ✅ PASS / ❌ FAIL
```

**If FAIL:** Stop verification, show error, suggest fixes:
- Docker context not active → `docker context use lima-docker`
- lima not running → `limactl start docker`

---

## Layer 2: Kubernetes Verification

### Check kubectl Context

```bash
kubectl config current-context
```

**✅ Success criteria:** Returns "kind-kind"

### Check Cluster Info

```bash
kubectl cluster-info --request-timeout=30s
```

**✅ Success criteria:** Control plane and CoreDNS running, no errors

### Check Node Status

```bash
kubectl get nodes
```

**✅ Success criteria:** All nodes STATUS=Ready

### Check System Pods

```bash
kubectl get pods -n kube-system
```

**✅ Success criteria:** All pods Running or Completed, none in CrashLoopBackOff

### Test API Health

```bash
kubectl get --raw /healthz --request-timeout=30s
```

**✅ Success criteria:** Returns "ok"

### Checklist Output

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

**If FAIL:** Stop verification, show error, suggest fixes:
- Context wrong → `kubectl config use-context kind-kind`
- Nodes not ready → `kubectl describe node {node-name}`
- Pods failing → `kubectl logs -n kube-system {pod-name}`

---

## Layer 3: Istio Verification

### Check Istio Pods

```bash
kubectl get pods -n istio-system
```

**✅ Success criteria:** istiod and istio-ingressgateway pods Running and Ready

### Check Ingress Gateway Service

```bash
kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'
```

**✅ Success criteria:** Returns 30080

### Check Default Gateway

```bash
kubectl get gateway default-gateway -n istio-system -o yaml
```

**✅ Success criteria:** Gateway exists, hosts include "*.127.0.0.1.nip.io"

### Deploy Test Application

```bash
# Create nginx
kubectl create deployment nginx --image=nginx:latest
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

# Wait for pod
kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s
```

### Test HTTP Access (CRITICAL)

```bash
curl --max-time 30 --connect-timeout 30 -v http://nginx.127.0.0.1.nip.io
```

**✅ Success criteria:**
- HTTP status: 200 OK
- Response includes nginx welcome page
- Server header shows istio-envoy

### Cleanup Test Resources

```bash
kubectl delete virtualservice nginx
kubectl delete svc nginx
kubectl delete deployment nginx
```

### Checklist Output

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

**If FAIL:** Show error and suggest fixes:
- Istio pods not running → `kubectl describe pod -n istio-system {pod-name}`
- HTTP connection refused → Check ingress gateway service and kind port mapping
- HTTP 404 → Verify VirtualService and Gateway configuration
- Connection timeout → Check nginx pod, test direct access with port-forward

---

## Overall Verification Summary

Present comprehensive results:

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

Your local Kubernetes development environment is fully operational!
```

---

## Fix Suggestions

If any layer fails, provide specific fix suggestions based on the error:

**Docker layer failures:**
- Context issues: Docker context commands
- lima issues: limactl commands
- Permission issues: Socket permissions

**Kubernetes layer failures:**
- Context issues: kubectl config commands
- Node issues: Describe node, check events
- Pod issues: Logs, describe, resource availability

**Istio layer failures:**
- Pod issues: Reinstall Istio
- Gateway issues: Check configuration
- HTTP issues: Step-by-step debugging (pod → service → ingress → full path)

---

**If all layers pass:** Congratulate user and confirm environment is ready for development.

**If any layer fails:** Offer to trigger setup-troubleshooter agent for detailed diagnosis and automatic fix suggestions.
