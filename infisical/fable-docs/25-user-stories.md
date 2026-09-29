# 25 User Stories — Junior SWE Upskilling Backlog

A sprint-able backlog for the junior engineer working through this curriculum. Each story has acceptance criteria and points to the curriculum material that supports it. Stories 1–8 are onboarding (week 1–2), 9–17 are skill-building (weeks 3–6), 18–25 are stretch/interview-readiness (weeks 6+). Treat them like real tickets: move them across a board, demo the result to someone, and write a two-line retro per story.

## Epic 1 — Orient (run it, read it, trace it)

**US-01** — As a junior SWE, I want to run the Infisical dev stack locally so that I can observe the system I'm studying.
*Acceptance*: `make up-dev` (or the split backend/frontend path) reaches a working login page; `npm run type:check` passes in backend. *Support*: [00-fast-track](00-fast-track.md).

**US-02** — As a junior SWE, I want to read the first-10-files list in order so that I hold the repo's core shape in my head.
*Acceptance*: for each file, one written sentence answering its guiding question; no file skipped. *Support*: [00-fast-track](00-fast-track.md), [01/02-file-reading-order](01-codebase-cartography/02-file-reading-order.md).

**US-03** — As a junior SWE, I want to trace the create-secret flow end to end so that I can explain a full-stack write path without notes.
*Acceptance*: 3-minute spoken walkthrough recorded, covering all five layers + queue fan-out; checked against the Flow 1 table. *Support*: [01/05-key-flows](01-codebase-cartography/05-key-flows.md).

**US-04** — As a junior SWE, I want to fill in the domain glossary from memory so that I use the product's nouns precisely.
*Acceptance*: 12+ terms defined without the doc, then diffed against it; the five near-synonym pairs disambiguated correctly. *Support*: [01/03-domain-glossary](01-codebase-cartography/03-domain-glossary.md).

**US-05** — As a junior SWE, I want to make one safe change, verify it, and revert it so that editing a big codebase stops feeling dangerous.
*Acceptance*: description-string edit + `type:check` + revert completed; one sentence on what made it safe. *Support*: [00-fast-track](00-fast-track.md) Sunday section.

**US-06** — As a junior SWE, I want to run the backend unit tests and read two of them so that I know the cheap test layer's shape.
*Acceptance*: `npm run test:unit` outcome recorded; written note on what [validate-url.test.ts](../backend/src/lib/validator/validate-url.test.ts) covers and *why that logic earned unit tests*. *Support*: [05/01-testing-strategy](05-quality-engineering/01-testing-strategy.md).

**US-07** — As a junior SWE, I want to map the auth plugin chain so that I can say where authentication ends and authorization begins.
*Acceptance*: hand-drawn diagram of inject-identity → inject-permission → verify-auth → CASL with one sentence per stage; passes the Flow 3 drill. *Support*: [03/03-validation-auth](03-architecture-and-patterns/03-validation-auth-and-permissions.md).

**US-08** — As a junior SWE, I want to complete annotation drills 1–4 so that I read code as contracts, not lines.
*Acceptance*: all six annotation categories written per drill; self-graded Solid or better, honestly. *Support*: [04/01-annotation-drills](04-code-reading-gym/01-annotation-drills.md).

## Epic 2 — Build skill (patterns, tests, debugging, first tickets)

**US-09** — As a junior SWE, I want to identify five catalog patterns in a module I've never read so that recognition becomes automatic.
*Acceptance*: the 20-minute recognition drill completed with anchors noted. *Support*: [03/05-pattern-catalog](03-architecture-and-patterns/05-pattern-catalog.md).

**US-10** — As a junior SWE, I want to complete trace tables 2 and 4 solo so that I can follow values across layers under my own power.
*Acceptance*: tables filled before reading completed versions; every risk cell is a scenario. *Support*: [04/02-trace-tables](04-code-reading-gym/02-trace-tables.md).

**US-11** — As a junior SWE, I want to write my first e2e test using the repo helpers so that I can contribute tests confidently.
*Acceptance*: Recipe 1 (happy path) implemented and passing locally, with cleanup and unique fixtures. *Support*: [05/02-writing-tests-here](05-quality-engineering/02-writing-tests-here.md).

**US-12** — As a junior SWE, I want to write a validation-failure test (400 not 500) so that I internalize boundary contracts.
*Acceptance*: Recipe 2 implemented; the assertion checks the error body names the field. *Support*: same file.

**US-13** — As a junior SWE, I want to complete ticket J1 (metadataFilter parser tests) so that I ship my first real coverage improvement.
*Acceptance*: J1 acceptance criteria met; `make reviewable-api` clean; PR description follows the anatomy. *Support*: [06/01](06-contribution-practice/01-good-first-tickets.md), [07/02](07-career-and-collaboration/02-writing-prs-and-rfcs.md).

**US-14** — As a junior SWE, I want to complete ticket J3 (cross-tenant e2e) so that I've written an adversarial security test.
*Acceptance*: J3 criteria met including write-path attempts; one paragraph on what IDOR means, in my own words. *Support*: [06/01](06-contribution-practice/01-good-first-tickets.md), [05/05-security-checklist](05-quality-engineering/05-security-checklist.md).

**US-15** — As a junior SWE, I want to work debugging scenarios 1 and 2 cold so that I practice the reproduce→narrow loop.
*Acceptance*: narrated aloud with hypotheses stated before probes; self-graded Solid+. *Support*: [05/03-systematic-debugging](05-quality-engineering/03-systematic-debugging.md).

**US-16** — As a junior SWE, I want to review katas 1–4 and compare against expected findings so that I learn severity triage.
*Acceptance*: all Blockings caught on at most the second attempt; one comment per kata rewritten in kind-specific form. *Support*: [04/04-review-katas](04-code-reading-gym/04-review-katas.md).

**US-17** — As a junior SWE, I want to complete one more J-ticket of my choice (J5–J15) so that I build breadth beyond secrets.
*Acceptance*: ticket's own criteria + Strong self-grade bar from the tickets file. *Support*: [06/01](06-contribution-practice/01-good-first-tickets.md).

## Epic 3 — Stretch toward mid-level and interviews

**US-18** — As a junior SWE, I want to write the design note for an M-ticket before implementing it so that I practice design-first work.
*Acceptance*: half-page note (approach, alternative, risk, rollback) written; reviewed against outcome after implementation with a delta sentence. *Support*: [06/02](06-contribution-practice/02-mid-level-feature-tickets.md).

**US-19** — As a junior SWE, I want to implement M2 (count endpoint) or M4 (pagination) end to end so that I've shipped a cross-layer feature.
*Acceptance*: route+service+DAL+UI+tests; authorization respected in aggregates; negative-path test present. *Support*: [06/02](06-contribution-practice/02-mid-level-feature-tickets.md), [03/01-boundaries](03-architecture-and-patterns/01-boundaries-and-layers.md).

**US-20** — As a junior SWE, I want to complete kata K3 (extract + characterization tests) so that I can refactor without changing behavior.
*Acceptance*: diff reviewable in <5 min; tests written before the move; one surprising current behavior documented. *Support*: [06/04](06-contribution-practice/04-refactor-and-design-katas.md).

**US-21** — As a junior SWE, I want to answer all 14 JS/TS/Node cards aloud so that my fundamentals are spoken, not just read.
*Acceptance*: each card ≤90s, recorded; the three weakest re-done after two days. *Support*: [08/01](08-interview-prep/01-js-ts-node-deep-dive.md).

**US-22** — As a junior SWE, I want to answer the frontend and API/data card decks so that framework and design questions don't surprise me.
*Acceptance*: 24 cards done aloud; for the six anchored ones I know least, the anchor file re-read first. *Support*: [08/02](08-interview-prep/02-frontend-framework-questions.md), [08/03](08-interview-prep/03-api-and-data-modeling-questions.md).

**US-23** — As a junior SWE, I want to run the full system-design walkthrough twice so that I can design "this product" on a whiteboard.
*Acceptance*: two recorded 35-min runs, second graded mid-or-better on the rubric; one variation prompt attempted. *Support*: [08/04](08-interview-prep/04-system-design-from-this-repo.md).

**US-24** — As a junior SWE, I want to run four timed simulations (D1, D2, R1, R3) so that I perform under interview pressure.
*Acceptance*: within time, narrated, rubric rows Process and Evidence at Strong for at least two sims. *Support*: [08/05](08-interview-prep/05-debugging-and-code-review-rounds.md).

**US-25** — As a junior SWE, I want four rehearsed STAR stories built from my completed stories/tickets so that behavioral rounds are evidence-backed.
*Acceptance*: stories 1, 3, 4, 6 filled with my specifics; each under 2 minutes recorded; 30-second versions exist; prompt→story map memorized. *Support*: [08/06](08-interview-prep/06-behavioral-star-stories.md).

---

## Definition of Done (applies to every story)

- The artifact exists (recording, note, test, PR, diagram) — "I read it" is not done.
- Self-grade recorded against the relevant rubric, plus a two-line retro (what was hard, what changed).
- Anything shippable passed `make reviewable-api` / `reviewable-ui`.

Suggested cadence: 2–3 stories/week alongside normal work; Epics 1→2→3 in order, but US-21/22 can interleave anytime. Finish line: the "call yourself mid-level here" gate in [09-reference/learning-rubrics.md](09-reference/learning-rubrics.md).
