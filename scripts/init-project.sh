#!/bin/bash

# Initialize project configuration
set -e

CONFIG_FILE=".github/project-config.json"

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub"
    echo "Run: gh auth login --scopes \"project\""
    exit 1
fi

USERNAME=$(jq -r '.username' "$CONFIG_FILE")
PROJECT_NUMBER=$(jq -r '.projectNumber' "$CONFIG_FILE")

echo "Fetching project ID for user: $USERNAME, project: $PROJECT_NUMBER"

# Get project ID
PROJECT_ID=$(gh api graphql -f query="
query {
  user(login: \"$USERNAME\") {
    projectV2(number: $PROJECT_NUMBER) {
      id
      title
    }
  }
}" --jq '.data.user.projectV2.id')

if [ -z "$PROJECT_ID" ]; then
    echo "Error: Could not fetch project ID"
    exit 1
fi

echo "Project ID: $PROJECT_ID"

# Update config with project ID
jq --arg pid "$PROJECT_ID" '.projectId = $pid' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

# Get field information
echo "Fetching project fields..."

FIELDS_JSON=$(gh api graphql -f query="
query {
  node(id: \"$PROJECT_ID\") {
    ... on ProjectV2 {
      fields(first: 20) {
        nodes {
          ... on ProjectV2Field {
            id
            name
          }
          ... on ProjectV2SingleSelectField {
            id
            name
            options {
              id
              name
            }
          }
        }
      }
    }
  }
}")

echo "$FIELDS_JSON" | jq '.'

echo ""
echo "✓ Configuration initialized successfully"
echo "Update $CONFIG_FILE with the field IDs and options you want to use"
