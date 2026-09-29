# Performance Thinking

Rule zero: **measure first**. Every subsection below names the measurement before the candidate fix. Optimizing unmeasured code is how you make systems slower and PRs unreviewable.

## The performance domains in this system

| Domain | Measure with | Likely hotspots here (hypotheses with anchors — verify by measuring) |
| --- | --- | --- |
| **DB queries** | `EXPLAIN ANALYZE`, pg_stat_statements, Knex query logs | Unbounded `find()` calls — `ormify.find` applies `limit` only if provided ([lib/knex/index.ts:190](../../backend/src/lib/knex/index.ts)); recent migrations adding indexes for prune jobs ([20260513182201...](../../backend/src/db/migrations/20260513182201_add-folder-id-indexes-for-snapshot-prune.ts)) show where scans hurt in practice |
| **N+1** | query log while loading one page | any DAL loop calling `findById` per item; the repo's own antidotes: joins + `sqlNestRelationships`, `$in` filters, `Promise.all` batches ([secret-dal.ts:23-45](../../backend/src/services/secret/secret-dal.ts)) |
| **Serial async** | request waterfalls in server traces | sequential awaits that could be `Promise.all`; per-request memoization already fights duplicate loads (`requestMemoize`, [secret-v2-bridge-service.ts:349-351](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)) |
| **Network (client)** | devtools network tab | per-environment query fan-out in `useGetProjectSecretsAllEnv` ([queries.tsx:173-215](../../frontend/src/hooks/api/secrets/queries.tsx)); over-invalidation refetch storms after mutations ([mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx)) |
| **Render** | React Profiler | 3,759-line [OverviewPage.tsx](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx); wide tables re-rendering on selection/hover state |
| **Bundle** | `vite build` output, rollup-plugin-visualizer | WASM crates and heavy admin-only pages — check route-level code splitting in the router |
| **Cache** | React Query Devtools; Redis hit rates | `staleTime` policy ([reactQuery.tsx:222-224](../../frontend/src/hooks/api/reactQuery.tsx)); backend `with-cache` helper ([lib/cache/with-cache.test.ts](../../backend/src/lib/cache/with-cache.test.ts)); secret cache invalidation (`invalidateSecretCacheByProjectId` dep at [secret-service.ts:143](../../backend/src/services/secret/secret-service.ts)) |
| **Queue/memory** | BullMQ metrics, heap snapshots | job payload sizes; `removeOnComplete` keeping Redis lean ([secret-queue.ts:575](../../backend/src/services/secret/secret-queue.ts)) |

## How to find each classic, concretely

- **N+1**: enable Knex query logging in dev, load one page, count queries. >20 similar queries differing only in an id = found it. Fix at the DAL with a join/`$in`, never by caching over it.
- **Serial async**: add timing logs around suspicious service blocks; if total ≈ sum of parts rather than max of parts, awaits are serial. Fix with `Promise.all` *when independent* — see [02-stack/01](../02-stack-and-language-mastery/01-language-runtime-model.md) for the cancellation caveat.
- **Expensive renders**: React Profiler → commit ranking. Fix state placement first (move selection state down), memoize second (`memo`/`useMemo` on row components), restructure last.
- **Oversized bundles**: build with the visualizer; look for admin/rarely-used pages in the main chunk. Fix: route-level `lazy` splitting.
- **Missing indexes**: `EXPLAIN` showing Seq Scan on a large table under a WHERE. Fix: `CREATE INDEX CONCURRENTLY` migration (the repo shows you exactly how).
- **Unbounded queries**: grep DAL `find(` calls feeding list endpoints without `limit`. The fix is pagination at the API level — a contract change, so it's a ticket, not a hotfix.

## Latency budgets (the senior framing)

A user-facing request here spends: auth extraction (JWT verify) → permission build (role queries — cached? **investigate**) → business reads → response. The write path adds queue enqueue (one Redis op — cheap; that's the *point* of Flow 4). When someone says "the API is slow," partition the budget before touching code — the fix for a 40ms permission build is different from a 2s table scan.

## Drill

Pick `GET /api/v4/secrets` for a project with many folders. Write the measurement plan (three probes, one per layer), predict the top cost, then — if you have the dev stack running — measure and compare. Self-grade: **Weak** — proposed a fix first. **Solid** — plan isolates layers cheaply. **Strong** — prediction stated *with a falsifiable number* before measuring, and you updated your model when wrong.

Interview angle: "How would you speed up a slow page/endpoint?" — the winning shape is always: partition (network/server/DB/render) → measure → name the classic for the guilty layer → fix at the right layer → prevent regression. Practice saying it with this repo's anchors. Cross-linked from [08-interview-prep/02](../08-interview-prep/02-frontend-framework-questions.md) and [03](../08-interview-prep/03-api-and-data-modeling-questions.md).
