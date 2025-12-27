---
description: Delete Istio layer only
allowed-tools: Bash(*), AskUserQuestion
model: haiku
---

Delete only Istio layer, keeping Kubernetes cluster intact.

**Warning:** This will delete:
- istio-system namespace
- All Istio components
- Ingress gateway
- All Gateway and VirtualService resources

Ask user for confirmation before proceeding.

**Workflow:**
1. Show what will be deleted
2. Ask confirmation
3. Delete namespace: `kubectl delete namespace istio-system`
4. Delete Istio CRDs: `kubectl delete crd $(kubectl get crd | grep istio.io | awk '{print $1}')`
5. Keep istio.yaml in ./.config/local/

Report completion and suggest: `/k8s-local-setup:setup-istio` to recreate
