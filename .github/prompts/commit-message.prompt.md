# Commit Message Generator

Generate a clear, meaningful git commit message based on the staged changes.

## Rules

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

## Instructions

1. Use `get_changed_files` with `sourceControlState: ['staged']` to read the staged diff.
2. Analyze the diff to understand what changed and why.
3. Group related changes under a single type if possible.
4. If changes span multiple unrelated areas, suggest splitting into separate commits.
5. Output ONLY the commit message — no explanation or commentary.

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