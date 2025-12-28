---
name: Lima Docker Environment Setup
description: This skill should be used when the user needs to "setup Docker with lima", "create lima VM", "configure lima resources", "use docker-rootful template", "setup Docker on Mac", or manage lima-based Docker environments.
version: 0.2.0
---

# Lima Docker Environment Setup

Setup Docker environment on Mac using lima (Linux virtual machines on macOS) with the docker-rootful template.

## Purpose

lima provides lightweight Linux VMs on macOS for running containerized workloads. This skill guides setting up Docker using lima's docker-rootful template, configuring VM resources, and integrating with Docker CLI.

## When to Use

Use this skill when:
- Setting up Docker environment on Mac without Docker Desktop
- Configuring lima VM with custom CPU, memory, storage
- Creating docker-rootful based lima instances
- Parsing lima output to extract Docker context information
- Managing existing lima instances

## Lima Overview

**lima:** Linux virtual machines on macOS (https://github.com/lima-vm/lima)
**docker-rootful template:** Pre-configured lima template for Docker with root access
**Template location:** https://github.com/lima-vm/lima/blob/master/templates/docker-rootful.yaml

## Resource Configuration

### Default Resources

- **CPU:** 4 cores
- **Memory:** 8 GB
- **Storage:** 10 GB

### Preset Options

- **8-16-20:** 8 cores, 16GB memory, 20GB storage
- **Custom:** User-specified in format `CPU-MEMORY-STORAGE` (e.g., `6-12-15`)

### Prompting User for Resources

```
Select lima VM resources:

1. Default (4 cores, 8GB memory, 10GB storage)
2. High (8 cores, 16GB memory, 20GB storage)
3. Custom (specify CPU-MEMORY-STORAGE format, e.g., 6-12-15)

Choice:
```

## Lima Template Configuration

### Fetching docker-rootful Template

```bash
# Download latest docker-rootful template
curl -fsSL https://raw.githubusercontent.com/lima-vm/lima/master/templates/docker-rootful.yaml -o ./.config/local/lima.yaml
```

### Modifying Template for Custom Resources

Update downloaded template with user-specified resources:

```bash
# Set CPU cores (default: 4)
sed -i '' "s/cpus: [0-9]*/cpus: 6/" ./.config/local/lima.yaml

# Set memory (in GiB, default: 8)
sed -i '' "s/memory: \"[0-9]*GiB\"/memory: \"12GiB\"/" ./.config/local/lima.yaml

# Set disk size (in GiB, default: 10)
sed -i '' "s/disk: \"[0-9]*GiB\"/disk: \"15GiB\"/" ./.config/local/lima.yaml
```

**Template customization process:**
1. Download docker-rootful.yaml template
2. Parse user resource selection (default/preset/custom)
3. Update cpus, memory, disk fields
4. Save to `./.config/local/lima.yaml`
5. Use customized config for lima creation

## Creating Lima Instance

### Instance Naming

**Convention:** Use descriptive name (e.g., `docker`, `k8s-docker`)
**Docker context:** Will be `lima-{instance-name}`

Example: Instance name `docker` creates context `lima-docker`

### Create Instance with Template

```bash
# Create lima instance with custom config
limactl start --name={LIMA_INSTANCE_NAME} ./.config/local/lima.yaml
```

**Flags:**
- `--name=NAME`: Instance name (required)
- Template file: Path to lima configuration YAML

### Instance Creation Output

limactl outputs important information during creation:

```
To run `docker` on the host (assumes docker-cli is installed), run the following commands:
------
docker context create lima-docker --docker "host=unix:///Users/username/.lima/docker/sock/docker.sock"
docker context use lima-docker
docker run hello-world
------
```

**Parse this output to:**
1. Extract docker context name (`lima-docker`)
2. Extract socket path
3. Run suggested commands
4. Save context name for .claude/settings.local.json

## Docker Context Configuration

### Creating Docker Context

After lima instance starts, create Docker context:

```bash
# Extract from limactl output
docker context create lima-docker --docker "host=unix:///Users/$(whoami)/.lima/docker/sock/docker.sock"
```

### Setting Active Context

```bash
# Set as current context
docker context use lima-docker

# Verify
docker context ls
docker ps
```

### Verification

```bash
# Test Docker works
docker run --rm hello-world

# Should output: "Hello from Docker!"
```

## Managing Existing Instances

### Check Existing Instances

```bash
# List all lima instances
limactl list

# Check specific instance
limactl list | grep docker
```

**Output format:**
```
NAME     STATUS    SSH       ARCH      CPUS   MEMORY   DISK
docker   Running   Ready     aarch64   4      8GiB     10GiB
```

### Instance States

- **Running:** Instance is active
- **Stopped:** Instance exists but not running
- **Not exists:** No instance with that name

### Handling Existing Instances

**If instance exists and running:**
```
Lima instance 'docker' already exists and is running.

Options:
1. Skip setup (use existing instance)
2. Stop and recreate (will lose data)
3. Cancel

Choice:
```

**If instance exists but stopped:**
```bash
# Start existing instance
limactl start docker
```

## Integration with Plugin Settings

### Updating Configuration File

After creating instance, save configuration to `.claude/k8s-setup.local.md`:

```yaml
---
lima:
  vm_name: "{LIMA_INSTANCE_NAME}"
  cpu: 4
  memory: 8
  storage: 10
---
```

### Updating Docker Context in Claude Settings

Update `.claude/settings.local.json`:

```bash
# Set DOCKER_CONTEXT environment variable
# (Use claude-settings-management skill)
jq '.env.DOCKER_CONTEXT = "lima-docker"' .claude/settings.local.json
```

## Complete Setup Workflow

1. **Prompt user for resources** (default/preset/custom)
2. **Download docker-rootful template** to `./.config/local/lima.yaml`
3. **Customize template** with user-specified resources
4. **Check for existing instance** with same name
5. **Handle existing instance** (skip/recreate/cancel)
6. **Create lima instance** with `limactl start`
7. **Parse limactl output** for Docker context commands
8. **Create Docker context** from parsed commands
9. **Set Docker context as active**
10. **Verify** with `docker run hello-world`
11. **Update .claude/k8s-setup.local.md** with configuration
12. **Update .claude/settings.local.json** with DOCKER_CONTEXT

## Stopping and Deleting Instances

### Stop Instance

```bash
# Stop running instance
limactl stop docker
```

### Delete Instance

```bash
# Delete instance (removes all data)
limactl delete docker

# Force delete without confirmation
limactl delete --force docker
```

### Cleanup Docker Context

```bash
# Remove Docker context
docker context rm lima-docker
```

## Error Handling

### lima Not Installed

```bash
# Check if limactl exists
if ! command -v limactl &> /dev/null; then
  echo "lima is not installed. Install with: mise install lima@1.0.0"
  exit 1
fi
```

### Template Download Fails

```bash
# Retry with timeout
if ! curl -fsSL --max-time 30 \
  https://raw.githubusercontent.com/lima-vm/lima/master/templates/docker-rootful.yaml \
  -o ./.config/local/lima.yaml; then
  echo "Failed to download docker-rootful template"
  exit 1
fi
```

### Instance Creation Fails

```bash
# Check lima logs
limactl shell docker -- cat /var/log/cloud-init-output.log

# Or delete and retry
limactl delete --force docker
limactl start --name={LIMA_INSTANCE_NAME} ./.config/local/lima.yaml
```

## Troubleshooting

### Docker Commands Fail

**Symptom:** `docker ps` returns connection error

**Solution:**
```bash
# Check lima instance is running
limactl list

# Check Docker context
docker context ls
docker context use lima-docker

# Test socket connection
ls /Users/$(whoami)/.lima/docker/sock/docker.sock
```

### Socket Permission Denied

**Symptom:** Permission denied accessing docker.sock

**Solution:**
```bash
# Restart lima instance
limactl stop docker
limactl start docker
```

### Resource Limits

**Symptom:** VM fails to start with resource error

**Solution:**
- Reduce CPU/memory/storage allocation
- Check available system resources
- Close other VMs or resource-intensive apps

## Additional Resources

### Reference Files

- **`references/lima-architecture.md`** - How lima works, VM internals
- **`references/template-customization.md`** - Advanced template modifications

### Template Source

docker-rootful template: https://github.com/lima-vm/lima/blob/master/templates/docker-rootful.yaml

Use WebFetch to get latest template version and available options.

Focus on resource configuration, template customization, and Docker context management for reliable lima-based Docker environments.
