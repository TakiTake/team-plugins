---
name: mise Usage and Version Management
description: This skill should be used when the user needs to "install tools with mise", "manage tool versions", "create mise.toml", "update mise.local.toml", "configure mise settings", or work with mise for version management of lima, kind, kubectl, istioctl, and helm.
version: 0.2.0
---

# mise Usage and Version Management

Manage development tool versions using mise (https://github.com/jdx/mise) for consistent environments across team members and projects.

## Purpose

mise is a polyglot runtime manager (asdf successor) that manages tool versions through configuration files. This skill provides guidance for using mise to manage local Kubernetes development tools: lima, kind, kubectl, istioctl, and helm.

## When to Use

Use this skill when:
- Installing and managing mise itself
- Creating or updating mise.toml (shared settings)
- Creating or updating mise.local.toml (personal settings)
- Installing tools at specific versions
- Checking which tool versions are active
- Troubleshooting mise installation or tool availability

## mise Installation

### Check if mise is Installed

```bash
if command -v mise &> /dev/null; then
  echo "mise is installed: $(mise --version)"
else
  echo "mise is not installed"
fi
```

### Install mise via Homebrew

```bash
brew install mise
```

### Activate mise in Shell

After installation, mise needs to be activated in the shell:

**For bash:**
```bash
echo 'eval "$(mise activate bash)"' >> ~/.bashrc
source ~/.bashrc
```

**For zsh:**
```bash
echo 'eval "$(mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc
```

**Verification:**
```bash
mise doctor
```

## Configuration Files

### mise.toml (Shared Settings)

**Location:** Project root
**Purpose:** Team-wide tool versions (committed to git)
**Format:** TOML

**Example:**
```toml
[tools]
lima = "1.0.0"
kind = "0.31.0"
kubectl = "1.31.14"
istioctl = "1.24.0"
helm = "3.16.0"
```

### mise.local.toml (Personal Settings)

**Location:** Project root
**Purpose:** Personal overrides (in .gitignore)
**Format:** TOML

**Example:**
```toml
[tools]
# Override kubectl version for local testing
kubectl = "1.32.11"

[env]
# Personal environment variables
KUBECONFIG = "./.config/local/kubeconfig"
```

### Settings Hierarchy

mise resolves settings in this order (later overrides earlier):
1. `mise.toml` (shared)
2. `mise.local.toml` (personal)
3. Environment variables

## Tool Management

### Install Tools from Configuration

```bash
# Install all tools from mise.toml
mise install

# Install specific tool
mise install kind@0.31.0
```

### Check Installed Versions

```bash
# List all installed tools and versions
mise list

# Show current active versions
mise current

# Check specific tool
mise current kind
```

### Add Tool to Configuration

**To mise.toml (shared):**
```bash
mise use --global lima@1.0.0
# Or edit mise.toml manually
```

**To mise.local.toml (personal):**
```bash
mise use --env local kind@0.31.0
# Or edit mise.local.toml manually
```

## Creating Configuration Files

### Creating mise.toml

Create shared team configuration:

```bash
cat > mise.toml <<'EOF'
[tools]
lima = "1.0.0"
kind = "0.31.0"
kubectl = "1.31.14"
istioctl = "1.24.0"
helm = "3.16.0"
EOF
```

Then install tools:

```bash
mise install
```

### Creating mise.local.toml

Create personal overrides:

```bash
cat > mise.local.toml <<'EOF'
[tools]
# Personal tool version overrides

[env]
# Personal environment variables
DOCKER_CONTEXT = "lima-docker"
KUBECONFIG = "./.config/local/kubeconfig"
EOF
```

## Tool-Specific Usage

### lima

```bash
# Install lima
mise install lima@1.0.0

# Verify installation
mise exec lima -- limactl --version

# Or if mise is activated
limactl --version
```

### kind

```bash
# Install kind
mise install kind@0.31.0

# Use kind
kind version

# Create cluster
kind create cluster
```

### kubectl

```bash
# Install kubectl
mise install kubectl@1.31.14

# Verify
kubectl version --client

# Use kubectl
kubectl cluster-info
```

### istioctl

```bash
# Install istioctl
mise install istioctl@1.24.0

# Verify
istioctl version
```

### helm

```bash
# Install helm
mise install helm@3.16.0

# Verify
helm version
```

## Best Practices

### Shared vs Personal Settings

**mise.toml (commit to git):**
- Tool versions required by project
- Shared team standards
- CI/CD tool versions

**mise.local.toml (add to .gitignore):**
- Personal tool version preferences
- Local environment variables
- Development-specific overrides

### Version Specification

**Exact versions (recommended for stability):**
```toml
[tools]
kind = "0.31.0"  # Exact version
```

**Version ranges (use cautiously):**
```toml
[tools]
kubectl = "1.31"  # Latest 1.31.x
helm = "3"        # Latest 3.x.x
```

### .gitignore Configuration

Add to `.gitignore`:

```gitignore
# mise local settings
mise.local.toml
.mise.local.toml
```

## Workflow Integration

### Initial Project Setup

```bash
# 1. Install mise
brew install mise

# 2. Activate in shell
eval "$(mise activate $(basename $SHELL))"

# 3. Create mise.toml
cat > mise.toml <<'EOF'
[tools]
lima = "1.0.0"
kind = "0.31.0"
kubectl = "1.31.14"
istioctl = "1.24.0"
helm = "3.16.0"
EOF

# 4. Install tools
mise install

# 5. Verify
mise list
```

### New Team Member Onboarding

```bash
# 1. Clone repository
git clone <repo>
cd <repo>

# 2. Install mise (if not installed)
brew install mise

# 3. Activate mise
eval "$(mise activate $(basename $SHELL))"

# 4. Install all project tools
mise install

# 5. Ready to develop!
kind version
kubectl version
```

## Troubleshooting

### mise Command Not Found

**Cause:** mise not in PATH or not activated

**Solution:**
```bash
# Add to shell config
eval "$(mise activate zsh)"  # or bash

# Or full path
/opt/homebrew/bin/mise install
```

### Tool Not Found After Installation

**Cause:** Shell needs to be reloaded or mise not activated

**Solution:**
```bash
# Reload shell config
source ~/.zshrc  # or ~/.bashrc

# Or use mise exec
mise exec kind -- kind version
```

### Version Mismatch

**Cause:** mise.local.toml overriding mise.toml

**Solution:**
```bash
# Check which version is active
mise current kind

# See where version comes from
mise where kind

# Remove local override if needed
rm mise.local.toml
```

### Installation Fails

**Cause:** Tool backend not available or network issues

**Solution:**
```bash
# Check mise doctor
mise doctor

# Try specific tool manually
mise install kind@0.31.0 --verbose

# Check available versions
mise list-all kind
```

## Online Documentation

For latest documentation, refer to official mise docs:

**Primary documentation:** https://github.com/jdx/mise/tree/main/docs

**Key sections:**
- **Getting Started:** https://github.com/jdx/mise/blob/main/docs/getting-started.md
- **Configuration:** https://github.com/jdx/mise/blob/main/docs/configuration.md
- **Tool Management:** https://github.com/jdx/mise/blob/main/docs/cli.md

**Use WebFetch to access current documentation when needed:**

```
Fetch https://github.com/jdx/mise/tree/main/docs to get latest mise documentation
```

## Additional Resources

### Reference Files

- **`references/tool-backends.md`** - Available tool backends and version sources
- **`examples/mise-toml-templates.md`** - Template configurations for different scenarios

### Quick Commands Reference

```bash
# Installation
mise install                    # Install all tools from config
mise install kind@0.31.0       # Install specific version

# Version management
mise list                       # Show installed tools
mise current                    # Show active versions
mise where kind                 # Show tool installation path

# Configuration
mise use lima@1.0.0            # Add to mise.toml
mise use --env local kind@0.31.0  # Add to mise.local.toml

# Troubleshooting
mise doctor                     # Check mise setup
mise list-all kind             # Show available versions
mise which kind                # Show path to active tool
```

Focus on using mise.toml for shared team settings and mise.local.toml for personal preferences to maintain consistent development environments.
