# Writing PRs and RFCs

## PR description anatomy (use every time)

```md
## What
One paragraph: the change, in product terms first, mechanism second.

## Why
Link the issue/ticket. If none exists, the evidence that motivated this.

## How tested
Exact commands + what you observed. "make reviewable-api clean; new e2e
cross-tenant spec fails on main, passes here" beats "tested locally."

## Risks
What could this break, and why you believe it doesn't. Name the blast radius.

## Rollback
Revert-safe? Migration involved (then: down() story)? Feature flag?

## Follow-ups
Deliberately out of scope, so reviewers don't expand your PR for you.
```

Small PRs win: one intent per PR; mechanical refactors separated from behavior changes (K3 discipline); generated files (`generate:schema` output, `routeTree.gen.ts`) in their own commit so reviewers can skip them.

Commit messages: imperative summary ≤72 chars, body explains *why*. `fix(secrets): reject 11+ metadata filters with 400` — scoped, greppable, matches the repo's conventional-commit style (check `git log` for the live convention; this working copy has no commit history to inspect — *verify upstream*).

## When to RFC instead of PR

RFC first when: new dependency (FIPS + supply-chain policy make this expensive here — [CLAUDE.md](../../CLAUDE.md)), new tooling (M6), contract changes (API/webhook shapes), anything with a migration that's hard to reverse, cross-cutting patterns (outbox). PR directly when: the pattern already exists and you're adding an instance.

## RFC template (tailored to this repo)

```md
# RFC: <title>
Status: draft | discussed | accepted | rejected
## Problem
What hurts, with evidence (incident, measurement, anchor to code).
## Constraints
The ones this repo actually has: FIPS deps, self-hosted long tail,
EE/community split, 4 live API versions, min-release-age policy.
## Design A (recommended) / Design B
Shape, touched areas, migration path, failure modes — for each.
## Security & permissions impact
New surface? CASL actions? Audit events? (Mandatory section in a secrets product.)
## Rollout
Flag? Phases? Rollback at each phase?
## Not doing
Adjacent work explicitly out of scope.
## Open questions
Numbered, so discussion threads stay addressable.
```

## Drill

Write the full PR description for ticket J3 (cross-tenant e2e) *before* implementing it — then implement and see which sections you got wrong. The delta is your planning-accuracy gap; it shrinks with reps. Interview angle: "walk me through a recent PR" is a standard screen question — the anatomy above *is* the answer's outline. ([08/06](../08-interview-prep/06-behavioral-star-stories.md) turns completed tickets into stories.)
