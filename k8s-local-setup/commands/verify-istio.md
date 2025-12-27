---
description: Verify Istio layer is working correctly
allowed-tools: Bash(*)
model: sonnet
---

Verify Istio layer following verification-strategies skill.

**Checks:**
1. istiod pod: Running
2. istio-ingressgateway pod: Running
3. Ingress gateway service: NodePort 30080 configured
4. default-gateway: Exists and configured
5. Deploy test nginx with VirtualService
6. HTTP test: nginx.127.0.0.1.nip.io returns 200 OK with istio-envoy header
7. Cleanup test resources

Show checklist with ✅/❌ for each check.
If any check fails, suggest fixes including step-by-step debugging.
