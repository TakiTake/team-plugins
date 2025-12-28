---
name: Claude Settings Management
description: This skill should be used when the user needs to "update Claude Code environment variables", "modify .claude/settings.local.json", "set DOCKER_CONTEXT", "configure KUBECONFIG", or manage Claude Code settings for local development environment.
version: 0.2.0
---

# Claude Settings Management

Manage Claude Code environment variables and settings for local development environments by updating `.claude/settings.local.json`.

## Purpose

Claude Code allows configuring environment variables that affect tool execution (like Bash, Docker commands, kubectl commands) through `.claude/settings.local.json`. This skill provides guidance for programmatically updating these settings, particularly for DOCKER_CONTEXT and KUBECONFIG used in local Kubernetes development.

## When to Use

Use this skill when:
- Setting up Docker environment to point to lima context
- Configuring kubectl to use local kubeconfig file
- Updating environment variables after provisioning infrastructure
- Managing project-specific Claude Code settings

## Settings File Location

**.claude/settings.local.json** at project root

This file contains:
```json
{
  "env": {
    "DOCKER_CONTEXT": "lima-docker",
    "KUBECONFIG": "./.config/local/kubeconfig",
    "OTHER_VAR": "value"
  }
}
```

## Updating Environment Variables

### File Existence Check

Before updating, check if `.claude/settings.local.json` exists:

```bash
if [ -f .claude/settings.local.json ]; then
  # File exists, update it
else
  # File doesn't exist, create it
fi
```

### Creating New Settings File

If file doesn't exist, create directory and file:

```bash
mkdir -p .claude
cat > .claude/settings.local.json <<'EOF'
{
  "env": {
    "DOCKER_CONTEXT": "lima-docker",
    "KUBECONFIG": "./.config/local/kubeconfig"
  }
}
EOF
```

### Updating Existing Settings File

When updating existing file, **overwrite specific env var values** while preserving others:

**Using jq (recommended):**
```bash
# Read current settings
current=$(cat .claude/settings.local.json)

# Update DOCKER_CONTEXT
echo "$current" | jq '.env.DOCKER_CONTEXT = "lima-docker"' > .claude/settings.local.json

# Update KUBECONFIG
current=$(cat .claude/settings.local.json)
echo "$current" | jq '.env.KUBECONFIG = "./.config/local/kubeconfig"' > .claude/settings.local.json
```

**Using sed (if jq not available):**
```bash
# For DOCKER_CONTEXT
sed -i '' 's/"DOCKER_CONTEXT": ".*"/"DOCKER_CONTEXT": "lima-docker"/' .claude/settings.local.json

# For KUBECONFIG
sed -i '' 's|"KUBECONFIG": ".*"|"KUBECONFIG": "./.config/local/kubeconfig"|' .claude/settings.local.json
```

### User Confirmation

**Always ask user before updating settings:**

```
The setup requires updating .claude/settings.local.json with:
- DOCKER_CONTEXT: lima-docker
- KUBECONFIG: ./.config/local/kubeconfig

This allows Claude Code to use the correct Docker context and Kubernetes config.

Do you want to proceed? (yes/no)
```

Wait for user confirmation before making changes.

## Environment Variables for This Plugin

### DOCKER_CONTEXT

**Purpose:** Points Docker commands to lima-based Docker instance

**Format:** `lima-{instance-name}`

**Example:** `lima-docker`

**Set after:** Docker (lima) setup completes successfully

**Verification:**
```bash
# Check context exists
docker context ls | grep lima-docker

# Test context works
docker --context lima-docker ps
```

### KUBECONFIG

**Purpose:** Points kubectl to local kind cluster kubeconfig

**Format:** Relative path from project root

**Example:** `./.config/local/kubeconfig`

**Set before:** Kubernetes (kind) setup starts

**Verification:**
```bash
# Check file exists
ls ./.config/local/kubeconfig

# Test kubeconfig works
KUBECONFIG=./.config/local/kubeconfig kubectl cluster-info
```

## Best Practices

### Path Conventions

**Relative paths:** Use paths relative to project root
```json
{
  "env": {
    "KUBECONFIG": "./.config/local/kubeconfig"
  }
}
```

**Not absolute paths:**
```json
{
  "env": {
    "KUBECONFIG": "/Users/username/project/.config/local/kubeconfig"  // ❌ Don't do this
  }
}
```

### Preserving Existing Settings

When updating, preserve other environment variables:

```bash
# ✅ Good - preserves other vars
jq '.env.DOCKER_CONTEXT = "lima-docker"' .claude/settings.local.json

# ❌ Bad - replaces entire file
echo '{"env":{"DOCKER_CONTEXT":"lima-docker"}}' > .claude/settings.local.json
```

### File Permissions

Ensure proper permissions for settings file:

```bash
chmod 644 .claude/settings.local.json
```

## Workflow Integration

### Docker Setup Flow

1. Setup lima VM with Docker
2. Start lima instance
3. Parse docker context name from limactl output
4. **Ask user for confirmation**
5. Update DOCKER_CONTEXT in .claude/settings.local.json
6. Verify docker commands work

### Kubernetes Setup Flow

1. **Ask user for confirmation**
2. **Set KUBECONFIG before kind setup**
3. Create kind cluster with KUBECONFIG pointing to ./.config/local/kubeconfig
4. Verify kubectl commands work

## Error Handling

### Invalid JSON

Check JSON validity before and after updates:

```bash
# Validate JSON
jq empty .claude/settings.local.json 2>/dev/null
if [ $? -eq 0 ]; then
  echo "✅ Valid JSON"
else
  echo "❌ Invalid JSON - aborting update"
  exit 1
fi
```

### Backup Strategy

No automatic backup needed (as per requirements), but:
- Ask user before updating
- Show what will be changed
- Validate JSON after update

### Missing .claude Directory

Create directory if missing:

```bash
mkdir -p .claude
```

## Complete Update Script Example

See `examples/update-settings.sh` for a complete, production-ready script that:
- Checks file existence
- Asks for user confirmation
- Preserves existing settings
- Validates JSON
- Handles errors gracefully

## Additional Resources

### Reference Files

- **`references/settings-schema.md`** - Complete settings.local.json schema documentation
- **`examples/update-settings.sh`** - Production-ready update script

### Context Value Verification

After updating settings, verify values are correctly applied:

```bash
# Show current settings
cat .claude/settings.local.json | jq .env

# Test DOCKER_CONTEXT
docker context use $(jq -r '.env.DOCKER_CONTEXT' .claude/settings.local.json)
docker ps

# Test KUBECONFIG
export KUBECONFIG=$(jq -r '.env.KUBECONFIG' .claude/settings.local.json)
kubectl cluster-info
```

Focus on user confirmation, preserving existing settings, and validating changes for reliable settings management.
