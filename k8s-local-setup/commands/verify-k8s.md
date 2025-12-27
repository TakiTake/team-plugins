---
description: Verify Kubernetes cluster is working correctly
allowed-tools: Bash(*)
model: haiku
---

Verify Kubernetes (kind) layer following verification-strategies skill.

**Checks:**
1. kubectl context: kind-kind
2. Cluster info: Control plane and CoreDNS running
3. Nodes: All Ready
4. kube-system pods: All Running
5. API health: /healthz returns "ok"

Show checklist with ✅/❌ for each check.
If any check fails, suggest fixes.
