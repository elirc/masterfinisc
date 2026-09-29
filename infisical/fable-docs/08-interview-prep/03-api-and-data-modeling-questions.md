# API & Data Modeling — 12 Question Cards

## Q1: Design a REST endpoint well. What does "well" include?
Round: API/data. Repo anchor: [secret-router.ts:48-170](../../backend/src/server/routes/v4/secret-router.ts).
Junior: method + path + JSON.
Mid adds: the full route contract from this repo: schema-validated input, typed responses, rate-limit preset, auth-mode allowlist, operationId for docs, versioned path — one route definition carries all of it.
Senior includes: response schema as a public commitment (what you expose you maintain); error taxonomy; idempotency semantics per method (PUT/DELETE retryable, POST needs keys).
Follow-ups: "PATCH vs PUT here?" Drill: read one v4 route aloud and name each contract element.

## Q2: Where do you validate input, and where do you authorize?
Round: API/data. Repo anchor: five-layer table in [03/03](../03-architecture-and-patterns/03-validation-auth-and-permissions.md); CASL-in-service ([secret-v2-bridge-service.ts:339-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)).
Junior: "middleware validates and checks the user."
Mid adds: validate shape at the edge (Zod), business rules in services, authz in services with full context (so internal callers can't bypass), DB constraints as the last line; authn ≠ authz with the two-plugin example.
Senior includes: the tradeoff of service-layer authz (context threading through every signature) and fail-closed defaults ([permission-service.ts:416-418](../../backend/src/ee/services/permission/permission-service.ts)).
Follow-ups: "what does the DB constraint catch that code can't?" (concurrent check-then-write). Drill: Flow 3 teach-back.

## Q3: RBAC vs ABAC — when do roles stop being enough?
Round: API/data. Repo anchor: [project-permission.ts:15, 45, 323](../../backend/src/ee/services/permission/project-permission.ts); attribute subjects in service checks.
Junior: "roles group permissions."
Mid adds: roles break when access depends on the *resource* (env=prod, path=/payments/**); CASL subject attributes give per-attribute rules; real example: secret actions scoped by environment+path+tags.
Senior includes: policy-as-data audit difficulty ("who can read prod?" becomes evaluation, not grep); glob-boundary math needing real tests ([lib/casl/](../../backend/src/lib/casl/)); performance of per-request ability building.
Follow-ups: "how would you cache abilities safely?" Drill: write the rule for "read-only staging" on paper.

## Q4: Design pagination. Defend your choice.
Round: API/data. Repo anchor: `limit/offset/sort` support in [lib/knex/index.ts:177-196](../../backend/src/lib/knex/index.ts); `COUNT(*) OVER()` window for totals.
Junior: page/pageSize with OFFSET.
Mid adds: offset degrades linearly and skips/duplicates under concurrent writes; cursor (keyset) pagination for stable, deep lists; this repo's window-function total avoids a second COUNT query.
Senior includes: cursor design (opaque, composite key, tie-breaker on id); total counts as a *product* negotiation (expensive at scale — "about N" or none); per-endpoint choice by access pattern.
Follow-ups: "cursor + user-changeable sort?" Drill: design the cursor for secrets sorted by key within a folder.

## Q5: Model this: secrets with per-user overrides and full version history.
Round: API/data. Repo anchor: SecretType Shared/Personal ([models.ts:363-366](../../backend/src/db/schemas/models.ts)); shadow rule ([secret-v2-bridge-service.ts:312-329](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)); version rows + DAL increment ([secret-dal.ts:14-21](../../backend/src/services/secret/secret-dal.ts)).
Junior: secrets table + edits in place.
Mid adds: type column + userId for overrides with the "personal must shadow shared" invariant; separate versions table (immutable history) with version counter bumped atomically in the data layer.
Senior includes: where each invariant is enforced (type system / DAL / DB constraint) and the check-then-insert race on the duplicate rule; retention policy for versions.
Follow-ups: "how do you diff two versions efficiently?" Drill: draw the ERD from the glossary spine, then check the schemas.

## Q6: Transactions — what goes inside, what stays out?
Round: API/data. Repo anchor: `tx` threading ([lib/knex/index.ts:161-165](../../backend/src/lib/knex/index.ts)); enqueue-after-commit discipline ([03/04](../03-architecture-and-patterns/04-side-effects-async-and-reliability.md)).
Junior: "wrap related writes."
Mid adds: invariant-owning service opens the tx and threads it; external calls (HTTP, email) stay out — latency holds locks, rollback can't unsend; queue enqueue after commit.
Senior includes: the forgot-to-pass-tx silent failure; isolation levels when read-check-write matters; outbox as the atomicity completion.
Follow-ups: "deadlock — how does it happen and what do you do?" Drill: audit one service transaction block for tx threading (Pattern 5 drill).

## Q7: How do you change a production schema without downtime?
Round: API/data. Repo anchor: [20260513182201...](../../backend/src/db/migrations/20260513182201_add-folder-id-indexes-for-snapshot-prune.ts) — CONCURRENTLY, lock_timeout, transaction:false, guards.
Junior: "run the migration at night."
Mid adds: expand–contract; locks are the enemy, not duration; concurrent index builds; backfills batched separately; deploy-order awareness (old code must survive the new schema).
Senior includes: lock_timeout-fail-fast rationale; `down()` honesty (when rollback becomes roll-forward); migrations auto-run on boot here ([auto-start-migrations.ts](../../backend/src/auto-start-migrations.ts)) coupling deploy and migrate — name the consequence.
Follow-ups: "rename a column with zero downtime, step by step." Drill: K6 kata.

## Q8: Prevent IDOR in a multi-tenant API.
Round: API/data/security. Repo anchor: org context requirement ([permission-service.ts:416-418](../../backend/src/ee/services/permission/permission-service.ts)); scoped lookups ([secret-v2-bridge-service.ts:304](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)).
Junior: "check the user owns it."
Mid adds: systematic answer — tenant id from *auth context*, never from the request body; lookups scoped through the tenancy chain; ABAC assertion per operation; adversarial tests (two orgs) as the regression net.
Senior includes: 403-vs-404 existence leakage policy; id-based convenience routes as the high-risk surface; the "any authenticated user" default-deny posture.
Follow-ups: "what about batch endpoints?" (per-item authz!). Drill: write the J3 test plan aloud.

## Q9: Cache invalidation — tell me about a real strategy.
Round: API/data. Repo anchor: client: nine-family invalidation ([mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx)); server: secret cache with project-scoped invalidation (`invalidateSecretCacheByProjectId`, [secret-service.ts:143](../../backend/src/services/secret/secret-service.ts)); replica lag as a cache-coherence problem in disguise.
Junior: "set a TTL."
Mid adds: invalidate-on-write with explicit key design; scope granularity tradeoff (per-project invalidation = simple but broad); TTL as the backstop, not the strategy.
Senior includes: the three consistencies in this one system (React Query staleness, Redis cache, replica lag) and how each is bounded; thundering-herd on invalidation.
Follow-ups: "cache a permission check?" (dangerous — staleness = security). Drill: enumerate every cache between a user's eyeball and the secrets table.

## Q10: How do you version an API — and how do you avoid needing to?
Round: API/data. Repo anchor: four live versions ([routes/index.ts:3572-3591](../../backend/src/server/routes/index.ts)); v1-v4 secret routers coexisting.
Junior: "/v1, /v2 in the path."
Mid adds: additive-first evolution (new optional fields never break); version only for shape breaks; this repo carries four versions concurrently — name the maintenance cost you're signing up for.
Senior includes: deprecation as a *process* (usage telemetry → warnings → sunset — project P2's shape); contract tests pinning what consumers rely on; webhook payloads as unversioned contracts people forget.
Follow-ups: "how do you know when v1 can die?" Drill: find one route that exists in both v3 and v4 and diff their schemas.

## Q11: Walk me through securing an endpoint that fetches a user-supplied URL.
Round: API/data/security. Repo anchor: [validate-url.ts:13](../../backend/src/lib/validator/validate-url.ts), webhook flow ([key-flows Flow 5](../01-codebase-cartography/05-key-flows.md)).
Junior: "validate it's a valid URL."
Mid adds: SSRF — block private/link-local/localhost ranges, because the *server's* network position is the prize (cloud metadata endpoints); validate at create AND use; timeouts; store encrypted.
Senior includes: DNS rebinding (resolve-then-connect gap); egress allowlists/proxies as the infrastructure answer; response handling (never echo fetched content to the user raw).
Follow-ups: "redirects?" (re-validate each hop). Drill: list the three URL classes to reject and check them against the real validator.

## Q12: An endpoint is slow. Walk me through the server-side diagnosis.
Round: API/data. Repo anchor: [04-performance-thinking](../05-quality-engineering/04-performance-thinking.md) table; unbounded `find()` ([lib/knex/index.ts:190](../../backend/src/lib/knex/index.ts)).
Junior: "add an index."
Mid adds: partition the budget (auth/permission build, business queries, serialization); query log to count queries (N+1?) then EXPLAIN the slow one; check missing limit/pagination.
Senior includes: p95-not-average thinking; the permission-build cost as a per-request fixed tax worth caching carefully; index write-amplification tradeoff.
Follow-ups: "EXPLAIN shows Seq Scan but the index exists — why?" (selectivity, type mismatch, stale stats). Drill: Scenario 5's measurement plan, server half only.
