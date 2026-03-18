# Commit & Pull Request Message Generator

Generate clear, meaningful git commit messages or pull request descriptions based on changes.

## Mode Detection

- **Commit mode** (default): User says "commit", or has staged changes → generate a commit message -> push to git.
- **PR mode**: User says "pull request", "PR", or "push" with context suggesting a PR → generate a PR description -> open a PR on GitHub.

---

## Commit Message Rules

### Format
```
<type>(<scope>): <subject>

<body>
```

### Type (required) — pick ONE:
| Type       | When to use                                      |
|------------|--------------------------------------------------|
| `feat`     | New feature or capability                        |
| `fix`      | Bug fix                                          |
| `refactor` | Code restructure with no behavior change         |
| `style`    | Formatting, whitespace, missing semicolons       |
| `docs`     | Documentation only                               |
| `perf`     | Performance improvement                          |
| `test`     | Adding or updating tests                         |
| `chore`    | Build config, dependencies, tooling              |
| `revert`   | Reverting a previous commit                      |

### Scope (optional) — the area of the codebase:
Examples: `hotbar`, `inventory`, `player`, `dungeon`, `crafting`, `hud`, `combat`, `items`, `skills`, `augments`, `npc`, `ui`

### Subject (required):
- Imperative mood ("add", "fix", "change" — not "added", "fixed", "changed")
- Lowercase, no period at end
- Max 50 characters
- Describe **what** the commit does, not how

### Body (when needed):
- Wrap at 72 characters
- Explain **why** the change was made, not just what
- Use bullet points (`-`) for multiple changes
- Reference related issues if any

## Commit Instructions

1. Use `get_changed_files` with `sourceControlState: ['staged']` to read the staged diff.
2. Analyze the diff to understand what changed and why.
3. Group related changes under a single type if possible.
4. If changes span multiple unrelated areas, suggest splitting into separate commits.
5. Output ONLY the commit message — no explanation or commentary.

---

## Pull Request Rules

### Format
```markdown
## <title>

### Summary
<1-3 sentence overview of the PR's purpose>

### Changes
- <bullet list of key changes, grouped by area>

### Testing
<how to verify the changes work>
```

### Title:
- Use the same `<type>(<scope>): <subject>` format as commit messages
- Should summarize the entire PR, not individual commits

### Summary:
- Explain **why** these changes were made (the problem or feature request)
- Keep it brief — 1-3 sentences max

### Changes:
- Group bullets by area/scope when the PR touches multiple systems
- Use sub-bullets for details under a group
- Reference specific files only when it adds clarity

### Testing:
- Describe manual testing steps or areas to verify
- Keep it practical — what should the reviewer check in-game?

## PR Instructions

1. Run `git log main..HEAD --oneline` to see all commits on the current branch.
2. Run `git diff main --stat` to see which files changed.
3. Run `git diff main` (or read key files) to understand the full scope of changes.
4. Synthesize commits into a cohesive PR description — don't just list commits.
5. Output ONLY the PR description — no explanation or commentary.

---

## Examples

**Single feature:**
```
feat(hotbar): add equip-swap support for equipment items

When activating an equipment item from the hotbar that swaps with
an already-equipped piece, the old equipment now appears in the
same hotbar slot instead of disappearing.
```

**Bug fix:**
```
fix(hotbar): prevent items from disappearing after inventory sort

Hotbar tracked items by inventory index which became stale after
sort. Now uses a two-pass algorithm to re-locate items by id.
```

**Refactor:**
```
refactor(inventory): extract augment stat calculation into helper
```

**Multiple related changes:**
```
fix(combat): correct damage formula and iframe timing

- Apply defense reduction before passive effects
- Increase iframe duration from 0.3s to 0.5s
- Fix thorns damage triggering on blocked hits
```

---

## PR Examples

**Feature PR:**
```markdown
## feat(npc): add smith shop with crafting and inventory

### Summary
Implements the blacksmith shop NPC with buy/sell tabs, crafting
station, and side-by-side inventory panel so players can browse
items while managing their inventory.

### Changes
- **Shop UI**: SmithShopPopup with category tabs, gold display,
  and buy/sell item rows
- **Crafting**: CraftingPanel embedded in shop with tiered recipes
- **Inventory**: Open inventory alongside shop via
  UIPopupComponent.open_inventory_alongside
- **Notifications**: Purchase success/failure feedback via
  NotificationManager

### Testing
- Interact with blacksmith → shop and inventory both open
- Buy an item → gold decreases, item appears in inventory
- Switch to Crafting tab → recipes display with ingredient checks
- Walk away → both panels close automatically
```

**Bug fix PR:**
```markdown
## fix(npc): restore smith shop interaction and inventory popup

### Summary
Fixes broken blacksmith shop interaction caused by stale node
references and type mismatches after inventory refactor.

### Changes
- Remove orphan `$Dim` reference from smith_shop_popup.gd
- Fix `_paired_inventory_panel` type from CanvasLayer to Control
- Enable `open_inventory_alongside` on blacksmith scene
- Ensure inventory renders above shop by reordering HUD children

### Testing
- Interact with blacksmith → shop opens without errors
- Inventory panel appears above the shop popup
- Closing shop also closes paired inventory
```