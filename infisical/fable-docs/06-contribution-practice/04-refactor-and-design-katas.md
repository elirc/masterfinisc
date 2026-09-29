# Refactor and Design Katas (8)

Judgment exercises — most produce a *document or branch*, not a merged PR. Each has self-grading criteria. Timebox hard; over-polishing katas is procrastination with extra steps.

## K1: Boundary-leak hunt (90 min)
Task: find three places where a layer does another layer's job (route with logic, service with raw table access outside DALs, component with transport concerns). For each: the leak, the cost, the two-line fix direction.
Self-grade — Solid: three real findings with anchors. Strong: for one finding, you also argue why it might be *acceptable* (pragmatism is part of judgment).

## K2: Design the outbox RFC (half day)
Task: write the one-page RFC for project P1 using the template in [07/02-writing-prs-and-rfcs](../07-career-and-collaboration/02-writing-prs-and-rfcs.md): problem, evidence, two designs (polling relay vs LISTEN/NOTIFY), recommendation, migration, risks, "not doing" list.
Self-grade — Solid: both designs honestly costed. Strong: includes the instrumentation-first alternative and defines the metric that would justify building nothing.

## K3: Split a module (half day)
Task: on a branch, extract the metadataFilter parser ([secret-router.ts:64-96](../../backend/src/server/routes/v4/secret-router.ts)) into a pure function with tests; zero behavior change; diff must be reviewable in <5 min.
Self-grade — Solid: tests pass, type-check clean. Strong: you wrote characterization tests *before* moving code, and one test exposed a surprising current behavior (write it down).

## K4: Remove duplication — or don't (2 h)
Task: the per-domain `queries.tsx`/`mutations.tsx` files repeat structure 100+ times. Design the generic helper that would DRY them — then write the verdict: adopt or reject. (Hint: the repetition is *regular but not identical*; nine bespoke invalidation lists resist abstraction. Wrong abstraction > duplication is a real cost.)
Self-grade — Solid: honest cost/benefit. Strong: your verdict includes the *trigger condition* that would flip it ("if we add optimistic updates everywhere, revisit").

## K5: Improve type safety at one seam (2 h)
Task: find one `as` cast or wide type outside [lib/knex](../../backend/src/lib/knex/index.ts)'s sanctioned zone; eliminate it or document why it's irreducible.
Self-grade — Solid: compiler-verified improvement. Strong: you can state the general rule for when a cast is a bug vs a boundary.

## K6: Design a gnarly migration (half day, paper)
Task: plan splitting `secrets.key` uniqueness from per-folder to per-folder-per-type with zero downtime (invented requirement). Full expand–contract: each deploy step, each migration, old-code compatibility at every instant, rollback at every instant.
Self-grade — Solid: no step breaks old code. Strong: you identified the step where rollback flips from "roll back" to "roll forward" and said so explicitly.

## K7: N+1 hunt with proof (half day, needs dev stack)
Task: enable Knex query logging, load two heavy pages, capture query counts. Find one N+1 or prove the hot paths are clean (both outcomes pass).
Self-grade — Solid: evidence captured, correctly interpreted. Strong: if found — the join/`$in` fix sketched at the right DAL layer; if clean — you identified *why* (the `sqlNestRelationships` join discipline).

## K8: Review the flawed PR under time pressure (45 min)
Task: take Kata 8 from [04/review-katas](../04-code-reading-gym/04-review-katas.md) (admin bypass) and write the *actual full review* — every comment as you'd post it, severity-tagged, with an overall summary that is firm on the blocking issue and kind to the author's real need.
Self-grade — Solid: all blockings, professional tone. Strong: your review proposes the break-glass alternative concretely enough that the author's next diff is obvious.

Interview note: K2, K6, and K8 simulate the written/verbal artifacts senior loops ask for directly ("design doc exercise", "review this PR live"). Do them aloud/typed under time — the constraint is the training.
