# Task Management with GitHub Projects

This repository uses GitHub Projects for comprehensive task management.

**Project URL**: https://github.com/users/hhimanshu/projects/5

## Task Organization

Your project uses these fields to organize and track tasks:

### Core Fields
- **Status**: Backlog → Blocked → Ready → In progress → Done
- **Area**: Finance, Legal, Work, Home (categorize by life domain)
- **Priority**: P0 (critical), P1 (high), P2 (normal)

### Planning Fields
- **Size**: XS, S, M, L, XL (task complexity/effort)
- **Estimate**: Numeric estimation (hours/days)
- **Start date**: When to begin working
- **Target date**: Completion deadline

### Progress Tracking
- **Sub-issues progress**: Automatically tracks completion of related issues
- **Parent issue**: Link to parent for hierarchical organization

## Quick Usage

### Create a New Task (Interactive)

```bash
./scripts/create-task.sh
```

This will prompt you for:
1. **Task title** (required)
2. **Description** (optional)
3. **Area** - Select from:
   - **Finance**: Budget planning, investments, taxes, financial reviews
   - **Legal**: Contracts, compliance, legal documents, regulations
   - **Work**: Professional projects, meetings, career development
   - **Home**: Personal tasks, family, household chores, maintenance
4. **Target Date** - Choose from:
   - Today
   - Tomorrow
   - This week (Friday)
   - Next week
   - Custom date (YYYY-MM-DD)
   - Skip (no target date)

The script automatically:
- **Sets the Area** you selected
- **Sets the Target Date** you chose

**Note**: Draft issues (tasks created directly on the board) cannot have assignees. Assignees only work for real GitHub issues linked to repositories. Since all tasks in this project are yours, assignee tracking isn't needed.

You can update other fields manually in GitHub Projects or use the update scripts.

### Create Task via Command Line

```bash
# Basic task
./scripts/create-task.sh "Task title"

# With description
./scripts/create-task.sh "Task title" "Description"

# With area and target date
./scripts/create-task.sh "Task title" "Description" "Finance" "2026-02-15"
```

### Other Commands

```bash
# List all tasks
./scripts/list-tasks.sh

# Update task status
./scripts/update-status.sh ITEM_ID "In progress"
# Available statuses: Backlog, Blocked, Ready, "In progress", Done
```

## Field Definitions

### Status (Workflow)
- **Backlog**: Tasks not yet scheduled or prioritized
- **Blocked**: Waiting on dependencies or external factors
- **Ready**: Prioritized and ready to start
- **In progress**: Actively working on it
- **Done**: Completed

### Priority (Urgency)
- **P0**: Critical - drop everything else
- **P1**: High priority - schedule this week
- **P2**: Normal priority - schedule when possible

### Size (Effort Estimation)
- **XS**: < 1 hour (quick fix, simple update)
- **S**: 1-2 hours (small feature, minor refactor)
- **M**: 3-5 hours (moderate feature, research task)
- **L**: 1-2 days (major feature, complex problem)
- **XL**: 3+ days (large project, architectural change)

### Area (Life Domain)
- **Finance**: Money management, investments, tax planning
- **Legal**: Contracts, legal reviews, compliance
- **Work**: Professional tasks, projects, career
- **Home**: Personal life, family, household

## Setup

Your project is already configured! The config file at `.github/project-config.json` has all field IDs populated.

To authenticate (if needed):
```bash
gh auth login --scopes "project"
```

## Configuration

All field IDs are now set in `.github/project-config.json`:

```json
{
  "username": "hhimanshu",
  "projectNumber": 5,
  "projectId": "PVT_kwHOAGSKbM4BN5HU",
  "fields": {
    "status": { "id": "...", "options": {...} },
    "priority": { "id": "...", "options": {...} },
    "size": { "id": "...", "options": {...} },
    "area": { "id": "...", "options": {...} },
    "estimate": { "id": "..." },
    "startDate": { "id": "..." },
    "targetDate": { "id": "..." }
  }
}
```

**Note**: Draft issues don't support assignees. Since this is your personal project board, all tasks are implicitly yours.

## Workflow Recommendations

### When Creating Tasks

1. **Always set Area** - Helps you focus and filter tasks by life domain
2. **Set Target Date for time-sensitive tasks** - Keeps you accountable
3. **Start with Ready status** - Unless it's just an idea (Backlog) or blocked
4. **Estimate Size** - Helps with planning and workload management

### Daily Workflow

```bash
# Morning: Create your tasks for the day
./scripts/create-task.sh

# Check your active tasks
./scripts/list-tasks.sh

# Move task to In Progress
./scripts/update-status.sh ITEM_ID "In progress"

# Evening: Mark completed tasks as Done
./scripts/update-status.sh ITEM_ID "Done"
```

### Weekly Review

In GitHub Projects:
1. **Filter by Area** - Review each life domain
2. **Check Target Dates** - Reschedule if needed
3. **Review Backlog** - Promote items to Ready
4. **Clear Done items** - Archive or delete completed tasks

## Tips

- **Be specific with Areas**: If unsure, think about where you'll act on this task
- **Use Size for planning**: Don't start XL tasks without breaking them down
- **Priority ≠ Urgency**: P0 should be rare. Most tasks are P2.
- **Target Date for accountability**: Set realistic dates; review weekly
- **Link Sub-issues**: Break down L/XL tasks into smaller issues

## Advanced: Manual Field Updates

For fields not covered by scripts, update directly in GitHub Projects UI or use the GraphQL API:

```bash
# Update Priority
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwHOAGSKbM4BN5HU"
    itemId: "ITEM_ID"
    fieldId: "PVTSSF_lAHOAGSKbM4BN5HUzg8wXTM"
    value: { singleSelectOptionId: "79628723" }
  }) {
    projectV2Item { id }
  }
}
'
```

Tasks are created directly on the project board as draft issues - no GitHub repository issues needed.

## Documentation

For full API documentation, see: https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects
