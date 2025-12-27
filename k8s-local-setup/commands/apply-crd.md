---
description: Apply Custom Resource Definitions to cluster
argument-hint: [crd-location]
allowed-tools: Bash(*), AskUserQuestion
model: sonnet
---

Apply Custom Resource Definitions (CRDs) to the local Kubernetes cluster using kustomize.

**CRD Location:** Git repository URL, local path, or kustomization directory

---

## Determine CRD Location

If argument provided:
- Use `$1` as CRD location

If no argument:
- Check `.claude/k8s-setup.local.md` for saved CRD location
- If not found, ask user for CRD location using AskUserQuestion

**CRD location formats:**
- Git repo: `https://github.com/org/repo//path/to/crds?ref=main`
- Local path: `/absolute/path/to/crds`
- Relative path: `./crds`

---

## Verify Kubernetes Cluster

Check cluster is accessible:

```bash
kubectl cluster-info --request-timeout=10s
```

If cluster not accessible, error and suggest:
- Run `/k8s-local-setup:verify-k8s` to check cluster status
- Run `/k8s-local-setup:setup-k8s` if cluster not setup

---

## Validate CRDs (Dry Run)

Before applying, validate CRDs using server-side dry-run:

```bash
kubectl apply --dry-run=server -k {CRD_LOCATION}
```

**If dry-run succeeds:**
- Show what will be created/updated
- List CRD names
- Ask user for confirmation

**If dry-run fails:**
- Show validation errors
- Suggest fixes:
  - Check CRD location is correct
  - Verify kustomization.yaml exists
  - Check CRD syntax
  - Ensure cluster has required permissions

---

## Apply CRDs

After user confirmation:

```bash
kubectl apply -k {CRD_LOCATION}
```

Show output of applied resources.

---

## Verify CRDs Installed

```bash
kubectl get crd
```

List all installed CRDs, highlight newly installed ones.

**Verification checks:**
- All expected CRDs appear in list
- CRDs are in "Established" condition
- No errors in CRD status

```bash
# Check CRD status
for crd in $(kubectl get crd -o name | grep {expected-pattern}); do
  kubectl get $crd -o jsonpath='{.status.conditions[?(@.type=="Established")].status}'
done
```

All should return "True".

---

## Save CRD Location

Update `.claude/k8s-setup.local.md` with CRD location:

```yaml
---
crd:
  location: "{CRD_LOCATION}"
  applied_at: "2025-12-27"
---
```

---

## Success Summary

```
✅ CRDs Applied Successfully

Location: {CRD_LOCATION}
CRDs Installed: {COUNT}

Installed CRDs:
- {crd-name-1}
- {crd-name-2}
- ...

All CRDs are Established and ready to use.
```

---

## Error Handling

**If kubectl apply fails:**
1. Show exact error message
2. Analyze error type:
   - Permission denied → Check RBAC
   - Invalid CRD → Check CRD syntax
   - Network error → Check CRD location accessibility
   - Resource conflict → Check if CRDs already exist
3. Suggest specific fixes
4. Offer to rollback if partial application occurred

**Common errors and fixes:**

**Error: "no matches for kind Kustomization"**
→ CRD location doesn't have kustomization.yaml
→ Add kustomization.yaml or use `kubectl apply -f` instead

**Error: "unable to recognize"**
→ Invalid CRD YAML syntax
→ Validate YAML with `yamllint` or online validator

**Error: "already exists"**
→ CRDs already installed
→ Use `kubectl replace` or `kubectl apply --force-conflicts`

---

## Additional Options

**Force update existing CRDs:**
```bash
kubectl apply -k {CRD_LOCATION} --force-conflicts --server-side
```

**Delete and recreate CRDs:**
Ask user confirmation (data will be lost), then:
```bash
kubectl delete -k {CRD_LOCATION}
kubectl apply -k {CRD_LOCATION}
```

---

Provide clear feedback at each step, validate before applying, and save CRD location for future reference.
