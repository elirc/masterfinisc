# Pattern Catalog

14 patterns you can now *recognize*, not just name. Format per card: problem → shape → real anchors → why it works → failure modes → when (not) to use → interview angle → drill.

---

## Pattern 1: Service Factory with Manual DI

Problem it solves: testable, explicit composition without an IoC container.
General shape: `const xServiceFactory = (deps) => ({ methodA, methodB })`; the whole graph wired by hand in one place.
Real example: [secret-service.ts:149+](../../backend/src/services/secret/secret-service.ts)
Second example: [webhook-service.ts:39-45](../../backend/src/services/webhook/webhook-service.ts); wiring in [routes/index.ts:538+](../../backend/src/server/routes/index.ts)
Why this implementation works: zero magic — the dependency graph is grep-able; factories close over deps, so no `this` binding issues.
Failure modes: the wiring file grows unboundedly (3,606 lines here); circular deps must be broken by hand; construction order becomes tribal knowledge.
Use it when: the team values explicitness and the graph is wired once at boot. Avoid it when: hundreds of contributors churn the graph daily (container or code-gen wiring scales better).
Interview angle: "How do you do dependency injection in Node without a framework?" — this exact pattern, plus its scaling cost.
Drill: pick any service in [routes/index.ts](../../backend/src/server/routes/index.ts), list its deps from the call site, then verify against its `TDep` type.

## Pattern 2: `Pick`-Narrowed Dependency Contracts

Problem it solves: dependencies wide enough to work, narrow enough to reveal true coupling.
General shape: `dep: Pick<TFullFactory, "onlyMethod" | "otherMethod">`.
Real example: [secret-service.ts:113-127](../../backend/src/services/secret/secret-service.ts)
Second example: [webhook-service.ts:32-34](../../backend/src/services/webhook/webhook-service.ts) (`Pick<TProjectDALFactory, "findById">`)
Why this implementation works: compile-checked least privilege; test stubs shrink to the used surface.
Failure modes: `Pick` lists drift into noise if methods are added carelessly; refactoring a method name touches many `Pick`s (the compiler catches all of them — that's the point).
Use it when: modules consume small slices of big modules. Avoid it when: the dep is used wholesale anyway.
Interview angle: interface segregation with zero ceremony — a differentiating answer to "how do you manage coupling?"
Drill: find one dep taken un-narrowed in any service and propose its minimal `Pick`.

## Pattern 3: Table Gateway (`ormify`)

Problem it solves: 100+ tables needing identical CRUD without an ORM's weight or hand-written repetition.
General shape: generic factory `ormify(db, tableName)` returns typed `findById/find/create/update/delete/transaction`.
Real example: [lib/knex/index.ts:156-326](../../backend/src/lib/knex/index.ts)
Second example: every `*-dal.ts`, e.g. [secret-dal.ts:12](../../backend/src/services/secret/secret-dal.ts)
Why this implementation works: one audited implementation of error wrapping, replica routing, tx threading; DALs extend rather than reinvent.
Failure modes: generic types require internal casts; complex queries escape the abstraction (by design — they land in DAL customs); "just add an option to ormify" pressure bloats the core.
Use it when: many entities share access patterns. Avoid it when: a full ORM's features (lazy relations, identity map) are genuinely needed.
Interview angle: "ORM vs query builder vs raw SQL?" — this is the middle position, with receipts.
Drill: list which `ormify` methods `secret-dal` overrides vs inherits, and why each override exists.

## Pattern 4: Read-Replica Routing

Problem it solves: read scale-out without touching call sites.
General shape: reads → `(tx || db.replicaNode())`, writes → `(tx || db)`.
Real example: [lib/knex/index.ts:168, 184, 205](../../backend/src/lib/knex/index.ts) vs `create` at 211-218
Second example: `docker-compose.dev-read-replica.yml` at repo root (the infra half)
Why this implementation works: policy encoded once in the gateway; a `tx` always pins to primary, so transactional read-your-writes is preserved.
Failure modes: replica lag breaks read-after-write across *separate* calls (create → immediately find on replica may miss); developers unaware of the routing debug "phantom" staleness for hours.
Use it when: read-heavy traffic and tolerance for seconds of staleness. Avoid it when: every read must be current (or route those reads explicitly to primary).
Interview angle: "How would you scale database reads?" + the read-your-writes caveat = solid mid-level; naming the tx-pins-primary subtlety = senior.
Drill: write the failure scenario: user creates a secret, list view queries a lagged replica. What does the UI show, and which layer should fix it?

## Pattern 5: Transaction Threading (`tx` parameter)

Problem it solves: composing multiple DAL calls into one atomic unit without global transaction state.
General shape: every DAL method takes optional trailing `tx`; the invariant-owning service opens `dal.transaction(cb)` and passes `tx` down.
Real example: [lib/knex/index.ts:161-165](../../backend/src/lib/knex/index.ts) (transaction); every method's `(tx || db)`
Second example: `Pick<..., "transaction">` deps, e.g. `secretApprovalRequestDAL` in [secret-service.ts:135](../../backend/src/services/secret/secret-service.ts)
Why this implementation works: explicit — you can see atomicity at the call site; no AsyncLocalStorage magic to debug.
Failure modes: forgetting to pass `tx` to one call inside the block silently breaks atomicity (compiles fine!); long transactions holding locks.
Use it when: multi-row invariants. Avoid: wrapping slow external calls inside a tx.
Interview angle: "How do you ensure atomicity across multiple writes?" — and the classic follow-up "what bug happens when someone forgets the tx param?" is precisely its failure mode.
Drill: grep one service for `.transaction(` and audit every DAL call inside for `tx` threading.

## Pattern 6: Query-Key Factory

Problem it solves: cache identity as a single source of truth per API domain.
General shape: `export const xKeys = { list: (params) => [{...params}, "label"] as const, ... }`.
Real example: [secrets/queries.tsx:33-58](../../frontend/src/hooks/api/secrets/queries.tsx)
Second example: any of the 100+ domains under [frontend/src/hooks/api/](../../frontend/src/hooks/api/)
Why this implementation works: invalidation and subscription always agree on identity; `as const` keeps keys precisely typed.
Failure modes: a param omitted from the key ⇒ two screens share wrong data; inconsistent key shapes across domains make predicate-based invalidation fragile (see the predicate hack at [mutations.tsx:62-70](../../frontend/src/hooks/api/secrets/mutations.tsx)).
Use it when: always, with React Query. Avoid: inline ad-hoc keys.
Interview angle: "How does React Query caching actually work?" — keys as identity is the core insight.
Drill: find one query key in another domain that includes a param `getProjectSecret` doesn't, and explain why.

## Pattern 7: Invalidation-on-Mutation

Problem it solves: keeping N derived views consistent after a write, without websockets.
General shape: mutation `onSuccess` → invalidate every key family whose data the write could change.
Real example: [secrets/mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx) — nine families (dashboard, imports, snapshots, commits, approvals...)
Second example: update/delete mutations in the same file (L132+)
Why this implementation works: refetch-on-invalidate is simple and always converges to server truth.
Failure modes: the list is *manual* — every new derived view must be added to every relevant mutation (grep-and-pray); over-invalidation causes refetch storms.
Use it when: writes are infrequent relative to reads. Avoid/augment when: real-time collaboration needs push updates, or when optimistic updates are worth the rollback complexity.
Interview angle: "Optimistic updates vs invalidation?" — cost/benefit with this file as the conservative baseline.
Drill: add (on paper) a hypothetical "secrets count" widget: list every mutation file you must touch. Feel the pattern's tax.

## Pattern 8: Singleton In-Flight Promise (refresh dedupe)

Problem it solves: N concurrent 401s must trigger exactly one token refresh.
General shape: module-level `promise | null`; first caller creates it, all await it, `finally` clears it.
Real example: [request.ts:52, 75-84](../../frontend/src/config/request.ts)
Second example: No second example found in this repo (the pattern also underlies request-memoization — cf. `requestMemoize` in [secret-v2-bridge-service.ts:349-351](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts), a per-request cache of the same spirit).
Why this implementation works: the *promise itself* is the lock; JS single-threadedness makes check-then-set race-free.
Failure modes: forgetting `finally` ⇒ permanent stuck state after one failure; storing a boolean instead of the promise ⇒ latecomers can't await the result.
Use it when: deduplicating any expensive concurrent-identical async work. Avoid: cross-process dedupe (needs Redis locks — see keystore).
Interview angle: verbatim frontend interview classic ("handle token refresh with concurrent requests").
Drill: reimplement it blind in 15 lines; compare against the real file.

## Pattern 9: Schema-as-Contract (Zod route schemas)

Problem it solves: validation, typing, and API documentation drifting apart.
General shape: one Zod schema per route → runtime validation + inferred TS types + generated OpenAPI (`operationId`).
Real example: [secret-router.ts:54-170](../../backend/src/server/routes/v4/secret-router.ts)
Second example: recursive schema with `z.lazy` at lines 40-44 same file
Why this implementation works: a single artifact cannot drift from itself.
Failure modes: heavy transforms hide logic in schemas (the 60-line metadataFilter parser); response schemas that over-expose fields become accidental public API.
Use it when: any HTTP boundary. Avoid: putting multi-branch business parsing in schemas — extract to tested functions.
Interview angle: "How do you keep docs and code in sync?" — you have a one-word answer with receipts: you don't; you generate.
Drill: from the route schema alone, write the curl request for listing secrets with two metadata filters.

## Pattern 10: Attribute-Based Authorization (CASL)

Problem it solves: "role can do action" is too coarse for env/path/tag-scoped secret access.
General shape: build ability from roles → `throwUnlessCan(action, subject(type, attributes))`.
Real example: [secret-v2-bridge-service.ts:339-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)
Second example: action/subject vocabulary at [project-permission.ts:15, 45, 323](../../backend/src/ee/services/permission/project-permission.ts); glob-boundary tests in [lib/casl/](../../backend/src/lib/casl/)
Why this implementation works: policy is data (MongoDB-style rules), evaluated uniformly; service-layer placement means no route can forget it.
Failure modes: policy-as-data is hard to statically audit ("who can touch prod?" becomes a query, not a grep); attribute sets must be passed correctly at *every* call site — omitting `secretTags` would silently widen access.
Use it when: multi-tenant, resource-scoped products. Avoid when: three roles and flat resources — plain checks read better.
Interview angle: RBAC vs ABAC with a live example; also "where do you enforce authorization?"
Drill: write the CASL rule (on paper) for "read-only on env=staging, path /web/**" and find which enum values it needs.

## Pattern 11: Deterministic Job ID (queue dedupe)

Problem it solves: bursty triggers (five edits in two seconds) shouldn't queue five identical syncs.
General shape: `jobId = f(logical identity)` so BullMQ treats duplicates as the same pending job.
Real example: [secret-queue.ts:638](../../backend/src/services/secret/secret-queue.ts) (`$getJobKey(projectId, env, path)`)
Second example: the failure-email job id at [secret-queue.ts:653](../../backend/src/services/secret/secret-queue.ts) (`send-failed-...-${projectId}-${path}-${env}`)
Why this implementation works: dedupe by identity, not by time window; combined with `removeOnComplete: true` so the key is reusable after completion.
Failure modes: forgetting removeOnComplete ⇒ later legitimate jobs silently dropped (id "already exists"); too-coarse key ⇒ dropped distinct work; random UUID jobId (see [secret-queue.ts:577](../../backend/src/services/secret/secret-queue.ts)) opts *out* of dedupe — sometimes correctly!
Use it when: convergent jobs (sync-to-current-state). Avoid when: each event must be processed (deltas) — then dedupe loses data.
Interview angle: "How do you avoid duplicate processing in queues?" — dedupe key + idempotent handler, and know which of the two you're relying on.
Drill: for each `queueService.queue` call in secret-queue.ts, classify: dedupes or not, and argue why that's correct for that job type.

## Pattern 12: Retry, Backoff, and Escalation

Problem it solves: transient downstream failures shouldn't lose work; permanent ones shouldn't retry forever silently.
General shape: `attempts: N, backoff: exponential` + terminal-failure handler that notifies humans.
Real example: [secret-queue.ts:568-591, 640-647](../../backend/src/services/secret/secret-queue.ts); escalation email at 652-656
Second example: frontend `retry: 1` global ([reactQuery.tsx:223](../../frontend/src/hooks/api/reactQuery.tsx)) — same idea, different budget.
Why this implementation works: exponential backoff prevents hammering a struggling dependency; the email job converts "silent rot" into a human task.
Failure modes: retrying non-idempotent work; retrying 4xx (deterministic failures) wastes attempts; no jitter ⇒ synchronized retry storms (check whether backoff here jitters — investigate).
Use it when: any network effect. Avoid: retrying validation errors.
Interview angle: "Design a resilient integration" — retries/backoff/jitter/escalation is the expected quartet.
Drill: compute worst-case total delay for 5 exponential attempts with the base in the file; is it acceptable for secret sync?

## Pattern 13: Registration-Order Overriding (EE shadowing)

Problem it solves: enterprise edition extends/overrides community behavior without forking files.
General shape: register EE routes before community routes per API version; first match wins.
Real example: [routes/index.ts:3572-3573](../../backend/src/server/routes/index.ts) (`registerV1EERoutes` before `registerV1Routes`)
Second example: `backend/src/ee/` services layered over community services throughout wiring.
Why this implementation works: one codebase, license boundary expressed structurally; community build simply lacks EE registrations.
Failure modes: invisible override — you edit the community route and nothing changes because EE shadows it; ordering becomes load-bearing and nobody documents *which* routes are shadowed.
Use it when: open-core products. Avoid: using ordering tricks for non-licensing logic — too implicit.
Interview angle: "How would you structure an open-core codebase?" — rare, memorable answer material.
Drill: pick one EE route file and find whether a community route with the same path exists; describe which handler wins and why.

## Pattern 14: Data-Layer Invariant Enforcement

Problem it solves: an invariant ("every update bumps version") that must hold across all callers forever.
General shape: override the generic write in the DAL; make the type system forbid manual control (`Omit<..., "version">`).
Real example: [secret-dal.ts:14-21](../../backend/src/services/secret/secret-dal.ts) (`.increment("version", 1)` fused into update)
Second example: `bulkUpdateNoVersionIncrement` (same file, L46+) — the *named escape hatch*, greppable and reviewable.
Why this implementation works: enforcement sits below every caller; the escape hatch is explicit rather than a boolean flag.
Failure modes: raw knex writes bypass the DAL (grep for direct `db(TableName.Secret)` outside the DAL to audit); escape hatches multiply if the invariant was wrong.
Use it when: invariants about *data shape/versioning*. Avoid: business rules that need context (those belong in services).
Interview angle: "Where do you enforce invariants?" — layered answer: type-level (Omit) → DAL → DB constraint, choosing the lowest layer that has enough context.
Drill: propose the DB-level version of this invariant (trigger or check) and argue whether it's worth it.

---

## Recognition drill (whole catalog)

Open a service you've never read (suggestion: [backend/src/services/project-env/](../../backend/src/services/project-env/)). In 20 minutes, find and note instances of at least five of the fourteen patterns. Speed matters — pattern recognition under time pressure is exactly what interview code-reading rounds measure.
