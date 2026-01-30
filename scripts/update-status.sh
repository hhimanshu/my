#!/bin/bash

# Update task status
set -e

CONFIG_FILE=".github/project-config.json"

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 ITEM_ID STATUS"
    echo ""
    echo "Available statuses (configure in $CONFIG_FILE):"
    jq -r '.fields.status.options | to_entries[] | "  - \(.key)"' "$CONFIG_FILE" 2>/dev/null || echo "  Run init-project.sh first"
    exit 1
fi

ITEM_ID="$1"
STATUS_NAME="$2"

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    exit 1
fi

# Read configuration
PROJECT_ID=$(jq -r '.projectId' "$CONFIG_FILE")
STATUS_FIELD_ID=$(jq -r '.fields.status.id' "$CONFIG_FILE")
STATUS_OPTION_ID=$(jq -r --arg status "$STATUS_NAME" '.fields.status.options[$status]' "$CONFIG_FILE")

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ] || [ "$PROJECT_ID" = "" ]; then
    echo "Error: Project ID not configured. Run: ./scripts/init-project.sh"
    exit 1
fi

if [ -z "$STATUS_FIELD_ID" ] || [ "$STATUS_FIELD_ID" = "null" ] || [ "$STATUS_FIELD_ID" = "" ]; then
    echo "Error: Status field not configured in $CONFIG_FILE"
    exit 1
fi

if [ -z "$STATUS_OPTION_ID" ] || [ "$STATUS_OPTION_ID" = "null" ]; then
    echo "Error: Status '$STATUS_NAME' not found in configuration"
    echo ""
    echo "Available statuses:"
    jq -r '.fields.status.options | to_entries[] | "  - \(.key)"' "$CONFIG_FILE"
    exit 1
fi

echo "Updating task status to: $STATUS_NAME"

# Update field value
RESULT=$(gh api graphql -f query="
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: \"$PROJECT_ID\"
    itemId: \"$ITEM_ID\"
    fieldId: \"$STATUS_FIELD_ID\"
    value: {
      singleSelectOptionId: \"$STATUS_OPTION_ID\"
    }
  }) {
    projectV2Item {
      id
    }
  }
}")

if echo "$RESULT" | jq -e '.errors' > /dev/null 2>&1; then
    echo "Error updating status:"
    echo "$RESULT" | jq '.errors'
    exit 1
fi

echo "✓ Status updated successfully"
