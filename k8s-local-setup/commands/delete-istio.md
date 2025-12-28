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
- Istio CRDs

Ask user for confirmation before proceeding.

**Workflow:**
1. Show what will be deleted
2. Ask confirmation
3. Check if manifest exists: `[ -f ./.config/local/istio.yaml ]`
4. If manifest exists, delete using manifest: `kubectl delete -f ./.config/local/istio.yaml`
5. Delete Istio CRDs: `kubectl delete crd $(kubectl get crd | grep istio.io | awk '{print $1}')`
6. Keep istio.yaml in ./.config/local/

**Note:** Using the manifest file ensures we delete exactly the resources that were created during setup.

Report completion and suggest: `/k8s-local-setup:setup-istio` to recreate
