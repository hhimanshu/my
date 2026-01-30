#!/bin/bash

# Create a task directly on the project board (as draft issue)
# Prompts for Area and Due Date
set -e

CONFIG_FILE=".github/project-config.json"

# Colors for better UX
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Interactive mode if no arguments provided
if [ $# -eq 0 ]; then
    echo -e "${BLUE}Creating a new task...${NC}"
    echo ""

    # Get title
    read -p "Task title: " TITLE
    if [ -z "$TITLE" ]; then
        echo "Error: Title is required"
        exit 1
    fi

    # Get description
    read -p "Description (optional): " BODY

    # Get area
    echo ""
    echo -e "${BLUE}Select Area:${NC}"
    AREAS=($(jq -r '.fields.area.options | keys[]' "$CONFIG_FILE"))

    if [ ${#AREAS[@]} -gt 0 ]; then
        for i in "${!AREAS[@]}"; do
            echo "  $((i+1)). ${AREAS[$i]}"
        done
        echo "  0. Skip"
        echo ""
        read -p "Select area (1-${#AREAS[@]}, 0 to skip): " AREA_CHOICE

        if [ "$AREA_CHOICE" -gt 0 ] && [ "$AREA_CHOICE" -le "${#AREAS[@]}" ]; then
            AREA="${AREAS[$((AREA_CHOICE-1))]}"
        else
            AREA=""
        fi
    else
        echo -e "${YELLOW}No areas configured. Run ./scripts/init-project.sh${NC}"
        AREA=""
    fi

    # Get due date
    echo ""
    echo -e "${BLUE}Set Due Date:${NC}"
    echo "  1. Today"
    echo "  2. Tomorrow"
    echo "  3. This week (Friday)"
    echo "  4. Next week"
    echo "  5. Custom date"
    echo "  0. Skip"
    echo ""
    read -p "Select option (0-5): " DATE_CHOICE

    case $DATE_CHOICE in
        1)
            DUE_DATE=$(date +%Y-%m-%d)
            ;;
        2)
            DUE_DATE=$(date -v+1d +%Y-%m-%d 2>/dev/null || date -d "+1 day" +%Y-%m-%d)
            ;;
        3)
            # Find next Friday
            DUE_DATE=$(date -v+fri +%Y-%m-%d 2>/dev/null || date -d "next friday" +%Y-%m-%d)
            ;;
        4)
            DUE_DATE=$(date -v+7d +%Y-%m-%d 2>/dev/null || date -d "+7 days" +%Y-%m-%d)
            ;;
        5)
            read -p "Enter date (YYYY-MM-DD): " DUE_DATE
            ;;
        *)
            DUE_DATE=""
            ;;
    esac

else
    # Command line arguments mode
    TITLE="$1"
    BODY="${2:-}"
    AREA="${3:-}"
    DUE_DATE="${4:-}"
fi

echo ""
echo -e "${GREEN}Creating task...${NC}"
echo "  Title: $TITLE"
[ -n "$BODY" ] && echo "  Description: $BODY"
[ -n "$AREA" ] && echo "  Area: $AREA"
[ -n "$DUE_DATE" ] && echo "  Due Date: $DUE_DATE"
echo ""

# Create draft issue
RESULT=$(gh api graphql -f query="
mutation {
  addProjectV2DraftIssue(input: {
    projectId: \"$PROJECT_ID\"
    title: \"$TITLE\"
    body: \"$BODY\"
  }) {
    projectItem {
      id
    }
  }
}")

ITEM_ID=$(echo "$RESULT" | jq -r '.data.addProjectV2DraftIssue.projectItem.id')

if [ -z "$ITEM_ID" ] || [ "$ITEM_ID" = "null" ]; then
    echo "Error: Failed to create task"
    echo "$RESULT"
    exit 1
fi

echo -e "${GREEN}✓ Task created successfully${NC}"
echo "Item ID: $ITEM_ID"

# Note: Draft issues cannot have assignees. Assignees only work for real GitHub issues.
# All tasks are implicitly yours since this is your personal project board.

# Set Area if provided
if [ -n "$AREA" ]; then
    AREA_FIELD_ID=$(jq -r '.fields.area.id' "$CONFIG_FILE")
    AREA_OPTION_ID=$(jq -r --arg area "$AREA" '.fields.area.options[$area]' "$CONFIG_FILE")

    if [ -n "$AREA_FIELD_ID" ] && [ "$AREA_FIELD_ID" != "null" ] && [ -n "$AREA_OPTION_ID" ] && [ "$AREA_OPTION_ID" != "null" ]; then
        gh api graphql -f query="
        mutation {
          updateProjectV2ItemFieldValue(input: {
            projectId: \"$PROJECT_ID\"
            itemId: \"$ITEM_ID\"
            fieldId: \"$AREA_FIELD_ID\"
            value: {
              singleSelectOptionId: \"$AREA_OPTION_ID\"
            }
          }) {
            projectV2Item {
              id
            }
          }
        }" > /dev/null
        echo -e "${GREEN}✓ Area set to: $AREA${NC}"
    fi
fi

# Set Target Date if provided
if [ -n "$DUE_DATE" ]; then
    TARGET_DATE_FIELD_ID=$(jq -r '.fields.targetDate.id' "$CONFIG_FILE")

    if [ -n "$TARGET_DATE_FIELD_ID" ] && [ "$TARGET_DATE_FIELD_ID" != "null" ]; then
        gh api graphql -f query="
        mutation {
          updateProjectV2ItemFieldValue(input: {
            projectId: \"$PROJECT_ID\"
            itemId: \"$ITEM_ID\"
            fieldId: \"$TARGET_DATE_FIELD_ID\"
            value: {
              date: \"$DUE_DATE\"
            }
          }) {
            projectV2Item {
              id
            }
          }
        }" > /dev/null
        echo -e "${GREEN}✓ Target date set to: $DUE_DATE${NC}"
    fi
fi

echo ""
echo "To update status, run:"
echo "  ./scripts/update-status.sh $ITEM_ID [STATUS]"
