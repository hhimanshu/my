#!/bin/bash

# List tasks with target dates, sorted by due date
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

echo "Fetching tasks with due dates..."
echo ""

# Get all items with target dates
gh api graphql -f query="
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
            }
            ... on Issue {
              title
            }
          }
          fieldValues(first: 10) {
            nodes {
              __typename
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field {
                  ... on ProjectV2SingleSelectField {
                    name
                  }
                }
              }
              ... on ProjectV2ItemFieldDateValue {
                date
                field {
                  ... on ProjectV2Field {
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
}" | jq -r '
.data.node.items.nodes[] |
{
  title: .content.title,
  status: (.fieldValues.nodes[] | select(.field.name == "Status") | .name),
  area: (.fieldValues.nodes[] | select(.field.name == "Area") | .name),
  targetDate: (.fieldValues.nodes[] | select(.field.name == "Target date") | .date)
} |
select(.targetDate) |
"\(.targetDate) | \(.status // "No status") | \(.area // "No area") | \(.title)"
' | sort | awk -F' \\| ' '{
  printf "%-12s | %-15s | %-10s | %s\n", $1, $2, $3, $4
}'
