# 08 — Interview Prep

Target: **mid-level fullstack JS interviews**, using this repo as your evidence base. Most candidates answer with definitions; you'll answer with a real system's choices, tradeoffs, and failure modes.

## How mid-level fullstack loops are typically structured

| Round | Format | Prep file |
| --- | --- | --- |
| Screen | 30–45 min, resume walk + 2–3 technical probes | [06-behavioral](06-behavioral-star-stories.md) + any deep-dive file |
| Technical deep-dive | JS/TS/Node/React fundamentals, spoken | [01](01-js-ts-node-deep-dive.md), [02](02-frontend-framework-questions.md) |
| Practical coding | build/debug something small, live | [05-debugging-and-code-review-rounds](05-debugging-and-code-review-rounds.md) |
| System design | whiteboard a product | [04-system-design-from-this-repo](04-system-design-from-this-repo.md) |
| Code review round (increasingly common) | review a flawed PR | [05](05-debugging-and-code-review-rounds.md) |
| Behavioral | STAR stories | [06](06-behavioral-star-stories.md) |

Two weeks out? Go straight to [07-two-week-cram-plan.md](07-two-week-cram-plan.md).

## The golden rule

**Concrete example → tradeoff → failure mode.** Never stop at a definition. "What's idempotency?" — junior: defines it. You: define it in one sentence, then: "Infisical's secret-sync queue is at-least-once with 5 retries, so handlers must converge — they push current state, not deltas; the dedupe jobId handles bursts, and the failure mode is a dedupe key that's too coarse dropping distinct work." That answer contains a system; the definition contains a flashcard.

Repo-anchored cards (≥60% here) exist so you *practice retrieving the example with the concept*. Before each card, open its anchor and re-read the code — the goal is that in the room, the code plays back in your head.

## Question card count across this module

01: 14 cards · 02: 12 · 03: 12 · 04: 1 full walkthrough + 5 variations · 05: 7 timed simulations · 06: 8 STAR worksheets. Work them aloud; written fluency does not transfer to spoken fluency without reps.
