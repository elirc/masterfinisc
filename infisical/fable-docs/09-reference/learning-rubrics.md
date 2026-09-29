# Learning Rubrics

Observable behaviors only — "understands X" is not observable; "can trace X aloud with anchors" is. Self-assess monthly; be harsh. The **Interview-ready** column is the bar for claiming the skill in a loop.

## Codebase navigation

| Level | Observable behavior | Interview-ready when |
| --- | --- | --- |
| Junior | Finds any named feature's route/service/DAL within 10 min using grep + the wiring file | you can narrate *how* you locate things (method, not luck) |
| Mid | Predicts where a new feature's code belongs and which files a PR will touch, before looking | you can do it for a codebase you saw 30 min ago |
| Senior | Reads an unfamiliar module and states its contracts, invariants, and two risks in 20 min | you can do it live, thinking aloud (Sim rounds) |

## Fullstack data flow

| Level | Observable | Interview-ready |
| --- | --- | --- |
| Junior | Traces create-secret UI→DB with the doc open | 3-min spoken version, doc closed |
| Mid | Traces it doc-closed including both auth plugins, CASL, and queue fan-out; answers "what if step N fails" for any N | follow-up-proof: replica lag, retry, invalidation questions don't stall you |
| Senior | Redesigns any step with tradeoffs (outbox, optimistic UI, cursor pagination) and names what evidence would justify each | you volunteer the "not worth building unless X" caveat |

## Testing

| Level | Observable | Interview-ready |
| --- | --- | --- |
| Junior | Writes a passing happy-path e2e with the repo helpers | can explain what the custom e2e environment boots and why |
| Mid | Writes negative-path, cross-tenant, and async (bounded-poll) tests; picks the cheapest layer per bug class | the five-changes classification drill ([05/01](../05-quality-engineering/01-testing-strategy.md)) is instant |
| Senior | Designs test strategy for a feature (what NOT to test and why); converts flakes into architecture findings | you have one real flake-to-root-cause story |

## Security

| Level | Observable | Interview-ready |
| --- | --- | --- |
| Junior | Applies the pre-merge checklist ([05/05](../05-quality-engineering/05-security-checklist.md)) mechanically | can define IDOR/SSRF/XSS with this repo's defense for each |
| Mid | Spots the missing authz in Kata 1 unprompted; writes adversarial tests | authn-vs-authz + ABAC answers are automatic with anchors |
| Senior | Reasons about residual risk (rebinding after validation, 403/404 leakage, audit gaps) and prioritizes by blast radius | you can argue *against* a security measure on cost grounds credibly |

## Debugging

| Level | Observable | Interview-ready |
| --- | --- | --- |
| Junior | Follows reproduce→narrow→fix on a known-class bug | narrates instead of silently poking |
| Mid | Partitions hypothesis space before probing; each probe kills a branch | Sims D1/D2 pass in time |
| Senior | Names the bug *class* and lands the prevention (test/type/lint/process) | your postmortems are blameless and systemic (Sim D4) |

## Communication & review

| Level | Observable | Interview-ready |
| --- | --- | --- |
| Junior | PR descriptions follow the anatomy; review comments have severity tags | can walk a recent PR through what/why/tested/risks |
| Mid | Catches all Blockings in the katas; disagreement follows the compressed protocol ([07/03](../07-career-and-collaboration/03-maintainer-communication.md)) | R-sims pass; pushback follow-ups don't rattle you |
| Senior | Approves imperfect PRs deliberately; writes RFCs where PRs would waste cycles; escalates with options | you have a real "held the bar under pressure" story with a kind ending |

## Overall gate to "call yourself mid-level here"

☐ Two junior tickets + one M-ticket completed to the Strong bar ☐ Day-7 cram-plan checkpoint passes cold ☐ One full system-design run graded mid-or-better by someone else ☐ All review katas: no missed Blockings on second attempt.
