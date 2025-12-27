# Team Plugins

A collection of Claude Code plugins designed to streamline new member onboarding and accelerate team productivity.

## Overview

This repository contains reusable Claude Code plugins that automate common setup tasks and provide standardized development environments for engineering teams. These plugins help new engineers get up and running quickly with consistent configurations and best practices.

## Available Plugins

### k8s-local-setup

Automates the complete setup of a local Kubernetes development environment on macOS.

**What it does:**
- Sets up Docker via lima (limactl + docker-rootful template)
- Creates a Kubernetes cluster using kind
- Configures Istio ingress gateway for local routing
- Manages tool versions with mise
- Applies team-specific Custom Resource Definitions (CRDs)

**Key Features:**
- Interactive guided setup with sensible defaults
- Layer-based architecture (Docker → Kubernetes → Istio)
- Comprehensive verification at each layer
- Cascading deletion support
- Automatic troubleshooting when setup fails

**Quick Start:**
```bash
claude plugin install team-plugins/k8s-local-setup
/k8s-local-setup:setup-all
```

[View full documentation →](./k8s-local-setup/README.md)

## Installation

### Install from Repository

```bash
# Install specific plugin
claude plugin install team-plugins/k8s-local-setup

# Or clone and use locally during development
git clone https://github.com/TakiTake/team-plugins.git
claude --plugin-dir ./team-plugins/k8s-local-setup
```

### For Plugin Developers

```bash
# Clone the repository
git clone https://github.com/TakiTake/team-plugins.git
cd team-plugins

# Each plugin is in its own directory
cd k8s-local-setup

# Test locally
claude --plugin-dir .
```

## Repository Structure

```
team-plugins/
├── .claude-plugin/
│   └── marketplace.json       # Plugin marketplace configuration
├── k8s-local-setup/           # Kubernetes local setup plugin
│   ├── agents/                # Autonomous agents (troubleshooting)
│   ├── commands/              # Slash commands (16 commands)
│   ├── skills/                # Knowledge skills (6 skills)
│   └── README.md              # Plugin-specific documentation
└── README.md                  # This file
```

## Use Cases

### New Team Member Onboarding

When a new engineer joins your team:
1. They install Claude Code
2. They run the k8s-local-setup plugin
3. Within minutes, they have a fully configured local Kubernetes environment matching the team's standards

### Standardized Development Environments

- Ensures all team members use consistent tool versions
- Applies team-specific configurations automatically
- Reduces "works on my machine" issues
- Provides troubleshooting support when things go wrong

### Infrastructure as Code for Local Development

- Configuration is version controlled
- Team-wide updates are distributed as plugin updates
- Easy rollback if configurations need to change
- Documentation is embedded in the plugin itself

## Plugin Capabilities

The plugins in this repository leverage Claude Code's full feature set:

- **Slash Commands**: Quick access to common operations
- **Agents**: Autonomous troubleshooting and complex workflows
- **Skills**: Knowledge base for domain-specific expertise
- **Hooks**: Event-driven automation (planned)
- **MCP Integration**: External tool integration (planned)

## Prerequisites

- **macOS** (current plugins target macOS)
- **Claude Code** installed and configured
- **Homebrew** for package management

## Configuration

Plugin configurations are stored in `.claude/` directory:
- `.claude/settings.local.json` - Environment variables
- `.claude/k8s-setup.local.md` - k8s-local-setup configuration

Generated files are stored in `.config/local/` (gitignored).

## Contributing

Contributions are welcome! To add a new plugin:

1. Create a new directory for your plugin
2. Follow Claude Code plugin structure guidelines
3. Update `.claude-plugin/marketplace.json`
4. Add comprehensive documentation
5. Submit a pull request

### Plugin Development Guidelines

- Include a detailed README.md in your plugin directory
- Provide clear error messages and troubleshooting guidance
- Use agents for complex multi-step workflows
- Use skills for domain knowledge that Claude needs
- Test thoroughly on a clean system
- Follow the existing plugin structure patterns

## Roadmap

Planned additions:
- [ ] Database setup plugins (PostgreSQL, MySQL, MongoDB)
- [ ] IDE configuration plugins (VS Code, IntelliJ)
- [ ] Git workflow automation plugins
- [ ] Monitoring and observability setup
- [ ] CI/CD pipeline templates
- [ ] API testing environment setup

## Support

For issues or questions:
- Check plugin-specific README files
- Use Claude Code's built-in help: `/help`
- Open an issue in this repository
- Review command output and logs in `.config/local/`

## License

MIT

## Maintainer

**TakiTake**
Email: takitake.create@gmail.com

---

**Made for teams who value fast onboarding and consistent development environments.**
