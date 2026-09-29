# Maintainer Communication

Principle: **bring evidence, not homework.** Every message should show what you tried, what you observed, and the narrowest question that unblocks you. You're allowed to be wrong; you're not allowed to be lazy.

## Asking for help without outsourcing thinking

```md
**Goal**: cross-tenant e2e for secret reads (J3).
**Tried**: created 2nd org via seed pattern from identity.spec.ts; the
project-scoped token creation 403s at POST /api/v1/... (full request below).
**Expected/actual**: expected 200 per org.spec.ts precedent; got 403 "Forbidden access".
**Hypothesis**: seeded user lacks the org-level role for project creation in org 2.
**Question**: is there an intended fixture for multi-org tests, or should I
extend seed-data? Happy to PR the fixture either way.
```

Why it works: reproducible, hypothesis-bearing, offers labor back. Contrast: "e2e tests don't work for me, help?"

## Bug reports / triage

Minimal repro (smallest input that fails — for API bugs, a `testServer.inject()` snippet or curl), exact versions/config, expected vs actual, and *impact honestly stated* (don't inflate a cosmetic issue to "critical"; don't bury a security issue in a public thread either — use [SECURITY.md](../../SECURITY.md) channels for anything exploit-shaped).

## Proposing features

Lead with the problem, not your solution: maintainers reject solutions but engage with problems. One paragraph of use case → evidence others share it → sketch of a direction → "would a PR along these lines be welcome?" *before* writing three weeks of code. The RFC template ([02](02-writing-prs-and-rfcs.md)) is the long form.

## Responding to review

- Every comment gets a response: fixed (link commit), pushed back (with reasoning), or question.
- Push back on substance, never on effort: "I kept the explicit list because the generic version loses the per-mutation exceptions (see M4 in the file) — open to a follow-up if you disagree" beats silent compliance *and* beats defensiveness.
- Batch fixes into clearly-named commits; never force-push mid-review without saying so.
- If a reviewer is wrong, they're wrong *because of context you have and they don't* — give the context, not the verdict.

## Respectful disagreement, compressed

State their position better than they did → your concern as a consequence, not an opinion ("if we match on message text, the next copy edit logs users out — that happened in Scenario 4's shape") → propose the experiment/artifact that would settle it → accept the maintainer's call and document it. Losing an argument gracefully in public is a hiring signal people remember.

Interview angle: behavioral prompts "tell me about disagreeing with a senior engineer" and "how do you ask for help" are this page — pre-build both stories in [08/06](../08-interview-prep/06-behavioral-star-stories.md).
