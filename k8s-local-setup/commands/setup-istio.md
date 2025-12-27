---
description: Setup Istio service mesh with ingress gateway
allowed-tools: Bash(*), Read, Write
model: sonnet
---

Setup Istio with ingress gateway for local development routing.

**Use istio-ingress skill for detailed guidance.**

**Workflow:**
1. Verify Kubernetes cluster is ready
2. Run precheck: `istioctl x precheck`
3. **Generate manifest with nodePort configuration:**
   ```bash
   # Read container port from saved kind configuration
   CONTAINER_PORT=$(grep "container_port:" .claude/k8s-setup.local.md | awk '{print $2}')

   # Generate manifest with nodePort set to match kind mapping
   istioctl manifest generate --set profile=demo \
     --set components.ingressGateways[0].k8s.service.ports[1].nodePort=${CONTAINER_PORT} \
     > ./.config/local/istio.yaml
   ```
4. Apply manifest: `kubectl apply -f ./.config/local/istio.yaml`
5. Wait for pods: istiod and istio-ingressgateway
6. Verify NodePort matches container port: `kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}'`
7. Create default Gateway for *.127.0.0.1.nip.io
8. Deploy test nginx with VirtualService
9. Test HTTP: `curl http://nginx.127.0.0.1.nip.io` (expect 200 OK)
10. Cleanup test resources
11. Save config to .claude/k8s-setup.local.md

Report success and show routing pattern: {app}.127.0.0.1.nip.io
