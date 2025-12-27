# Claude Code settings.local.json Schema

## Overview

The `.claude/settings.local.json` file configures project-specific Claude Code settings, particularly environment variables that affect tool execution.

## File Location

```
project-root/
└── .claude/
    └── settings.local.json
```

## Complete Schema

```json
{
  "env": {
    "ENV_VAR_NAME": "value",
    "ANOTHER_VAR": "value"
  }
}
```

## Fields

### env (object)

Key-value pairs of environment variables to set when executing tools.

**Type:** Object with string keys and string values

**Example:**
```json
{
  "env": {
    "DOCKER_CONTEXT": "lima-docker",
    "KUBECONFIG": "./.config/local/kubeconfig",
    "PATH": "/custom/bin:${PATH}",
    "AWS_PROFILE": "development"
  }
}
```

## Environment Variable Behavior

### Tool Execution

When Claude Code executes tools (Bash, etc.), environment variables from `env` are:
1. Merged with system environment
2. Override system values if same key exists
3. Available to all executed commands

### Variable Expansion

**Not supported:** Shell variable expansion (`${VAR}`) is not evaluated
**Literal values only:** Values are used as-is

## Common Use Cases for This Plugin

### DOCKER_CONTEXT

**Purpose:** Specify which Docker context to use

**Format:** Context name (string)

**Example:** `"lima-docker"`

**Used by:** Docker CLI commands

**Verification:**
```bash
docker context ls
docker ps
```

### KUBECONFIG

**Purpose:** Specify kubeconfig file location

**Format:** Path (relative or absolute)

**Recommended:** Relative path from project root

**Example:** `"./.config/local/kubeconfig"`

**Used by:** kubectl commands

**Verification:**
```bash
kubectl config view
kubectl cluster-info
```

## File Management

### Creation

Create file with initial values:

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

### Updating

Update specific env var using jq:

```bash
jq '.env.DOCKER_CONTEXT = "new-value"' .claude/settings.local.json > tmp.json
mv tmp.json .claude/settings.local.json
```

Or in-place:

```bash
jq '.env.DOCKER_CONTEXT = "new-value"' .claude/settings.local.json | sponge .claude/settings.local.json
```

### Reading

Read all env vars:

```bash
jq '.env' .claude/settings.local.json
```

Read specific env var:

```bash
jq -r '.env.DOCKER_CONTEXT' .claude/settings.local.json
```

## Validation

### JSON Syntax

Validate JSON syntax:

```bash
jq empty .claude/settings.local.json
echo $?  # 0 = valid, non-zero = invalid
```

### Schema Validation

Check structure:

```bash
# Check env field exists and is object
jq 'if .env | type == "object" then "valid" else "invalid" end' .claude/settings.local.json
```

## Best Practices

### ✅ DO

- Use relative paths for project-specific files
- Validate JSON after updates
- Ask user before modifying
- Keep settings file in .gitignore
- Use descriptive env var names

### ❌ DON'T

- Use absolute paths (not portable)
- Assume file exists (check first)
- Overwrite without user confirmation
- Commit settings.local.json to git
- Store secrets (use proper secret management)

## Example Settings for K8s Local Setup

```json
{
  "env": {
    "DOCKER_CONTEXT": "lima-docker",
    "KUBECONFIG": "./.config/local/kubeconfig",
    "KIND_EXPERIMENTAL_PROVIDER": "podman"
  }
}
```

This configures:
- Docker to use lima context
- kubectl to use local kubeconfig
- kind to use experimental provider (optional)

## Troubleshooting

### File Not Found

```bash
if [ ! -f .claude/settings.local.json ]; then
  echo "Creating .claude/settings.local.json..."
  mkdir -p .claude
  echo '{"env":{}}' > .claude/settings.local.json
fi
```

### Invalid JSON

```bash
if ! jq empty .claude/settings.local.json 2>/dev/null; then
  echo "ERROR: Invalid JSON in .claude/settings.local.json"
  echo "Please fix or delete the file"
  exit 1
fi
```

### Missing env Field

```bash
# Add env field if missing
if ! jq -e '.env' .claude/settings.local.json >/dev/null 2>&1; then
  jq '. + {"env":{}}' .claude/settings.local.json > tmp.json
  mv tmp.json .claude/settings.local.json
fi
```

## Related Files

- `.claude/settings.json` - Global Claude Code settings (don't modify)
- `.claude/*.local.md` - Plugin-specific settings (different format)
- `.gitignore` - Should include `.claude/*.local.json`
