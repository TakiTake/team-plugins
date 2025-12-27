#!/bin/bash
# update-settings.sh - Update Claude Code environment variables in .claude/settings.local.json
#
# Usage:
#   ./update-settings.sh DOCKER_CONTEXT "lima-docker"
#   ./update-settings.sh KUBECONFIG "./.config/local/kubeconfig"

set -euo pipefail

SETTINGS_FILE=".claude/settings.local.json"
ENV_VAR="$1"
ENV_VALUE="$2"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}ERROR: jq is required but not installed${NC}"
    echo "Install with: brew install jq"
    exit 1
fi

# Create .claude directory if it doesn't exist
mkdir -p .claude

# Check if settings file exists
if [ ! -f "$SETTINGS_FILE" ]; then
    echo -e "${YELLOW}Creating new $SETTINGS_FILE${NC}"
    echo '{"env":{}}' > "$SETTINGS_FILE"
fi

# Validate current JSON
if ! jq empty "$SETTINGS_FILE" 2>/dev/null; then
    echo -e "${RED}ERROR: Invalid JSON in $SETTINGS_FILE${NC}"
    echo "Please fix or delete the file and try again"
    exit 1
fi

# Get current value if it exists
CURRENT_VALUE=$(jq -r ".env.${ENV_VAR} // \"(not set)\"" "$SETTINGS_FILE")

# Show what will be changed
echo -e "${YELLOW}Update $SETTINGS_FILE:${NC}"
echo "  Environment Variable: $ENV_VAR"
echo "  Current Value: $CURRENT_VALUE"
echo "  New Value: $ENV_VALUE"
echo ""

# Ask for confirmation
read -p "Proceed with update? (yes/no): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]([Ee][Ss])?$ ]]; then
    echo "Update cancelled"
    exit 0
fi

# Update the value
TMP_FILE=$(mktemp)
jq ".env.${ENV_VAR} = \"${ENV_VALUE}\"" "$SETTINGS_FILE" > "$TMP_FILE"

# Validate updated JSON
if ! jq empty "$TMP_FILE" 2>/dev/null; then
    echo -e "${RED}ERROR: Update produced invalid JSON${NC}"
    rm "$TMP_FILE"
    exit 1
fi

# Move temp file to settings file
mv "$TMP_FILE" "$SETTINGS_FILE"

echo -e "${GREEN}✅ Successfully updated $ENV_VAR${NC}"

# Show updated settings
echo ""
echo "Current environment variables:"
jq '.env' "$SETTINGS_FILE"
