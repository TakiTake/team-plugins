---
description: Update configuration interactively
allowed-tools: Read, Write, Bash(*), AskUserQuestion
model: sonnet
---

Update local K8s environment configuration interactively.

**Configurable settings:**
- Lima instance name (default: "docker")
- Lima VM resources (CPU, memory, storage)
- Kind cluster name (default: "kind")
- Kind worker count
- Kubernetes version
- Port mappings
- CRD location

**Workflow:**
1. Read current config from .claude/k8s-setup.local.md (if exists)
2. Show current values
3. Ask user which settings to update (use AskUserQuestion)
4. For each setting user wants to change:
   - Show current value
   - Prompt for new value
   - Validate input
5. Show configuration diff (old → new)
6. Ask user to confirm changes
7. Update ./.config/local/{lima.yaml,kind.yaml} as needed
8. Save to .claude/k8s-setup.local.md
9. **Important:** Ask if user wants to apply changes now:
   - If yes: Offer to re-run setup for changed layers
   - If no: Save config for next setup

**Support non-interactive mode:** Accept arguments like `--cpu=8 --memory=16`

Report updated configuration and whether re-setup is needed.
