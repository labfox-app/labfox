# CLAUDE.md

@AGENTS.md

`AGENTS.md` above holds this repository's shared rules and is the **source of truth**.
To change a rule, edit `AGENTS.md`. Keep this file limited to Claude Code specifics.

---

## Language

**Everything written into this repository is English** — code, comments, docs, commit messages,
issues, and PRs. See the language policy at the top of `AGENTS.md`.

The user may talk to you in Korean or any other language. Reply in whatever language they use,
but **what you write to disk, to git, and to GitHub is always English.**

## Skills

Project skills live in **`.agents/skills/`**, not `.claude/skills/`.
`.claude/skills` is a symlink to `.agents/skills`; the real files are all under `.agents/`.
To add a skill, create `.agents/skills/<name>/SKILL.md`.

| Skill | When to use |
|---|---|
| `gitlab-api-endpoint` | Adding or changing a GitLab endpoint in `packages/gitlab_api` |
| `feature-slice` | Adding a new screen or feature under `apps/labfox/lib/features/` |
| `design-system-component` | Adding a shared widget to `packages/design_system` |
| `responsive-screen` | Branching a screen across mobile / tablet / desktop |

## Reference docs

Read these only when relevant — do not load them into context by default.

- `.agents/docs/architecture.md` — layer responsibilities, data flow, caching strategy
- `.agents/docs/conventions.md` — naming, file placement, freezed/Riverpod rules
- `.agents/docs/api-reference.md` — GitLab endpoint map, auth, pagination, terminology
- `.agents/docs/monetization.md` — per-OS distribution, free/paid boundary, store entitlement
- `.agents/docs/roadmap.md` — M0–M4, vertical slice, 1.0 scope
- `.agents/docs/workflow.md` — Issue → Branch → PR procedure, `gh` commands, permission boundaries
- `.agents/docs/references.md` — reference repos and docs, priority order, license warnings

## Workflow

The origin remote is **GitHub** (`theorvane/labfox`). The CLI is **`gh`**.

```
Issue → Branch → Commit (-s) → Push → PR → Merge (maintainer)
```

⚠️ LabFox is a GitLab client but is developed on GitHub.
**App domain vocabulary is Merge Request; the development process is Pull Request.** Do not mix them.

Fine without asking: creating issues, creating branches, committing, pushing, opening PRs.
Never: pushing directly to `main`, force pushing, **merging a PR**, deleting issues/PRs/branches.

## Subagents

**Use of the Agent tool is permitted.** You do not need to ask each time.

Good fits:

- Surveying reference repositories (OctoLab, LabCoat, …) — read-only and high volume
- Checking several GitLab API endpoints in parallel
- Implementing independent feature slices
- Broad code exploration (`Explore`)
- PR review / code inspection

Rules:

- Tell the subagent in its prompt to **read and follow `AGENTS.md`** — especially the language
  policy, the license rules (§8), the `id`/`iid` distinction, and the 1.0 scope (§9).
- Never run parallel agents that touch the same files. Isolate with `isolation: "worktree"`
  or run them sequentially.
- Do not delegate pushing or merging to a subagent.
- Do not take a subagent's output at face value. **Verify API paths and licenses yourself.**
- Launch independent work concurrently in a single message.

## Habits

- **Work test-first** (`AGENTS.md` §5a): write the failing test before the code, and for a bug
  reproduce it as a failing test first. A behaviour change without a test that would have failed
  before it is not done.
- Read neighboring files at the same layer before writing code, and match their patterns.
- Propose new dependencies and get approval first (`AGENTS.md` §4).
- Touching a model is not done until `build_runner` has been run.
- Report `flutter analyze` / `flutter test` output as it is. A failure is reported as a failure.
