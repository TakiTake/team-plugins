---
description: Setup Docker environment using lima
allowed-tools: Bash(*), AskUserQuestion, Read, Write
model: sonnet
---

Setup Docker environment on Mac using lima with docker-rootful template.

**Use lima-docker skill for detailed guidance.**

**Workflow:**
1. Prompt user for lima instance name (default: "docker")
2. Prompt user for lima VM resources (4-8-10 default, 8-16-20 high, or custom)
3. Download and customize docker-rootful template → ./.config/local/lima.yaml
4. Check for existing lima instance with specified name
5. Create lima instance: `limactl start --name={LIMA_INSTANCE_NAME} ./.config/local/lima.yaml`
6. Parse output for Docker context commands
7. Create Docker context: `docker context create lima-{LIMA_INSTANCE_NAME} --docker "host=unix://..."`
8. Set context active: `docker context use lima-{LIMA_INSTANCE_NAME}`
9. Verify: `docker run --rm hello-world`
10. Update .claude/settings.local.json with DOCKER_CONTEXT=lima-{LIMA_INSTANCE_NAME} (ask user first)
11. Update mise.local.toml with DOCKER_CONTEXT:
    ```bash
    # Read DOCKER_CONTEXT from Claude settings
    DOCKER_CONTEXT_VALUE=$(jq -r '.env.DOCKER_CONTEXT // empty' .claude/settings.local.json)

    # Update or create mise.local.toml
    if [ -f mise.local.toml ]; then
      # File exists - update DOCKER_CONTEXT using jq-like tool or recreate [env] section
      # For simplicity, append or update the DOCKER_CONTEXT line
      if grep -q "DOCKER_CONTEXT" mise.local.toml; then
        sed -i '' "s|DOCKER_CONTEXT = .*|DOCKER_CONTEXT = \"$DOCKER_CONTEXT_VALUE\"|" mise.local.toml
      else
        # Add DOCKER_CONTEXT to existing [env] section or create it
        if grep -q "\[env\]" mise.local.toml; then
          sed -i '' "/\[env\]/a\\
DOCKER_CONTEXT = \"$DOCKER_CONTEXT_VALUE\"
" mise.local.toml
        else
          echo -e "\n[env]\nDOCKER_CONTEXT = \"$DOCKER_CONTEXT_VALUE\"" >> mise.local.toml
        fi
      fi
    else
      # File doesn't exist - create it
      cat > mise.local.toml <<EOF
[env]
DOCKER_CONTEXT = "$DOCKER_CONTEXT_VALUE"
EOF
    fi
    ```
12. Save config to .claude/k8s-setup.local.md with instance name

Report success and show next steps: `/k8s-local-setup:setup-k8s`
