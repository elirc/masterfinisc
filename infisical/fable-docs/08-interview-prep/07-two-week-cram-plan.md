# Two-Week Cram Plan

Assumes ~2.5h/day weekdays, ~4h weekend days, interview at the end of week 2. Everything spoken **aloud**. If you have less time, keep every ★ item and drop the rest.

## Week 1 — load the evidence base

**Day 1** ★ [00-fast-track](../00-fast-track.md) reading list (files 1–10) + Flow 1 trace. Aloud: 3-minute create-secret walkthrough, recorded.
**Day 2** ★ Flows 2–4 ([key-flows](../01-codebase-cartography/05-key-flows.md)). Cards: [01-deep-dive](01-js-ts-node-deep-dive.md) Q1–Q5. Drill: annotation drill 5 (syncSecrets).
**Day 3** Flows 5–6. Cards: Q6–Q10. Drill: reimplement the refresh dedupe blind (Q6/Pattern 8).
**Day 4** ★ [03/03-validation-auth](../03-architecture-and-patterns/03-validation-auth-and-permissions.md) + Flow 3 teach-back. Cards: [03-api](03-api-and-data-modeling-questions.md) Q2, Q3, Q8 (the authz trio — your differentiator).
**Day 5** Cards: [02-frontend](02-frontend-framework-questions.md) Q1–Q6. Drill: trace table 4 (error/refresh) filled from memory.
**Day 6 (weekend)** ★ Full system design run #1 ([04](04-system-design-from-this-repo.md)), 35 min, recorded, self-graded against the rubric. Then read [03/06-critique](../03-architecture-and-patterns/06-architecture-critique.md) and note what your run missed.
**Day 7** ★ **Checkpoint**: re-record the create-secret walkthrough and one 90-second answer for Q1, Q4 (idempotency), api-Q7 (migrations). Compare to Day 1 — if the walkthrough still misses auth layering or queue fan-out, repeat Day 4 before proceeding. Rest otherwise.

## Week 2 — pressure and polish

**Day 8** ★ Timed sims D1 + D2 ([05](05-debugging-and-code-review-rounds.md)) with timer, narrating. Cards: remaining 01-deep-dive (Q11–Q14).
**Day 9** ★ Timed sims R1 + R3 (review rounds). Cards: 03-api Q4, Q7, Q9, Q10.
**Day 10** ★ STAR stories 1, 3, 4, 6 drafted with your specifics ([06](06-behavioral-star-stories.md)); 2-minute versions recorded. Cards: 02-frontend Q7–Q12.
**Day 11** Sim D3 (the hard one) + D4. Remaining 03-api cards. 30-second compressed versions of your top 4 stories.
**Day 12** ★ Full system design run #2 + two variation prompts (pick multi-region and 10x-machines). Target: senior-rubric rows on invariants and staleness boundaries.
**Day 13 (day before)** Light: reread your flow-trace notes and story sheets. One teach-back of Flow 1 and Flow 4 to a human if available. No new material — consolidation beats cramming.
**Day 14 — interview** Morning: 90-second warm-up answers to Q1 (event loop) and api-Q2 (validate/authorize) aloud. In the room: golden rule — *example, tradeoff, failure mode.* When stuck, reach for the repo: "In a secrets platform I studied deeply, the way this was handled was..."

## Self-assessment checkpoints

**Day 7 gate** (must pass to stay on schedule): ☐ create-secret flow in <3 min with all five layers ☐ idempotency answer includes jobId dedupe + convergence ☐ authn/authz distinction with the two-plugin example, automatic.
**Day 14 morning**: ☐ four stories under 2 min each ☐ system-design run hits Step 4 (security) by minute 15 ☐ you can answer "what would you change in that codebase?" with two items *and their rollback plans* ([critique](../03-architecture-and-patterns/06-architecture-critique.md) items 1–2).

Cut-list if life happens: drop Days 3/5/11 content first; never drop the ★ system design runs, the Day 7 gate, or story rehearsal — spoken fluency is the scarcest resource.
