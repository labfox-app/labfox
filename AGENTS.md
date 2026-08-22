# AGENTS.md — LabFox

These are the **shared rules** for every coding agent working in the LabFox repository.
Tool-specific files (`CLAUDE.md`, etc.) import this document and add only tool-specific content.

---

## Language: English only

LabFox ships to a global audience. **Everything in this repository is written in English.**

| | |
|---|---|
| Code, identifiers, comments | English |
| Documentation, `README`, `AGENTS.md`, skills | English |
| Commit messages, branch names | English |
| Issues, Pull Requests, code review | English |
| User-facing UI strings | English source (`app_en.arb`); translations live in other `app_<code>.arb` |

This is not a style preference. Contributors and users are international; anything written in
another language silently excludes them and has to be rewritten later.

- Write English directly. Do not draft in another language and translate afterwards.
- Never hardcode user-facing strings in any language — route them through localization (§5).
- If a user talks to you in another language, **still write English into the repository.**
  Conversation language and repository language are separate concerns.

---

## 1. Project

**LabFox** — a Flutter-based cross-platform GitLab **workflow client** that pairs
GitHub Mobile-grade UX with GitLab's Merge Requests, CI/CD, and self-hosted support.

Supported platforms: Android · iOS · Windows · macOS

The core user flow — the yardstick for every feature decision:

```
Check notifications → Review Issue / MR → Read diff and review → Check pipeline status
→ Read job log → Approve / Merge / Retry
```

LabFox does not port every GitLab web feature. The goal is to **make the work developers do most
often fast**. When a feature is proposed, first decide whether it serves the flow above.

### License and distribution model

LabFox follows an **open core** model.

```
Source code            Apache-2.0 open source (GitHub: theorvane/labfox)
Windows                Direct download, free, full features
macOS                  Mac App Store, free, full features
Android / iOS          Free download, subscription for the paid features
```

The app is a free download everywhere; a single auto-renewing subscription is
sold through store in-app purchase. There is no LabFox account and no LabFox
server — entitlement comes from the store the app was installed from.
Details, including the free/paid boundary: `.agents/docs/monetization.md`

The intended improvement cycle:

```
Desktop users / outside contributors
        │  contribute a PR
        ▼
   Shared Flutter codebase
        │  same features, same logic
        ▼
    Mobile app improves too
```

**The premise of this model is an architectural constraint.**
If the code is split per platform, desktop contributions never reach mobile.
So "do not build separate UIs per platform" (§10) is not taste — it is a **business requirement**.

| File | Contents |
|---|---|
| `LICENSE` | Full Apache License 2.0 text |
| `NOTICE` | Copyright notice, attribution, third-party trademark notice |
| `TRADEMARK.md` | Trademark policy — the "LabFox" name and logo are excluded from the license |
| `THIRD_PARTY_NOTICES.md` | Dependency license allow/deny list, in-app notices |
| `CONTRIBUTING.md` | How outside contributions work |
| `CODE_OF_CONDUCT.md` | Contributor Covenant, enforcement contact |
| `SECURITY.md` | Vulnerability reporting, token-handling scope |
| `SUPPORT.md` | Where to ask questions, what maintainers do not cover |

- **The "LabFox" name and logo are trademarks and are not covered by the license** (Apache-2.0 §6).
  Anyone may use the code, but nobody else may ship it to a store under the same name.
  That is what sustains the paid model.
- Because outside contributions are accepted, **copyright becomes distributed.**
  Closing the license later is effectively impossible.
- Never describe LabFox as affiliated with or endorsed by GitLab or GitHub, in code or docs.

---

## 2. Repository layout

Monorepo. The API layer is separated from the app.

```
labfox/
├── apps/
│   └── labfox/              Flutter application
├── packages/
│   ├── gitlab_api/          GitLab REST / GraphQL client (pure Dart, no Flutter dependency)
│   ├── gitlab_models/       DTOs / entities (freezed + json_serializable)
│   ├── design_system/       LabFox Design System (widgets, theme, tokens)
│   └── secure_storage/      Platform secure storage wrapper
├── .agents/                 Agent skills and detailed documentation
├── AGENTS.md                ← this document
└── CLAUDE.md                Imports AGENTS.md + Claude Code specifics
```

Inside the app, **feature first**:

```
apps/labfox/lib/
├── app/          app.dart, router.dart, theme.dart
├── core/         auth/ network/ storage/ utils/
├── features/     home/ inbox/ projects/ repository/ issues/
│                 merge_requests/ pipelines/ search/ profile/
└── main.dart
```

Each feature folder holds roughly `data/` and `presentation/`. Do not subdivide further.

---

## 3. Architecture

```
UI (Widget)
  ↓
Controller / Notifier (Riverpod AsyncNotifier)
  ↓
Repository
  ↓
GitLabClient (packages/gitlab_api)
  ↓
GitLab instance
```

Rules:

- **Do not over-apply Clean Architecture.** This is a CRUD-over-an-API app.
- **Do not create UseCase classes.** Controllers call repositories directly.
- Widgets never touch `GitLabClient` or `Dio` directly. Always go through a controller.
- `packages/gitlab_api` must not import `package:flutter`. Keep it pure Dart.
- Repositories own the data source and hide it from controllers, which do not
  know where data came from. Today this is network-only (`GitLabClient`); a
  local cache (Drift) is a planned post-1.0 layer, not yet implemented.

Details: `.agents/docs/architecture.md`

---

## 4. Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter / Dart |
| State | Riverpod (`AsyncNotifier` by default) |
| Network | Dio |
| Routing | go_router |
| Models | freezed + json_serializable |
| Local DB | Drift + SQLite (planned, post-1.0; not yet added) |
| Secrets | flutter_secure_storage |
| Localization | flutter_localizations + intl (ARB) |
| Monorepo | native pub workspace (no melos) |

Do not introduce a different state management or networking library on your own.
Propose it and get approval first.

---

## 5. Coding conventions

- Files `snake_case.dart`, classes `PascalCase`, members `lowerCamelCase`.
- All models use `freezed` + `json_serializable`. Do not hand-write `fromJson`.
- Code generation: `dart run build_runner build --delete-conflicting-outputs`.
  Never edit generated files (`*.freezed.dart`, `*.g.dart`) by hand.
- The GitLab API returns snake_case field names. Map them with
  `@JsonKey(name: 'merge_status')` and keep the Dart name camelCase.
- **Always distinguish `iid` (per-project number) from `id` (global)** for MRs and issues.
  The `!142` and `#282` a user sees are `iid`. Do not flatten the parameter name to `id`.
- Prefer `design_system` tokens and components over hardcoded values.

### Language and localization

- **All identifiers, comments, and docstrings are in English** (see the language policy above).
- **No hardcoded user-facing strings.** Every string a user can read goes through the
  generated localization delegate, not a Dart literal in a widget.
- English (`en`) is the source locale. Other locales are translated from it, never the reverse.
- Supported locales: `en`, `ko`, `ja`, `hi`, `zh`. Add a locale by adding its `app_<code>.arb`.
- Keys are semantic, not literal: `mergeRequestApproveButton`, not `approveText`.
- Do not concatenate translated fragments to build a sentence. Use a single parameterized
  message — word order differs across languages.
- Format dates, numbers, and relative times through `intl`, never with manual string building.
- **Translation files are the one exemption from the English-only rule.** The `app_<code>.arb`
  files (except `app_en.arb`) and their generated `app_localizations_<code>.dart` contain
  non-English text by design, so the CI language check skips them. `app_en.arb` and every other
  file stay English.

Details: `.agents/docs/conventions.md`

---

## 5a. Test-driven development

**Work test-first.** For any behaviour change — a new feature, a bug fix, an edge case — write a
failing test that captures the expected behaviour before writing the code that satisfies it.

The loop:

1. **Red** — write a test that fails for the right reason. Run it and confirm it fails.
2. **Green** — write the least code that makes it pass.
3. **Refactor** — clean up with the test still green.

Why this is a rule here, not a preference:

- The client talks to real GitLab instances with real credentials. A wrong redirect, a leaked
  token, a mishandled 401 — these are the failures that matter, and a test that pins the intended
  behaviour is the cheapest place to catch them. The M1 sign-in redirect bug was caught by a
  widget test asserting "a rejected token stays on sign-in", not by inspection.
- Tests written after the code tend to assert what the code does, not what it should do. Writing
  the test first forces the behaviour to be decided before the implementation can bias it.

Applies to bug fixes especially: reproduce the bug as a failing test first, then fix it, so a
regression cannot return unnoticed.

Not everything needs a test first — a pure rename, a doc change, a formatting pass do not. But any
change to how the app *behaves* does. A pull request that changes behaviour without a test that
would have failed before it is incomplete.

---

## 6. GitLab API rules

- **The official docs are the final source of truth.** When a reference implementation disagrees
  with them, follow the docs. https://docs.gitlab.com/api/
- **REST (`/api/v4`) by default.** Use GraphQL selectively, only where one screen clearly
  benefits from fetching several resources at once.
- Self-hosted support: always derive `baseUrl` from the instance URL the user entered.
  `https://git.company.com` → `https://git.company.com/api/v4`. **Never hardcode `gitlab.com`.**
- Handle pagination via response headers (`X-Next-Page`, `X-Total-Pages`) or keyset pagination.
  Never assume a page count.
- Distinguish 401 / 403 / 404 / 429 / 5xx, convert them to domain exceptions, then surface them
  in the UI. Never let a raw `DioException` leak upward.

When adding an endpoint, follow `.agents/skills/gitlab-api-endpoint/SKILL.md`.

---

## 7. Security

The following must **never** be stored in plaintext or written to logs:

- Personal Access Tokens
- OAuth access and refresh tokens

- Read and write tokens only through `packages/secure_storage`.
  Never put them in Drift or SharedPreferences.
- Mask the `Authorization` header in a Dio interceptor so it cannot reach logs or error reports.
- Never put a real token in tests or examples. Use a dummy such as `glpat-xxxxxxxxxxxx`.

---

## 8. Do not

- **Do not copy code from reference repositories.**
  Analyze their API calls, DTOs, and endpoint structure, then reimplement in Flutter.
  This repository is public, so code of unclear origin is immediately visible.
- **Never take copyleft-licensed code in any form** (GPL · LGPL · AGPL).
  LabNex is one such project. Being open source does not change this — a single line makes
  copyleft propagate, which voids Apache-2.0, gives anyone who receives the binary the right
  to redistribute it for free, and blocks App Store distribution. Study structure and UX only.
- **Check the license before adding any dependency.**
  Allowed: MIT · BSD · Apache-2.0 · ISC · Zlib
  Forbidden: GPL · LGPL · AGPL · SSPL · BUSL · Commons Clause · no stated license
  LGPL is out because Flutter links statically, so the dynamic-linking exception does not apply.
- After adding a dependency, **update `THIRD_PARTY_NOTICES.md`.**
  Permissive licenses still require the copyright notice and license text. This is not optional.
- Fonts, icons, and image assets are subject to the same license check.
  Verify **commercial use is permitted** first.
- Do not take GitHub logos, icons, illustrations, UI assets, or brand elements.
  Reference **UX patterns only** and rebuild them in the LabFox Design System.
- Do not implement features outside the 1.0 scope on your own initiative (§9).
- Do not build separate UIs per platform. Branch one feature responsively.

---

## 9. 1.0 scope

**In scope** — Account (GitLab.com / self-hosted / PAT / OAuth / multi-account),
Project (projects, favorites, repository, files, branches, commits),
Collaboration (issues, comments, MRs, discussions, diff, approval, merge),
CI/CD (pipelines, jobs, job logs, retry, cancel, manual jobs),
Productivity (to-do inbox, search, recents, favorites).

**Out of scope** — Wiki, Packages, Container Registry, Infrastructure, Kubernetes,
Security Dashboard, GitLab Analytics (Value Stream, CI/CD Analytics, Insights),
Admin Area, Runner Administration, AI features.

Every entry above is a **GitLab feature area** LabFox does not mirror. None of them
is a statement about LabFox's own instrumentation. Anonymous product telemetry —
how LabFox itself is used — **is in scope for 1.0**: it is what tells us which
parts of the core flow (§1) actually get used. What it may collect is bounded by
§7 and by the privacy policy shipped in the app (`PRIVACY.md`): no tokens, no
usernames, no titles, no full URLs, and routes sanitized so no project or item can
be identified.

Development phases (M0–M4) and the first vertical slice: `.agents/docs/roadmap.md`

---

## 10. Responsive layout

The same feature code branches on width.

| Width | Mode | Layout |
|---|---|---|
| < 600 | Mobile | Bottom navigation, single pane, push navigation |
| 600–1000 | Tablet / compact desktop | Navigation rail, two panes |
| > 1000 | Desktop | Navigation rail + multi-pane, command palette, split diff |

Decide on **screen width**, not `Platform.isX` — tablets and resizable windows must work.
How to write it: `.agents/skills/responsive-screen/SKILL.md`

---

## 11. Workflow — Issue → Branch → PR

The origin remote is **GitHub** (`theorvane/labfox`). The CLI is `gh`.

> ⚠️ **Watch the vocabulary.** LabFox is a *GitLab client* developed *on GitHub*.
> - The domain the app works with → **Merge Request**, `iid`, `/api/v4` (GitLab)
> - The development process → **Pull Request**, `gh` (GitHub)
>
> Code and UI vocabulary stays GitLab's. Do not change it.

### Branches

```
feature branch ──PR──> dev ──release PR──> main
```

| Branch | Role |
|---|---|
| `dev` | Default branch. Integration. **All contributor PRs target `dev`.** |
| `main` | Releases only. Updated through a separate reviewed `dev` → `main` release PR. |

Never commit directly to `dev` or `main`, and never push a feature branch straight to `main`.

Every change follows the sequence below.

```
Issue → Branch (from dev) → Commit → Push → PR (into dev) → Review → Merge
```

### 1) Issue

```
gh issue create --title "Implement MR diff viewer" --body "..."
```

- The title says **what is being done**, in one line. No bare "fix" or "improve".
- If it falls outside the 1.0 scope (§9), confirm before opening the issue.
- Split work so that **one issue = one PR**.

### 2) Branch

```
<type>/<issue-number>-<slug>

feat/12-mr-diff-viewer
fix/28-self-hosted-cert-error
```

type: `feat` · `fix` · `docs` · `refactor` · `test` · `chore`

```
git switch dev && git pull
git switch -c feat/12-mr-diff-viewer
```

Branch from `dev`. Do not stack work on another feature branch.

### 3) Commit

Conventional Commits plus a **DCO sign-off** (`-s`). Scope is a package or feature name.

```
git commit -s -m "feat(merge_requests): add unified diff viewer"
```

- One commit, one logical change.
- Generated files (`*.g.dart`, `*.freezed.dart`) go in the same commit as the source change.
- The body explains **why**. The diff already shows what.

### 4) Quality gate before pushing

```
dart format .
flutter analyze
flutter test
```

Do not open a PR with `analyze` warnings outstanding. If something fails, report that it failed.

### 5) PR

```
gh pr create --fill --base dev
```

- **Target `dev`, never `main`.** Releases are promoted separately.
- Put **`Closes #12`** in the description to link the issue.
- Template: `.github/PULL_REQUEST_TEMPLATE.md`
- CI must pass before merging.

### Commit / push / PR permissions

- **Committing, creating branches, pushing, and opening PRs are fine.** Do not ask every time.
- **Never push directly to `dev` or `main`.** Never force push.
- **Never open a PR against `main`.** Release promotion is a maintainer decision.
- **Maintainers merge.** An agent does not merge a PR.
- **The reviewer resolves review threads, not the author.** Resolving the reviewer's own threads on
  your pull request defeats the resolution gate. The ruleset blocks merge until all threads are
  resolved.
- Close or delete issues and PRs only when asked.

### Everything else

1. Read the feature's existing patterns before changing it. Match them rather than inventing new ones.
2. Run `build_runner` after changing a model.
3. When touching an area that has no scaffolding yet, confirm the scope instead of inventing it.

> The workspace is a native pub workspace, not melos: `flutter pub get` at the root resolves
> every package against one lockfile. `flutter test` has to run per package, because the root
> has no `test/` directory of its own.

Details: `.agents/docs/workflow.md`

---

## 12. Reference priority

```
GitHub Mobile        → UX / information architecture
      ↓
OctoLab              → GitLab feature implementation (primary code reference)
      ↓
LabCoat              → secondary implementation reference
      ↓
GH4A / OpenHub       → GitHub client structure
      ↓
LabNex / GitNex      → feature ideas (GPL — read only, never copy)
```

That said, **the official GitLab docs always win on API accuracy.**
Where a reference implementation and the docs disagree, follow the docs.

Repository URLs, licenses, and what to study in each: `.agents/docs/references.md`

## 13. `.agents/`

Agent skills and detailed documentation live under `.agents/`, not `.claude/`.

```
.agents/
├── skills/    per-task procedures (SKILL.md)
└── docs/      architecture / conventions / api-reference / monetization /
                references / roadmap / workflow
```
