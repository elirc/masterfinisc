# Debugging & Code Review Rounds — 7 Timed Simulations

Live rounds test *process out loud*. Rules for every sim: narrate before you act ("I'll bisect client vs server first because..."), state hypotheses as falsifiable, and when given new evidence, say explicitly whether it confirms or kills your hypothesis. Silence reads as flailing.

## Debugging simulations (source: [05/03-systematic-debugging](../05-quality-engineering/03-systematic-debugging.md))

### Sim D1 — Stale list after create (20 min, from Scenario 1)
Interviewer setup: "Users report a created item not appearing. Here's the mutation file and the query file — find the bug class." ([mutations.tsx](../../frontend/src/hooks/api/secrets/mutations.tsx), [queries.tsx](../../frontend/src/hooks/api/secrets/queries.tsx))
Expected path: network-tab bisect → invalidation-vs-key param diff → the class-level fix.
Interviewer follow-ups: "No devtools available — now what?" (add a log to onSuccess; compare keys statically). "How do you prevent the whole class?" (shared factories, review checklist).
Grading — Pass: found a plausible key mismatch in time. Strong: articulated the class + prevention + why staleTime made it intermittent.

### Sim D2 — Machine token 401 (15 min, from Scenario 2)
Setup: "This curl gets 401; the same route works in the browser." Files: [verify-auth.ts](../../backend/src/server/plugins/auth/verify-auth.ts), [inject-identity.ts](../../backend/src/server/plugins/auth/inject-identity.ts), one router.
Expected path: map error message → emitting gate; check route's mode allowlist first (cheapest hypothesis).
Follow-ups: "Allowlist includes the mode — next?" (decode token's authTokenType; org context; CASL). "Design fix so this class self-diagnoses?" (error codes per gate).
Grading — Strong: ordered hypotheses by check-cost and said so.

### Sim D3 — The disappearing sync (25 min, from Scenario 3)
Setup: "Intermittent missing syncs. Here's the queue file." ([secret-queue.ts:594-660](../../backend/src/services/secret/secret-queue.ts))
Expected path: three-way partition (never enqueued / deduped away / failed out) *stated before* reading code; probe per branch.
Follow-ups: "Logs show enqueue but no processing — narrow it." "jobId dedupe: bug or feature here?"
Grading — Strong: reasoned about `removeOnComplete` + jobId interplay correctly under pressure.

### Sim D4 — Mass logout postmortem (15 min, from Scenario 4)
Setup: "After a copy-change deploy, everyone got logged out. Root-cause it and write the 3-bullet postmortem." ([request.ts:54-57](../../frontend/src/config/request.ts))
Expected: string-contract root cause; contributing factor (no contract test); prevention (error codes).
Grading — Strong: postmortem is blameless and names the *system* fix, not "be more careful."

## Review simulations (source: [04/04-review-katas](../04-code-reading-gym/04-review-katas.md))

### Sim R1 — The IDOR route (20 min, Kata 1)
You review the fake diff live, thinking aloud. Must-catch: missing project permission (blocking), raw-row response, layer violation. Follow-up: "Author says 'mobile needs it fast, ship now' — respond." (Grade: firm on the security blocker, offers the fast *correct* path.)

### Sim R2 — The retry inflation (15 min, Kata 3)
Must-catch: deleted failure-visibility channel; retrying deterministic failures. Follow-up: "What data would settle whether flakiness is transient?" (failure-reason distribution).

### Sim R3 — The admin bypass (20 min, Kata 8)
Must-catch: unaudited privilege bypass in a secrets product; hardcoded role string. Follow-up: "PM says compliance can wait a sprint." Grade: escalation with alternatives (break-glass design), not capitulation or moralizing.

---

## Universal rubric

| Signal | Weak | Strong |
| --- | --- | --- |
| Process | jumps to code, tweaks randomly | partitions the space, cheapest probe first, narrates |
| Evidence | "maybe it's X" forever | each probe kills or confirms a named hypothesis |
| Depth | stops at the fix | names the class, the regression test, the prevention |
| Communication | silent, then a conclusion | thinking audible; disagreement professional; severity triaged |

Do each sim with a timer and, ideally, a friend playing interviewer with the follow-up scripts. Alone, record audio and listen back — the gaps are always audible.
