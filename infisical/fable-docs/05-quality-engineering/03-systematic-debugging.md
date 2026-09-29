# Systematic Debugging

The loop, always: **reproduce → narrow (binary-search the layers) → hypothesize → test the hypothesis cheaply → fix the root cause → add regression coverage.** Skipping "reproduce" is the #1 junior time sink; skipping "regression coverage" is the #1 way bugs return.

Tools of this repo: pino logs (pretty in dev — `npm run dev`), Node debugger/`--inspect` through tsx, Knex query logging (enable via knexfile in dev), browser devtools + React Query Devtools (check availability), BullMQ state via Redis inspection, and the e2e harness as a *reproduction* tool (`testServer.inject()` reproduces API bugs faster than clicking).

---

## Scenario 1: "I created a secret but the list doesn't show it"

Reproduction: create via UI, list view unchanged until manual refresh.
First question: is the bug client (cache) or server (data)?
Narrowing path: 1. Network tab — did the list *request* even fire after the create? If no → cache invalidation bug. 2. If it fired, does the response contain the secret? If no → server. 3. If server: read replica in play? ([lib/knex/index.ts:168](../../backend/src/lib/knex/index.ts)).
Useful probes: React Query Devtools (query state: fresh/stale/inactive); compare the create's invalidated keys ([mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx)) against the list's actual key ([queries.tsx:33-41](../../frontend/src/hooks/api/secrets/queries.tsx)) *param by param*.
Likely root causes: a param mismatch between invalidation and key (e.g. `viewSecretValue` differs); a new view whose key family was never added to the mutation; replica lag (rarer).
Regression test to add: UI-level test asserting refetch fires post-mutation; or a lint-style check that key factories are shared, never inlined.
Senior lesson: manual invalidation lists are a *known* failure class of this architecture ([critique](../03-architecture-and-patterns/06-architecture-critique.md)) — when a bug class recurs, fix the class (shared key discipline), not just the instance.
Interview version: narrate as "I bisected client vs server with the network tab in one step" — bisection narration is what debugging rounds grade.

## Scenario 2: "Machine token gets 401 on an endpoint that works for users"

Reproduction: `curl -H "Authorization: Bearer <identity token>" /api/v4/secrets/...` → 401/403; same call with user JWT works.
First question: rejected at *which* gate — identity extraction, mode allowlist, org requirement, or CASL?
Narrowing path: 1. Response body/name: `Token missing` → extraction ([inject-identity.ts](../../backend/src/server/plugins/auth/inject-identity.ts)); `Forbidden access to <url>` → mode allowlist ([verify-auth.ts:22](../../backend/src/server/plugins/auth/verify-auth.ts)); org message → line 28; CASL error → service. 2. Check the route's `verifyAuth([...])` list — is `IDENTITY_ACCESS_TOKEN` present? 3. If CASL: does the identity's role have the action for *this env/path*?
Useful probes: the `injectPermission` info logs print actor type and id per request ([inject-permission.ts:22-23](../../backend/src/server/plugins/auth/inject-permission.ts)); decode the JWT (`authTokenType` claim) to confirm which switch branch it takes ([inject-identity.ts:112](../../backend/src/server/plugins/auth/inject-identity.ts)).
Likely root causes: route allowlist missing the mode (each route hand-lists modes — compare with a sibling route); identity lacks project membership/role; token issued for a different org.
Regression test: e2e calling the route with an identity token (Recipe 3/4 in [02-writing-tests-here](02-writing-tests-here.md)).
Senior lesson: error *taxonomy* is a debugging interface — this repo's distinct error names per gate let you localize in one read. Design your own systems that way.
Interview version: "I mapped each possible 401/403 to the layer that emits it, then matched the message" — evidence-driven, no guessing.

## Scenario 3: "Secret sync to GitHub randomly doesn't happen"

Reproduction: intermittent — some secret updates never appear in the integration.
First question: was the job never enqueued, dropped, or did it fail after retries?
Narrowing path: 1. Logs: `syncSecrets: syncing project secrets where [projectId=...]` ([secret-queue.ts:603](../../backend/src/services/secret/secret-queue.ts)) — present for the missing update? If absent → producer path. 2. If enqueued: BullMQ job state in Redis — completed/failed/stuck? 3. If failed 5× → did the failure email fire ([secret-queue.ts:652-656](../../backend/src/services/secret/secret-queue.ts))? 4. Check `jobId` dedupe ([line 638](../../backend/src/services/secret/secret-queue.ts)): was a duplicate-key job dropped while an identical one was pending — and is that *correct* here?
Useful probes: Redis CLI on the queue keys; enqueue-time log vs process-time log timestamps.
Likely root causes: dedupe collapsing distinct work when payloads differ but the key doesn't; enqueue failure during a Redis blip (unhandled?); integration credentials expired (deterministic failure retried 5× then emailed — check spam, seriously).
Regression test: unit-level test of the jobId key function's collision behavior; e2e asserting two rapid updates produce a final converged sync.
Senior lesson: with at-least-once queues, "randomly missing" is usually either dedupe semantics or silent enqueue failure — check the *edges* of the queue, not the middle.
Interview version: perfect "debug a distributed thing" story — emphasize forming the three-way hypothesis (never enqueued / dropped / failed) *before* touching anything.

## Scenario 4: "Everyone got logged out after the copy-update deploy"

Reproduction: mass logouts correlating with a release that touched backend strings.
First question: what does the client *do* on 401, and what did the deploy change about 401s?
Narrowing path: 1. [request.ts:54-57](../../frontend/src/config/request.ts) — refresh only triggers when the 401 body message contains "token expired"/"stalesession". 2. Diff the deploy for auth error strings. 3. Confirm: expired-token 401s with the *new* message skip refresh → hard logout path (lines 91-125).
Useful probes: reproduce with one expired token + proxy to observe the exact 401 body; grep frontend for `isTokenExpiredError`.
Likely root cause: implicit string contract broken (Kata 7 in [review-katas](../04-code-reading-gym/04-review-katas.md) — this scenario is that kata, shipped).
Regression test: contract test pinning the auth error *code/message* the client depends on; better fix: introduce `errorCode` and match on it.
Senior lesson: any string a machine parses is an API. Inventory them (grep consumers) before "harmless" copy changes.
Interview version: great "postmortem" behavioral story — root cause, contributing factor (no contract test), prevention (typed error codes).

## Scenario 5: "The overview page is slow for big projects"

Reproduction: project with ~1k secrets across 5 envs; overview takes seconds, interactions jank.
First question: is time spent in network, server, or render?
Narrowing path: 1. Performance tab + network tab: one slow request, many requests, or fast requests + slow frames? 2. Many requests → check `useGetProjectSecretsAllEnv` fan-out ([queries.tsx:173-215](../../frontend/src/hooks/api/secrets/queries.tsx) — one query per environment). 3. Slow frames → React Profiler on [OverviewPage.tsx](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx) (3,759 lines; wide tables re-rendering on hover/selection state are the usual suspects). 4. Slow single request → server timing: DB query plan (missing index? unbounded query?), N+1 in the DAL.
Useful probes: React Profiler flamegraph; `EXPLAIN ANALYZE` on the dashboard query; row counts.
Likely root causes (hypotheses to verify, not conclusions): per-env parallel queries scaling with env count; monolithic component re-rendering wholesale; missing pagination on very large folders.
Regression test: perf budget test is overkill here; instead, a fixture project in dev with 1k+ secrets and a written measurement procedure (see [04-performance-thinking](04-performance-thinking.md)).
Senior lesson: **measure before theorizing** — three candidate layers, one 5-minute experiment each, *then* optimize the one that's guilty.
Interview version: the interviewer wants the measurement plan more than the fix. Lead with the three-way split.

---

Self-grade across scenarios — **Weak**: jumped to a fix hypothesis before reproducing. **Solid**: followed the loop, localized the layer with ≤3 probes. **Strong**: named the regression test *and* the class-level prevention for each. Timed interview versions of scenarios 1, 3, 4: [08-interview-prep/05](../08-interview-prep/05-debugging-and-code-review-rounds.md).
