---
description: Delete Custom Resource Definitions from cluster
argument-hint: [crd-location]
allowed-tools: Bash(*), AskUserQuestion, Read
model: sonnet
---

Delete Custom Resource Definitions (CRDs) from the local Kubernetes cluster.

**CRD Location:** Git repository URL, local path, or kustomization directory

**Workflow:**
1. Determine CRD location (from argument, config file, or ask user)
2. Verify cluster accessible
3. Show CRDs that will be deleted: `kubectl get crd`
4. **Warning:** Ask user for confirmation (deleting CRDs deletes all custom resources)
5. Delete CRDs: `kubectl delete -k {CRD_LOCATION}`
6. Verify deletion: `kubectl get crd`
7. Update .claude/k8s-setup.local.md (remove CRD location)

Report completion and warn if any resources failed to delete.
