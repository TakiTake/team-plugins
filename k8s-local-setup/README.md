# k8s-local-setup

Automate local Kubernetes development environment setup on Mac with Docker (lima), kind, and Istio.

## Overview

This Claude Code plugin helps engineers onboard to your team by automating the setup of a complete local Kubernetes development environment. It handles the installation and configuration of:

- **Docker** via lima (limactl + docker-rootful template)
- **Kubernetes** cluster using kind
- **Istio** ingress gateway for routing
- **Tool version management** via mise
- **Custom Resource Definitions (CRDs)** for your team

## Features

- **Interactive Setup**: Guided configuration with sensible defaults
- **Layer-based Architecture**: Docker → Kubernetes → Istio
- **Comprehensive Verification**: Verify each layer works correctly
- **Cascading Deletion**: Deleting lower layers automatically removes dependent upper layers
- **Configuration Persistence**: Save and reuse your preferences
- **Troubleshooting**: Automatic diagnostics when setup fails
- **mise Integration**: Respects tool versions in mise.toml

## Prerequisites

- **macOS** (required)
- **Homebrew** (required)
- **Claude Code** (required)
- **mise** will be installed if not present

## Installation

```bash
# Install the plugin
cc plugin install k8s-local-setup

# Or use locally during development
cc --plugin-dir /path/to/k8s-local-setup
```

## Quick Start

```bash
# Full environment setup (interactive)
/k8s-local-setup:setup-all

# Check status
/k8s-local-setup:status

# Verify everything works
/k8s-local-setup:verify-all
```

## Routing Architecture

Applications deployed to the local cluster are accessible via browser through this routing chain:

```
Browser (http://app-name.127.0.0.1.nip.io)
  ↓
Host:80
  ↓
kind NodePort:30080
  ↓
Istio Ingress Gateway:30080 → 8080
  ↓
Kubernetes Service (ClusterIP)
  ↓
Pod
```

Each app repository only needs namespace-scoped manifest files. VirtualServices use the pattern: `http://{{app-name}}.127.0.0.1.nip.io`

## Commands

### Setup Commands

- `/k8s-local-setup:setup-all` - Interactive full environment setup
- `/k8s-local-setup:setup-docker` - Setup Docker/lima layer only
- `/k8s-local-setup:setup-k8s` - Setup Kubernetes/kind layer only
- `/k8s-local-setup:setup-istio` - Setup Istio layer only

### Verification Commands

- `/k8s-local-setup:verify-all` - Verify all layers
- `/k8s-local-setup:verify-docker` - Verify Docker layer only
- `/k8s-local-setup:verify-k8s` - Verify Kubernetes layer only
- `/k8s-local-setup:verify-istio` - Verify Istio layer only

### Deletion Commands

- `/k8s-local-setup:delete-all` - Delete all layers
- `/k8s-local-setup:delete-istio` - Delete Istio only
- `/k8s-local-setup:delete-k8s` - Delete Kubernetes and Istio
- `/k8s-local-setup:delete-docker` - Delete all layers (cascading)

### CRD Management

- `/k8s-local-setup:apply-crd` - Apply Custom Resource Definitions
- `/k8s-local-setup:delete-crd` - Delete Custom Resource Definitions

### Configuration & Status

- `/k8s-local-setup:status` - Show current setup status
- `/k8s-local-setup:configure` - Update configuration interactively

## Configuration

### Default Resources

**Lima VM**:
- CPU: 4 cores
- Memory: 8GB
- Storage: 10GB

**Kind Cluster**:
- Control plane: 1 node
- Workers: 2 nodes

**Kubernetes Version**: Latest stable (fetched from kind release notes)

**Istio Profile**: demo (suitable for local development)

### Custom Configuration

Configuration is saved in `.claude/k8s-setup.local.md`:

```yaml
---
lima:
  vm_name: "{LIMA_INSTANCE_NAME}"
  cpu: 4
  memory: 8
  storage: 10

kind:
  cluster_name: "{KIND_CLUSTER_NAME}"
  workers: 2
  k8s_version: "1.31.14"
  k8s_image: "kindest/node:v1.31.14@sha256:..."
  host_port: 80
  container_port: 30080

istio:
  profile: "demo"

crd:
  location: "/path/to/crds"

last_setup_date: "2025-12-27"
---
```

### Generated Configuration Files

The plugin generates configuration files in `./.config/local/`:

- `lima.yaml` - Lima VM configuration
- `kind.yaml` - Kind cluster configuration
- `istio.yaml` - Istio manifest
- `kubeconfig` - Kubernetes config file

### Environment Variables

The plugin automatically updates `.claude/settings.local.json`:

- `DOCKER_CONTEXT` - Set to lima context (e.g., `lima-docker`)
- `KUBECONFIG` - Set to `./.config/local/kubeconfig`

## mise Integration

This plugin respects `mise.toml` and `mise.local.toml` for tool version management:

**Managed tools**:
- lima
- kind
- istioctl
- kubectl
- helm

**Example mise.toml**:
```toml
[tools]
lima = "1.0.0"
kind = "0.31.0"
kubectl = "1.31.14"
istioctl = "1.24.0"
helm = "3.16.0"
```

The plugin can create and update these files during setup.

## Troubleshooting

If setup fails, the plugin automatically runs diagnostics and suggests fixes. You can also:

1. Check status: `/k8s-local-setup:status`
2. Verify specific layer: `/k8s-local-setup:verify-docker|k8s|istio`
3. Review logs in generated config files
4. Check environment variables in `.claude/settings.local.json`

## Development

### Plugin Structure

```
k8s-local-setup/
├── .claude-plugin/
│   └── plugin.json
├── commands/          # 16 slash commands
├── agents/            # setup-troubleshooter
├── skills/            # 6 knowledge skills
└── README.md
```

### Skills

The plugin includes specialized knowledge about:
- mise usage and version management
- kind cluster setup and k8s version fetching
- Istio ingress gateway configuration
- lima Docker environment setup
- Verification strategies for each layer
- Claude Code settings management

## License

MIT

## Contributing

Contributions welcome! Please open an issue or PR.
