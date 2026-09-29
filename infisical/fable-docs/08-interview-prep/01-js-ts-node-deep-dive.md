# JS / TS / Node Deep-Dive — 14 Question Cards

Format per card: what it's really testing · repo anchor · junior/mid/senior answer contrast · follow-ups · drill. Speak every answer aloud in ≤90 seconds.

## Q1: Explain the Node event loop. Why does it matter for a web server?
Round: JS/TS deep-dive. Really testing: do you connect the model to consequences.
Repo anchor: [secret-queue.ts:594-660](../../backend/src/services/secret/secret-queue.ts) — CPU/latency-heavy work exits the request path.
Junior: "single thread, callback queue, non-blocking I/O."
Mid adds: one synchronous hot loop delays *every* concurrent request; that's why Infisical ships integration syncs to BullMQ workers instead of awaiting them in the handler.
Senior includes: microtask vs macrotask ordering; when to use worker_threads vs a queue (shared memory CPU work vs durable retryable jobs); the invariant "request path spends its budget on durable state only."
Follow-ups: "what blocks the loop that people don't expect?" (JSON.parse of megabytes, sync crypto, catastrophic regex). Drill: narrate the create-secret request marking each await as I/O-yield vs CPU.

## Q2: Microtasks vs macrotasks — give an order-of-execution example.
Round: JS/TS deep-dive. Really testing: precision.
Repo anchor: conceptual — no direct anchor.
Junior: knows promises run "before timers" sometimes.
Mid adds: sync code → *all* microtasks (then-callbacks, queueMicrotask) → one macrotask (timer/I/O) → drain microtasks again; can predict `log/then/timeout` puzzles reliably.
Senior includes: starvation (a microtask that re-queues itself blocks timers forever); where this bites in production (recursive promise chains in a hot path).
Follow-ups: `process.nextTick` vs `queueMicrotask`. Drill: write and predict three ordering puzzles, verify with `node -e`.

## Q3: `Promise.all` vs `Promise.allSettled` vs sequential await — when each?
Round: JS/TS deep-dive. Really testing: failure-mode thinking, not API recall.
Repo anchor: [secret-dal.ts:29-40](../../backend/src/services/secret/secret-dal.ts) — `Promise.all` over parallel updates in one tx.
Junior: "all is parallel, it's faster."
Mid adds: `all` rejects on first failure *without cancelling* the rest — side effects continue; `allSettled` when partial results matter; sequential when order or backpressure matters. Cites bulkUpdate throwing on any missing row.
Senior includes: unhandled-rejection risk from abandoned branches; concurrency *limits* (p-limit style) as the missing middle; inside one DB connection parallel statements serialize anyway.
Follow-ups: "how do you cancel?" (AbortController plumbed through). Drill: annotate bulkUpdate's failure behavior — what state remains if update 3 of 10 throws inside the tx? (tx rolls back — connect the two mechanisms.)

## Q4: What is idempotency and why do queues force it on you?
Round: JS/TS deep-dive / system design. Really testing: distributed-systems literacy at mid level.
Repo anchor: [secret-queue.ts:626-648](../../backend/src/services/secret/secret-queue.ts) — `jobId` dedupe, `attempts: 5`, `removeOnComplete`.
Junior: "safe to run twice."
Mid adds: BullMQ is at-least-once (retries + redelivery), so handlers must converge; Infisical's sync pushes *current state* (naturally idempotent) and dedupes bursts with a deterministic jobId.
Senior includes: idempotency *keys* vs idempotent *operations*; the `removeOnComplete` subtlety (completed-job ids must clear or later work is dropped); exactly-once is a lie, you buy it with dedupe + convergence.
Follow-ups: "how would you make an email send idempotent?" (send-record with unique key checked in tx). Drill: classify each job type in secret-queue.ts as convergent or additive.

## Q5: How do you run work after responding to the user?
Round: JS/TS deep-dive. Really testing: reliability instincts.
Repo anchor: [secret-queue.ts:568-591](../../backend/src/services/secret/secret-queue.ts).
Junior: "setImmediate / don't await it."
Mid adds: fire-and-forget in-process loses work on crash/deploy; enqueue durable jobs with retries+backoff; show the exact options object from the repo.
Senior includes: the commit-vs-enqueue ordering problem and the outbox pattern; escalation channel for terminal failures ([secret-queue.ts:652-656](../../backend/src/services/secret/secret-queue.ts)).
Follow-ups: "what if Redis is down at enqueue?" Drill: whiteboard the outbox table for this repo (K2 prepares this).

## Q6: Closures — give a real bug and a real feature they enable.
Round: JS/TS deep-dive. Really testing: whether "closure" is a word or a tool.
Repo anchor: [request.ts:46-84](../../frontend/src/config/request.ts) — module-scope `refreshPromise` captured by interceptors (feature); every service factory closing over deps ([secret-service.ts:149+](../../backend/src/services/secret/secret-service.ts)).
Junior: defines lexical capture, maybe the loop-var bug.
Mid adds: the deduped-refresh singleton as deliberate shared state; factories-close-over-deps as DI-without-classes.
Senior includes: server-side module state = cross-request leakage; stale-closure class in React callbacks; how to *choose* closure vs class (no `this` rebinding hazards).
Follow-ups: "why is this safe client-side but a smell server-side?" Drill: reimplement the refresh dedupe blind (also Pattern 8's drill).

## Q7: How does error handling work across async boundaries?
Round: JS/TS deep-dive. Really testing: production scar tissue.
Repo anchor: [lib/knex/index.ts:166-173](../../backend/src/lib/knex/index.ts) typed wrapping; typed domain errors translated at the Fastify edge.
Junior: try/catch, .catch().
Mid adds: throw rich typed errors deep, translate to HTTP once at the edge; wrap-with-context at layer boundaries (`DatabaseError({error, name})`); swallowed-error anti-pattern.
Senior includes: error taxonomy as *debugging interface* (distinct names localize the failing gate — Scenario 2); unhandled rejections crash modern Node; retryable vs terminal classification driving queue behavior.
Follow-ups: "what belongs in an error message vs logs vs metrics?" Drill: trace one `NotFoundError` from service to HTTP status.

## Q8: `unknown` vs `any` — and where would you tolerate `any`?
Round: JS/TS deep-dive. Repo anchor: casts contained in [lib/knex/index.ts](../../backend/src/lib/knex/index.ts); zero-`any` service signatures.
Junior: "any disables checking, unknown is safer."
Mid adds: `any` is *transitive* poison through inference; `unknown` forces narrowing; this repo quarantines unsafety in one generic file and keeps consumers clean.
Senior includes: the boundary rule — parse (Zod) at trust boundaries so `unknown` becomes typed once; cast-audit as a review activity.
Follow-ups: `satisfies`? (check-without-widening). Drill: find any `as` cast in a service file and classify: bug or boundary (K5).

## Q9: How do you get runtime validation and static types from one source?
Round: JS/TS deep-dive. Repo anchor: [secret-router.ts:54-120](../../backend/src/server/routes/v4/secret-router.ts); generated DB schemas ([db/schemas/](../../backend/src/db/schemas/)).
Junior: "we use Zod."
Mid adds: schema → `z.infer` types → validation → OpenAPI, one artifact, three jobs; DB side: types *generated from the database* after migrations.
Senior includes: transforms as parsing at the boundary ("parse, don't validate"); the failure mode of logic-heavy schemas (60-line parser, untested); response schemas as accidental public contract.
Follow-ups: "how do you version when the schema must change?" (→ [03](03-api-and-data-modeling-questions.md) Q10). Drill: write the Zod schema for a webhook payload from memory of the shape.

## Q10: Generics — show me a generic you'd actually write.
Round: JS/TS deep-dive. Repo anchor: `ormify<DbOps, Tname extends keyof Tables>` ([lib/knex/index.ts:156-160](../../backend/src/lib/knex/index.ts)).
Junior: `function identity<T>(x: T): T`.
Mid adds: table-name parameter drives row types for every method from one implementation — generics as "write the pattern once, keep per-call-site types."
Senior includes: constraint design (`extends keyof Tables`); when to stop — the internal casts show the type-system ceiling, and containing them beats fighting them.
Follow-ups: variance intuition ("why can't I pass `(x: Dog) => void` where `(x: Animal) => void` is expected... or can I?"). Drill: write a mini `pickBy<T, K extends keyof T>` from scratch.

## Q11: What actually happens when you "start the dev server"?
Round: JS/TS deep-dive. Repo anchor: backend `tsx watch` vs frontend Vite ([02-stack/04](../02-stack-and-language-mastery/04-tooling-and-build-system.md)).
Junior: "it compiles and runs."
Mid adds: tsx = esbuild transform per file, Node executes, watch restarts; Vite = native-ESM dev serving with on-demand transform + HMR; prod inverts (tsup bundle vs Rollup build) — and *why* each runtime wants that.
Senior includes: cold-start and deployment consequences of bundling the server; type-checking is *separate* from transpilation in both (tsc is the checker, esbuild strips).
Follow-ups: "why is type-check a separate CI step?" Drill: explain what `npm run dev` skips that `npm run build` doesn't (type errors!).

## Q12: How do Node module systems bite you (ESM vs CJS)?
Round: JS/TS deep-dive. Repo anchor: conceptual — no direct anchor (both packages use bundler-mediated setups that paper over most of it).
Junior: "import vs require."
Mid adds: interop pain (default exports, `__dirname`, top-level await); bundlers/tsx normalize in dev, then prod config diverges — the classic "works in dev" class.
Senior includes: dual-package hazard; conditional exports; why path aliases (`@app/*`) need coordinated config in tsconfig + bundler + test runner — three places to drift.
Follow-ups: "how would you debug 'cannot use import outside a module'?" Drill: find where `@app/*` is configured in backend (tsconfig + vitest e2e env) — count the places.

## Q13: Explain `this` — and why this codebase barely uses it.
Round: JS/TS deep-dive. Repo anchor: factory style throughout ([secret-service.ts:149](../../backend/src/services/secret/secret-service.ts)).
Junior: call-site binding rules, arrow functions.
Mid adds: factories + closures eliminate rebinding hazards entirely — methods are plain functions over captured deps; contrast with class-based services needing `.bind` or arrows.
Senior includes: the tradeoff (per-instance memory of closures vs prototype sharing — irrelevant at "one instance per process" scale, decisive for 10k instances); knowing when the argument *doesn't* matter is the senior part.
Follow-ups: "when would you still pick classes?" (instanceof-based error hierarchies — which this repo's `lib/errors` uses!). Drill: find the class-vs-factory split in this repo and justify each side.

## Q14: What's a memory leak in a Node server and how do you find one?
Round: JS/TS deep-dive. Really testing: operational maturity.
Repo anchor: conceptual — plus the module-state discussion ([request.ts:46-52](../../frontend/src/config/request.ts) client-side singleton as the *contained* version).
Junior: "when memory grows."
Mid adds: usual suspects — unbounded caches/maps keyed by request data, listeners never removed, closures pinning big buffers, growing arrays in module scope; find with heap snapshots diffed under load.
Senior includes: leak vs churn (GC pressure); production approach — memory metrics trend + `--heapsnapshot-signal`; why queues with `removeOnComplete: true` ([secret-queue.ts:575](../../backend/src/services/secret/secret-queue.ts)) are Redis-side leak prevention of the same instinct.
Follow-ups: "your pod OOMs every 3 days — walk me through week one." Drill: name three places *this* repo could leak if options were removed (job retention, per-request memo maps, keystore entries without TTL).
