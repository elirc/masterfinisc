# Architecture Critique

An honest assessment — strengths, risks, and what I'd change owning this for three months. Confirmed observations are anchored; everything else is labeled hypothesis. **This file doubles as system-design interview material** — see [08-interview-prep/04](../08-interview-prep/04-system-design-from-this-repo.md), which reuses it.

## Strongest design choices (steal these)

1. **Authorization in the service layer, attribute-based.** No route can forget permissions because routes don't do permissions ([secret-v2-bridge-service.ts:339-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)). ABAC subjects (env/path/name/tags) give real least-privilege.
2. **Explicit everything.** Manual DI ([routes/index.ts](../../backend/src/server/routes/index.ts)), `Pick` contracts, `tx` threading, hand-listed invalidations. The system trades ceremony for grep-ability; onboarding cost is low relative to its size.
3. **Schema-first HTTP.** Zod → validation + types + OpenAPI from one artifact ([secret-router.ts:54+](../../backend/src/server/routes/v4/secret-router.ts)).
4. **Production-literate migrations.** Concurrent index builds, lock timeouts, non-transactional config where required ([20260513182201...](../../backend/src/db/migrations/20260513182201_add-folder-id-indexes-for-snapshot-prune.ts)).
5. **Reliability defaults on async paths.** Retries, backoff, dedupe keys, failure emails ([secret-queue.ts:568-660](../../backend/src/services/secret/secret-queue.ts)).
6. **Supply-chain posture.** `min-release-age=7`, FIPS-aware dependency policy.

## Risks and tradeoffs (confirmed observations)

| Risk | Evidence | Who pays |
| --- | --- | --- |
| Wiring god-file | 3,606-line [routes/index.ts](../../backend/src/server/routes/index.ts); every feature PR touches it | Merge conflicts; slow reviews |
| Check-then-insert races | duplicate-secret check is a read, then insert ([secret-v2-bridge-service.ts:316-323](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)); unless a DB unique constraint backs it (**investigate**), concurrent creates can double-write | Data integrity under concurrency |
| No transactional outbox | job enqueue is a Redis write separate from the DB tx ([03/04-side-effects](04-side-effects-async-and-reliability.md)) | Crash window: committed change, lost sync job |
| Manual invalidation lists | nine hand-maintained families per mutation ([mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx)) | Stale-UI bugs on every new derived view |
| Giant page components | 3,759-line [OverviewPage.tsx](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx) | Render perf; reasoning cost; conflict-prone |
| Error-contract by message string | client matches "token expired" text ([request.ts:54-57](../../frontend/src/config/request.ts)) | One copy edit logs everyone out |
| Dual secrets engines | `services/secret/` + `secret-v2-bridge/` both live | New code lands on wrong engine; double maintenance |
| Deprecated auth modes still active | `API_KEY`/`SERVICE_TOKEN` handled in [inject-identity.ts:94+](../../backend/src/server/plugins/auth/inject-identity.ts) | Security surface kept alive for compat |

Hypotheses (not confirmed, would need measurement): metadataFilter's hand parser has edge-case 500s; retry backoff lacks jitter; webhook e2e coverage gap (searched `e2e-test/`, no webhook spec found — this one is close to confirmed).

## What I'd change owning this for 3 months (prioritized)

1. **Add a unique constraint under the duplicate-secret check** (if absent). Migration: `CREATE UNIQUE INDEX CONCURRENTLY ... ON secrets(folderId, key, type) WHERE type='shared'` — expand-contract, plus mapping the constraint violation to the existing 400. *Test strategy*: concurrent-create e2e that today double-writes. *Migration path*: audit existing dupes first, clean, then enforce. Low blast radius, closes a real race.
2. **Error codes over messages in the auth contract.** Add `errorCode: "TOKEN_EXPIRED"` to the 401 body; client matches code, message stays human. Backward compatible (keep matching both during transition). *Test*: interceptor unit test (none exists — write it first).
3. **Extract the metadataFilter parser** to `parse-metadata-filter.ts` + property-ish unit tests; schema keeps a one-line `.transform(parseMetadataFilter)`. Zero behavior change intended; tests define current behavior first.
4. **Shard the wiring file** by product area (`wireSecretsGraph(db) → {...}`), mechanical refactor, no behavior change; measure by conflict rate.
5. **Outbox for sync enqueue** — only if incident data shows lost jobs; otherwise document the crash window and rely on scheduled reconciliation. (Senior judgment includes *not* building the fancy thing.)
6. **Split OverviewPage** along its natural seams (toolbar / table / drawers), behind identical props; snapshot the rendered DOM before/after.

Each proposal names its test strategy and migration path — that's the difference between a critique and a complaint, and it is exactly the structure a system-design interviewer wants when they ask "what would you improve?"

## Drill

Defend the *opposite* position for items 1 and 4: why might the maintainers be right to leave them as-is? (1: writes are per-folder rare, races unobserved in practice, partial unique indexes complicate the multi-engine migration; 4: one wiring file is trivially searchable and the conflict cost may be lower than the indirection cost.) Being able to argue both sides is the actual senior skill.

Self-grade — Basic: restated the risks. Solid: for one risk, produced fix + test + rollback. Strong: argued both sides of two items with costs quantified in reviewer-hours or incident likelihood.
