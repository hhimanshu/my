#!/bin/bash

# List all tasks on the project board
set -e

CONFIG_FILE=".github/project-config.json"

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    exit 1
fi

# Read project ID from config
PROJECT_ID=$(jq -r '.projectId' "$CONFIG_FILE")

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ] || [ "$PROJECT_ID" = "" ]; then
    echo "Error: Project ID not configured"
    echo "Run: ./scripts/init-project.sh"
    exit 1
fi

echo "Fetching tasks from project..."
echo ""

# Get all items
ITEMS=$(gh api graphql -f query="
query {
  node(id: \"$PROJECT_ID\") {
    ... on ProjectV2 {
      items(first: 50) {
        nodes {
          id
          content {
            __typename
            ... on DraftIssue {
              title
              body
            }
            ... on Issue {
              number
              title
              url
            }
            ... on PullRequest {
              number
              title
              url
            }
          }
          fieldValues(first: 8) {
            nodes {
              __typename
              ... on ProjectV2ItemFieldTextValue {
                text
                field {
                  ... on ProjectV2Field {
                    name
                  }
                }
              }
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field {
                  ... on ProjectV2SingleSelectField {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}")

# Parse and display items
echo "$ITEMS" | jq -r '
.data.node.items.nodes[] |
"ID: \(.id)",
"Type: \(.content.__typename)",
(if .content.__typename == "DraftIssue" then
  "Title: \(.content.title)"
elif .content.__typename == "Issue" or .content.__typename == "PullRequest" then
  "Title: \(.content.title)",
  "URL: \(.content.url)"
else
  "Title: N/A"
end),
(if .fieldValues.nodes | length > 0 then
  "Fields:",
  (.fieldValues.nodes[] | "  \(.field.name): \(.name // .text)")
else
  "Fields: None"
end),
"---"
'
