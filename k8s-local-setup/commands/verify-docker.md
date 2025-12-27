---
description: Verify Docker layer is working correctly
allowed-tools: Bash(*)
model: haiku
---

Verify Docker (lima) layer following verification-strategies skill.

**Checks:**
1. Docker context: lima-docker is active
2. lima instance: Running and SSH Ready
3. docker ps: Command succeeds
4. docker run --rm hello-world: Returns "Hello from Docker!"

Show checklist with ✅/❌ for each check.
If any check fails, suggest fixes.
