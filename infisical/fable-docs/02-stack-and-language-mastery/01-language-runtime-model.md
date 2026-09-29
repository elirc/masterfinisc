# Language & Runtime Model (Node/JS)

## The event loop, in one paragraph

Node runs your JS on one thread. I/O (DB queries, HTTP calls, Redis) is handed to the runtime and completes later via callbacks/promises; CPU work you write runs to completion and blocks everything else meanwhile. Promise callbacks run on the *microtask* queue (drained completely after each task, before timers/I/O). Consequence for a server like this backend: one slow synchronous loop in a handler delays *every* concurrent request. That's why heavy work (integration syncs, webhook fanout, replication) is shipped to BullMQ workers in [secret-queue.ts](../../backend/src/services/secret/secret-queue.ts) instead of running in the request.

## Serial vs parallel awaits — the #1 practical async skill

Real example of deliberate parallelism: [secret-dal.ts:29-40](../../backend/src/services/secret/secret-dal.ts) `bulkUpdate` runs every update through `Promise.all(data.map(...))` — all statements in flight at once, on one transaction.

```ts
// Illustrative fake code: not from this repo.
// Serial — 3 round trips, ~3x latency:
const a = await dal.findById(idA);
const b = await dal.findById(idB);
const c = await dal.findById(idC);
// Parallel — 1 round trip of wall time:
const [a2, b2, c2] = await Promise.all([dal.findById(idA), dal.findById(idB), dal.findById(idC)]);
```

Failure modes to know: `Promise.all` rejects on the *first* failure and does not cancel the others (they keep running — with side effects). If partial success must be observed, `Promise.allSettled`. Inside a DB transaction, parallel statements on one connection are serialized by the driver anyway — the win shrinks; and an unhandled rejection from an abandoned branch can crash Node.

## Fire-and-forget, done deliberately

`syncSecrets` ([secret-queue.ts:594-648](../../backend/src/services/secret/secret-queue.ts)) is awaited only up to *enqueue*; the actual work happens later in a worker. That converts "user waits for GitHub's API" into "user waits for one Redis write." The cost: you now need retries (`attempts: 5`, exponential backoff at lines 640-647), idempotent handlers, and a failure-visibility channel (the failed-sync email job, lines 652-656). Say "at-least-once delivery" and "idempotency" out loud — interview vocabulary, both defined precisely by this file.

## Closures and module-level state

[request.ts:46-52](../../frontend/src/config/request.ts) holds `isRedirecting` and `refreshPromise` as module-level variables captured by the interceptor closures. This is a *deliberate singleton*: all requests in the tab share one refresh. The same mechanism is the classic footgun on the server — module-level mutable state in the backend would be shared across all requests and users. Notice the repo's backend services avoid it: state lives in the DB/Redis, services are stateless factories.

## Error handling model

Every `ormify` method wraps driver errors into typed `DatabaseError`s ([lib/knex/index.ts:166-173](../../backend/src/lib/knex/index.ts)); services throw typed errors (`BadRequestError`, `NotFoundError`, `ForbiddenRequestError` — see [lib/errors](../../backend/src/lib/errors/)) that a central Fastify error handler maps to status codes. Transferable principle: *throw rich, typed errors deep; translate to transport codes once, at the edge.* The anti-pattern is `catch (e) { return null }` — a swallowed error that resurfaces as a mystery 500 three layers up.

## Pitfall checklist

- [ ] `await` in a loop where `Promise.all` was intended (or vice versa when order matters)
- [ ] Unawaited promise whose rejection nobody handles (crashes Node ≥15)
- [ ] CPU-heavy work (crypto, big JSON, regex backtracking) inside a request handler
- [ ] Module-level mutable state on the server
- [ ] Mixing microtask assumptions with timers ("why did my `setTimeout(0)` run after all those `.then`s?")

## Drills

1. In [secret-queue.ts:594-648](../../backend/src/services/secret/secret-queue.ts), list what the request thread actually waits for vs what a worker does later.
2. Rewrite (on paper) `bulkUpdate` ([secret-dal.ts:23-45](../../backend/src/services/secret/secret-dal.ts)) as a serial loop, then argue which version you'd ship inside a transaction and why.
3. Predict output order of a `console.log` / `.then` / `setTimeout(0)` triplet, then run it in `node -e`.

## Interview angle

- "Explain the event loop / microtasks vs macrotasks" → answer with the blocked-handler consequence, then the queue-offload pattern from `secret-queue.ts`. (See [08-interview-prep/01](../08-interview-prep/01-js-ts-node-deep-dive.md) Q1–Q3.)
- "`Promise.all` vs `allSettled` vs serial `await`?" → cite `bulkUpdate`, name first-rejection semantics and non-cancellation. (Q4)
- "How do you run something after the response is sent?" → enqueue with retries + idempotency, not `setTimeout`. (Q5)
- "What's wrong with global variables in a Node server?" → contrast with the *intentional* client-side singleton in `request.ts`. (Q6)
