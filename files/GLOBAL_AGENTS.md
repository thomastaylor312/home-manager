# Development Guidelines

## Planning

For complex work, break it into 3-5 stages and track them with the harness's native planning/todo
tooling. If, and only if, a longer-lived artifact is useful, document the stages in an
`IMPLEMENTATION_PLAN.md` and remove it once all stages are done:

```markdown
## Stage N: [Name]
**Goal**: [Specific deliverable]
**Success Criteria**: [Testable outcomes]
**Tests**: [Specific test cases]
**Status**: [Not Started|In Progress|Complete]
```

## When Stuck (After 3 Attempts)

**CRITICAL**: Maximum 3 attempts per issue, then STOP.

1. **Document what failed**:
   - What you tried
   - Specific error messages
   - Why you think it failed

2. **Research alternatives**:
   - Find 2-3 similar implementations
   - Note different approaches used

3. **Question fundamentals**:
   - Is this the right abstraction level?
   - Can this be split into smaller problems?
   - Is there a simpler approach entirely?

4. **Try different angle**:
   - Different library/framework feature?
   - Different architectural pattern?
   - Remove abstraction instead of adding?

## Tooling & Workflow

- Use the project's existing build system, test framework, and formatter/linter
  settings. Don't introduce new tools without strong justification.
- Use jujutsu `jj` instead of git for most projects when searching for diffs and
  commit information. If `jj` errors due to it not being a jj repo, fall back to git.
- If asked to look at a specific GitHub issue (or issues on any other code forge),
  YOU MUST read the entire issue thread, including linked issues and PRs, to
  understand the full context before starting work.

## Hard Rules

**NEVER**:
- Use `--no-verify` to bypass commit hooks
- Disable tests instead of fixing them
- Commit code that doesn't compile
- Make assumptions - verify with existing code
