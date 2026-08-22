# Monetization

How LabFox is distributed, what is free, and what a subscription unlocks.

`AGENTS.md` §1 states the open-core model and the trademark position. This document
is the detail behind it. Where the two disagree, `AGENTS.md` wins.

---

## 1. Distribution

The app is a **free download on every platform**. A single auto-renewing
subscription is sold as an in-app purchase.

| OS | Channel | App | Subscription | Entitlement source |
|---|---|---|---|---|
| Windows | Direct download (GitHub Releases) | Free, full features | — | none |
| macOS | Mac App Store | Free download | Optional | StoreKit |
| iOS | App Store | Free download | Required for paid features | StoreKit |
| Android | Play Store | Free download | Required for paid features | Play Billing |

There is **no LabFox account and no LabFox server**. Entitlement comes from the
store the app was installed from, and nowhere else.

### Why desktop stays free

`AGENTS.md` §1 frames the contributor loop as a business requirement, not a
preference: desktop users and outside contributors send pull requests, the
codebase is shared, and the mobile app improves as a result. Gating desktop
features would tax exactly the people that loop depends on.

Windows shipping outside the stores and macOS shipping inside one is a
distribution choice, not a pricing one. Both are fully featured and free.

---

## 2. The free / paid boundary

One line: **free is for checking on things, paid is for finishing them.**

| Area | Free | Subscription |
|---|---|---|
| Accounts | One account (GitLab.com or one self-hosted instance) | Multiple accounts and instances |
| Notifications | To-do inbox, manual refresh | Push notifications |
| Reading | Everything — projects, repository, files, branches, commits, issues, merge requests, diffs, discussions, pipelines, jobs, job logs | — |
| Writing | Comments on issues and merge requests | Approve, merge, retry, cancel, manual jobs |
| Productivity | Search, recents, favorites (capped) | Unlimited favorites, saved searches, custom inbox filters |
| Offline | — | Local cache and offline reading (planned, post-1.0) |

The core flow in `AGENTS.md` §1 ends at *approve / merge / retry*. Free carries a
user all the way to that last step, so the value is felt before the paywall is.
Gating reading instead would leave a free tier nobody keeps installed, and gating
nothing leaves no reason to subscribe.

Comments stay free deliberately. They cost nothing to serve, and an app that
cannot reply reads as a viewer rather than a client, which kills the return visit
that the whole model depends on.

---

## 3. Entitlement

### Apple covers iOS, iPadOS, and macOS together

The iOS and macOS targets already share the bundle identifier
`com.sloki9637.labfox`, which is what Universal Purchase requires. One Apple
subscription therefore covers iPhone, iPad, and Mac with no work on our side.

Keep those identifiers equal. Splitting them silently breaks Universal Purchase
and turns one subscription into two.

### Apple and Google do not share entitlement

There is no server to link a Play subscription to an Apple one, so a subscriber
on one vendor has no entitlement on the other. The blast radius is small and
should stay documented rather than engineered around:

- An Apple subscriber is covered on iPhone, iPad, and Mac.
- A Play subscriber is covered on Android, and Windows is free anyway, so their
  desktop need is already met.
- Only **Play subscriber + Mac** is left uncovered.

Say so plainly in the store listing. Building an account system to close this one
case would mean running a backend, storing user identity, and expanding the
privacy surface that `PRIVACY.md` currently keeps narrow.

### Restore

- Apple **requires** a visible restore control (App Store Review Guideline 3.1.1).
  It belongs in Settings, next to the subscription state.
- Play Billing restores through `queryPurchases` at launch, but ship the same
  visible control so the two platforms behave alike.

### Fail open

Cache the entitlement locally and **treat an unreachable store as entitled**.
A receipt check that times out on a train must never be what stops a paying user
from merging. Give the cache a long life — two weeks or more — and refresh it
opportunistically rather than on the critical path.

Failing closed here is worse than any revenue it protects: it breaks the core
flow for the people who paid for it.

---

## 4. Implementation notes

- Put the gate in **`core/entitlement/`** and check it in **controllers**, never in
  widgets. Scattering checks through the UI multiplies the places to get it wrong
  and makes the boundary untestable.
- Gate behaviour, not navigation. A paid screen should be reachable and explain
  itself; a dead menu item teaches the user nothing.
- The paid actions map to existing controllers — approve and merge in
  `features/merge_requests`, retry and cancel in `features/jobs` and
  `features/pipelines`, account handling in `core/auth`. Nothing needs a new
  feature slice.
- Analytics may record that a gate was reached, subject to `PRIVACY.md`: no
  usernames, no titles, no full URLs.

### The gate is honor-system, and that is fine

LabFox is Apache-2.0. Anyone can clone the repository, remove the check, and
build. No client-side gate changes that.

What protects the model is the trademark (`TRADEMARK.md`) and store
distribution: nobody else may ship this app under this name, and the people
buying from a store are not the people compiling from source. This was already
true when mobile was a paid download; a subscription raises the incentive to
bypass but not the means.

Do not spend engineering effort on obfuscation or tamper checks. It would not
work, and it would make the codebase worse for the contributors the model needs.

---

## 5. Store obligations

- Both stores require their own billing for digital subscriptions, at 15–30%.
- Apple requires the app to be useful without a subscription. The free tier above
  satisfies this; keep it that way when the boundary moves.
- Windows ships unsigned by default, which triggers a SmartScreen warning and
  costs real installs. Budget for a code-signing certificate, an update check
  against GitHub Releases, and a `winget` manifest.
