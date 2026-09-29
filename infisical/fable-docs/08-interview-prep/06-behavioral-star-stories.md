# Behavioral STAR Stories — 8 Worksheets

Each worksheet is pre-structured from work in this curriculum. Fill Situation/Task/Action/Result with *your* specifics after completing the source ticket; the senior-signal details and resume bullets are drafted for you to adapt. Rehearsal check applies to all: **under 2 minutes, concrete numbers where possible, ends with impact.** If you haven't done the source ticket, the honest framing is "studying a production codebase, I..." — deep code study is a legitimate story; claiming merged PRs you didn't ship is not.

## Story 1: Learning a large unfamiliar codebase fast
Prompts this answers: "How do you ramp up?" / "Tell me about learning something complex."
Source: this curriculum itself (Phase: cartography + key flows).
S/T: needed working knowledge of a 270-table, 100-service secrets platform. A: systematic cartography — manifests → entry points → DI wiring file → traced six flows end-to-end with file:line notes; validated understanding by predicting behavior before reading (pause-and-predict). R: could locate any feature's stack in minutes; produced a written system map.
Evidence to cite: your flow-trace notes; the 11-step create-secret trace.
Senior-signal details: *method* over grind — "I read the wiring file because DI graphs are the map"; verification habit.
Resume bullet: Reverse-engineered a 100+-service open-source secrets platform (Fastify/React/Postgres), documenting six end-to-end flows and its authorization architecture.
Rehearsal check: ☐ <2min ☐ names one specific file pattern ☐ ends with the capability gained.

## Story 2: Finding and fixing a coverage gap (source: J1/J3/J4)
Prompts: "A time you improved quality" / "Initiative without being asked."
S/T: public API boundary had a hand-rolled parser (or: tenant isolation had no adversarial test). A: pinned current behavior with characterization tests first, then hardened; wrote the negative-path cases nobody had. R: N new tests; one surprising behavior documented (there's always one — say what it was).
Senior-signal: tests *before* refactor; adversarial mindset (cross-tenant cases).
Resume bullet: Added adversarial multi-tenant and parser edge-case coverage to a security-critical API surface.

## Story 3: Debugging something intermittent (source: Sim D3 / Scenario 3)
Prompts: "Hardest bug" / "Debugging under ambiguity."
S/T: intermittent missing background syncs. A: partitioned into never-enqueued/deduped/failed before touching code; probed each with logs/Redis state; found the dedupe-semantics interaction. R: root cause + regression test + a one-paragraph runbook.
Senior-signal: hypothesis discipline; understanding at-least-once semantics; wrote the runbook so the *next* person doesn't redo the hunt.
Resume bullet: Root-caused intermittent job-loss in a BullMQ pipeline to dedupe-key semantics; added regression coverage and runbook.

## Story 4: Pushing back on a risky change (source: Kata 7/8, Sim R3)
Prompts: "Disagreed with a teammate/senior" / "Held a quality bar under pressure."
S/T: reviewed a change that broke an implicit contract (or bypassed authz) with schedule pressure to approve. A: demonstrated the concrete failure (grep of consumers / missing audit trail), proposed the fast-but-correct alternative, escalated with options not ultimatums. R: shipped the safe version; contract made explicit so the class can't recur.
Senior-signal: firm on the invariant, flexible on the path; converted conflict into a systemic fix.
Resume bullet: Prevented a breaking auth-contract change by demonstrating downstream impact and landing a compatible alternative.

## Story 5: A mistake and what changed (source: any ticket where your design note was wrong — M-series retro)
Prompts: "Tell me about a mistake."
S/T: your pre-implementation design note chose approach A; implementation revealed it broke on X. A: caught it via [tests/measurement], switched to B, and — the key beat — updated your *process* (now you check X in every design note). R: the process change, named.
Senior-signal: blameless self-postmortem; the lesson is procedural, not "try harder."
Resume bullet: (usually not a bullet — this one's for the room.)

## Story 6: Cross-layer feature with a contract decision (source: M1/M2/M4)
Prompts: "Walk me through a recent project" / "A technical tradeoff you made."
S/T: e.g. pagination for an unbounded endpoint. A: audited access patterns, chose offset vs cursor *for a stated reason*, additive rollout, negative-path tests, documented the follow-up you deliberately didn't do. R: shipped; old clients unaffected.
Senior-signal: the tradeoff sentence ("cursor because deep pages + concurrent writes; accepted no jump-to-page") and the scope discipline.
Resume bullet: Designed and shipped backward-compatible pagination across API/DB/UI layers with adversarial tests.

## Story 7: Making a system observable (source: M5/M9 or the observability drill)
Prompts: "How do you operate what you ship?" / "A time you improved reliability."
S/T: a background flow failed silently in a crash window. A: instrumented first (counter on enqueue failures), let data decide whether the heavier fix (outbox) was warranted; wrote the "how would we know it broke" trio into the PR template. R: measured frequency → informed build/don't-build decision.
Senior-signal: instrumentation *before* architecture; explicit don't-build option.
Resume bullet: Instrumented queue-loss risk and drove an evidence-based build/no-build decision on a transactional-outbox proposal.

## Story 8: Teaching / leveling others (source: J5/J9/J14 docs tickets, or teaching this curriculum's flows to someone)
Prompts: "Leadership without authority" / "Improving team effectiveness."
S/T: recurring onboarding confusion (auth modes, seed data, ormify semantics). A: wrote the decision-table/contract docs anchored to code lines; walked a peer through one flow teach-back style. R: next person's ramp measured in days not weeks (or: peer shipped their first ticket against those docs).
Senior-signal: documentation as leverage; teach-backs as verification that the docs work.
Resume bullet: Authored contributor-facing architecture documentation (auth matrix, data-layer contracts) adopted for onboarding.

---

## Prompt → story map

| Common prompt | Primary | Backup |
| --- | --- | --- |
| Hardest bug | 3 | 4 |
| Conflict/disagreement | 4 | 5 |
| Mistake/failure | 5 | 3 |
| Recent project deep-dive | 6 | 2 |
| Ambiguity | 1 | 7 |
| Leadership/mentoring | 8 | 4 |
| Quality/initiative | 2 | 7 |
| Tradeoff | 6 | 7 |

Rehearse the top four until the 2-minute version is automatic, then practice the 30-second compressed versions — screens often want the short form.
