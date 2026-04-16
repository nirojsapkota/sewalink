---
description: Remove a GSD workspace and clean up worktrees
argument-hint: "<workspace-name>"
tools:
  bash: true
  read: true
  question: true
---
<context>
**Arguments:**
- `<workspace-name>` (required) — Name of the workspace to remove
</context>

<objective>
Remove a workspace directory after confirmation. For worktree strategy, runs `git worktree remove` for each member repo first. Refuses if any repo has uncommitted changes.
</objective>

<execution_context>
@/Users/niroj/projects/project_ideas/sewaLink/.kilo/get-shit-done/workflows/remove-workspace.md
@/Users/niroj/projects/project_ideas/sewaLink/.kilo/get-shit-done/references/ui-brand.md
</execution_context>

<process>
Execute the remove-workspace workflow from @/Users/niroj/projects/project_ideas/sewaLink/.kilo/get-shit-done/workflows/remove-workspace.md end-to-end.
</process>
