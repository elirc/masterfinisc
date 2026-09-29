# Side Effects, Async, and Reliability

## Map of side effects (where the outside world gets touched)

| Side effect | Trigger | Mechanism | Anchor |
| --- | --- | --- | --- |
| Integration sync (push secrets to GitHub/AWS/...) | secret change | BullMQ `IntegrationSync`, 5 attempts, exp backoff | [secret-queue.ts:568-577](../../backend/src/services/secret/secret-queue.ts) |
| Secret replication (copy across projects/envs) | secret change | BullMQ `SecretReplication`, 5 attempts | [secret-queue.ts:582-591](../../backend/src/services/secret/secret-queue.ts) |
| Secret sync fan-out | secret change | BullMQ `SecretSync`, deterministic `jobId` dedupe | [secret-queue.ts:594-648](../../backend/src/services/secret/secret-queue.ts) |
| Webhooks (outbound HTTP to user URLs) | secret events | BullMQ `SecretWebhook` → `fnTriggerWebhook` | [secret-queue.ts:674-675](../../backend/src/services/secret/secret-queue.ts), [webhook-fns.ts:285-320](../../backend/src/services/webhook/webhook-fns.ts) |
| Failure-notification email | sync failures | dedicated queue job | [secret-queue.ts:652-656](../../backend/src/services/secret/secret-queue.ts) |
| Audit logs | ~every mutating request | audit-log service/queue in [backend/src/ee/services/audit-log/](../../backend/src/ee/services/audit-log/) | — |
| Reminders / cron | schedules | cron lib ([lib/cron/cron-job.test.ts](../../backend/src/lib/cron/cron-job.test.ts) shows the wrapper is unit-tested) | — |

Pattern to internalize: **the request path writes the DB and enqueues; workers touch the world.** The user's latency budget is spent on durable state, not on third parties.

## The reliability toolkit, as used here

- **Retries + exponential backoff**: `attempts: 5, backoff: {type: exponential...}` on every producer above. Retries only help with *transient* faults; a 400 from GitHub will fail five times identically — which is why failures escalate to email.
- **Idempotency** (safe to apply twice): required because BullMQ is at-least-once. Deterministic `jobId: $getJobKey(projectId, env, path)` ([secret-queue.ts:638](../../backend/src/services/secret/secret-queue.ts)) collapses duplicate *pending* work; `removeOnComplete: true` lets the same key be reused later. Handlers should also be *logically* idempotent — syncing the current state (not a delta) is naturally so: pushing the full current secret set twice converges.
- **Timeouts**: any outbound HTTP without a timeout is a worker leak. Webhook requests go through `triggerWebhookRequest` ([webhook-fns.ts:38](../../backend/src/services/webhook/webhook-fns.ts)) — read it and note the configured timeout (drill 2).
- **Failure visibility**: the failed-sync email job is the humble version of alerting: *someone finds out.* A senior asks of every async path, "who notices when this silently fails, and how fast?"
- **Locks/coordination**: Redis-backed keystore provides distributed locks ([backend/src/keystore/](../../backend/src/keystore/)) for work that must not run concurrently across instances.

## Risky-place checklist (flag these in review)

- Side effect *before* the DB commit → effect fires, transaction rolls back, world and DB disagree. When reviewing, check ordering: are jobs enqueued after the transaction commits? (The create-secret path enqueues after the write — verify the transaction boundary each time; labeled **investigate** per call site.)
- Side effect inside a loop without concurrency limits → self-inflicted DoS on a partner API.
- Enqueue failure unhandled → user saw success, sync never scheduled. What happens here if Redis is down at enqueue time? (**investigate** — good exercise, trace `queueService.queue` error path in [queue/queue-service.ts](../../backend/src/queue/queue-service.ts).)
- Missing the outbox pattern: this repo does *not* use a transactional outbox (job enqueue is a separate Redis write, not part of the DB transaction) — meaning "DB committed but job lost" is possible in a crash window. Small blast radius here because syncs also run on schedules/retries, but know the term: **outbox** = write the "event to publish" into the DB in the same transaction, publish from a relay. This is a favorite senior interview topic; this repo is your concrete example of the tradeoff of *not* having one.

## Fake-code contrast

```ts
// Illustrative fake code: not from this repo.
// BAD: side effect in-request, unreliable, slow, unordered with the tx
await db.transaction(async (tx) => {
  await secretDAL.create(data, tx);
  await fetch(webhookUrl, { method: "POST", body: ... }); // partner outage = user's save fails
});

// BETTER (this repo's shape): commit, then enqueue retryable work
await db.transaction(async (tx) => { await secretDAL.create(data, tx); });
await queue.enqueue("SecretWebhook", { projectId, env, path }, { attempts: 5, backoff: exp });
```

## Drills

1. Trace one secret update through every queue it fans into; draw the tree of jobs with their retry configs.
2. Open [webhook-fns.ts:38-64](../../backend/src/services/webhook/webhook-fns.ts) and answer: what timeout, what counts as failure, what's recorded on failure?
3. Design (paper) the outbox version of `syncSecrets`: which table, which columns, what the relay does, what new failure modes appear (relay lag, poison messages).

Self-grade — Basic: drew the fan-out. Solid: correct retry/idempotency story incl. `jobId` semantics. Strong: articulated the missing-outbox tradeoff and its crash window unprompted.

Interview angle: "How would you make X reliable?" — the answer template is exactly this page: durable state first, queue with retries/backoff, idempotent handlers, dedupe keys, visibility on failure, outbox if you need atomicity. Cross-linked in [08-interview-prep/04](../08-interview-prep/04-system-design-from-this-repo.md).
