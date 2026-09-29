# Senior Build Projects (5)

Two days to four weeks each. Full planning discipline required: problem, value, design checklist, architecture decisions, likely files, migration/test/security/performance plans, rollout/rollback, open questions, stretch goals. These are *plausible* directions for a secrets platform — check upstream before assuming novelty.

## P1: Transactional outbox for queue enqueue (1–2 weeks)

Problem: job enqueue is a Redis write outside the DB transaction — a crash between commit and enqueue loses sync work ([03/04](../03-architecture-and-patterns/04-side-effects-async-and-reliability.md)).
Product value: no silently-stale downstream integrations after infra hiccups.
Architecture decisions: outbox table (id, jobName, payload, createdAt, processedAt) written *in* the business tx; relay = polling loop vs LISTEN/NOTIFY; exactly-once illusion via idempotent consumers (keep BullMQ as executor).
Likely files: new migration + schema; [queue-service.ts](../../backend/src/queue/queue-service.ts) wrapper for `enqueueViaOutbox(tx, ...)`; opt-in at [secret-queue.ts:594+](../../backend/src/services/secret/secret-queue.ts) producers.
Migration plan: additive table; dual-write phase (direct + outbox with dedupe by jobId) before cutover.
Test plan: kill-between-commit-and-enqueue simulation (e2e with induced failure); relay crash/restart; poison-payload handling.
Security plan: payloads carry ids only (existing discipline); outbox rows subject to retention policy.
Performance plan: relay batch size and poll interval measured; index on `processedAt IS NULL`.
Rollout/rollback: flag per producer; rollback = flip flag, table remains (harmless).
Open questions: is loss frequency actually worth this? (Instrument first — a counter of enqueue failures. If ~0, write the ADR saying "not now" — that's a senior deliverable too.)
Stretch: generalize to all producers.
Interview story potential: complete outbox narrative — problem, alternative (accept risk), instrumentation-before-building.

## P2: Retire a deprecated auth mode path (2–4 weeks, mostly analysis)

Problem: `API_KEY`/`SERVICE_TOKEN` remain live attack/maintenance surface ([inject-identity.ts:94+](../../backend/src/server/plugins/auth/inject-identity.ts), [CLAUDE.md](../../CLAUDE.md)).
Product value: smaller security surface; simpler auth code.
Architecture decisions: telemetry first (usage counters per mode per route); deprecation timeline; hard-off behind config before deletion.
Likely files: inject-identity, verify-auth mode lists across all routers (grep `SERVICE_TOKEN`), docs.
Migration plan for users: publish migration guide to identity tokens; warn headers on deprecated-mode responses.
Test plan: e2e for the "mode disabled" config; ensure no route lists *only* deprecated modes.
Security plan: this *is* the security plan.
Rollout/rollback: config flag default-on (allowed) → default-off → code removal releases later.
Open questions: self-hosted long-tail usage — how long is the tail?
Interview story potential: "Sunset a credential type without breaking users" — rare, memorable, very senior.

## P3: Real-time secret updates via server-sent events (2–3 weeks)

Problem: two users editing the same folder see each other's changes only after staleTime/refetch ([reactQuery.tsx:222-224](../../frontend/src/hooks/api/reactQuery.tsx)).
Product value: collaborative freshness; fewer refetch storms (targeted invalidation instead of nine families).
Architecture decisions: SSE vs WebSocket (SSE likely sufficient: server→client only); event = invalidation *hint* (project/env/path), client invalidates matching keys — never push secret values over the channel; fan-out via Redis pub/sub (multi-instance).
Likely files: new backend route + Redis subscriber; frontend: one hook subscribing and calling `queryClient.invalidateQueries` by key prefix; producers publish where queues already fan out ([secret-queue.ts:594+](../../backend/src/services/secret/secret-queue.ts)).
Migration plan: none (additive).
Test plan: two-client e2e; reconnect/backoff behavior; auth on the SSE endpoint (same verifyAuth chain).
Security plan: channel scoping per project permission — a user must not receive hints for paths they can't read (existence leak!); this is the hard part, design it first.
Performance plan: connection counts per instance; heartbeat interval.
Rollout/rollback: feature-flagged; degrade to polling.
Stretch: presence indicators.
Interview story potential: real-time system design with the least-privilege twist most candidates miss.

## P4: Permission explain tool (1–2 weeks)

Problem: "why can't user X read /prod/db?" requires a human to mentally evaluate CASL rules ([permission-service.ts:405+](../../backend/src/ee/services/permission/permission-service.ts)).
Product value: support-ticket killer; admin trust.
Architecture decisions: read-only endpoint `POST /permissions/explain {actor, action, subjectAttrs}` returning matched/blocking rules; reuse the actual ability builder (no reimplementation — the whole point is fidelity); admin-gated.
Likely files: new EE route + service using [permission-service](../../backend/src/ee/services/permission/permission-service.ts) internals; UI panel in access-management pages.
Test plan: table-driven cases mirroring [lib/casl](../../backend/src/lib/casl/) glob tests; explain-vs-enforce consistency test (explain says yes ⟺ enforcement allows).
Security plan: the explainer itself is privileged (it reveals policy); audit its use.
Performance plan: trivial (single evaluation).
Rollout/rollback: additive endpoint.
Interview story potential: "Built introspection for an ABAC engine" — outstanding authz depth signal.

## P5: Load-test rig + performance baseline for the secrets read path (2 days–1 week)

Problem: performance claims in this curriculum (and any future optimization PR) are hypotheses without a rig.
Product value: regression gate; data for capacity planning.
Architecture decisions: k6 (or autocannon) scripts against dev compose; seeded project sizes S/M/L (100/1k/10k secrets); scenarios: list, create burst (queue fan-out!), auth-heavy mix.
Likely files: new `load/` directory; seed scripts extending [db/seed-data](../../backend/src/db/seed-data.ts); docs.
Test plan: the rig is the test; validate determinism across two runs.
Security plan: rig runs only against local/dev; no real credentials.
Performance plan: capture p50/p95/p99 + DB query counts; publish baseline table.
Rollout/rollback: dev tooling only.
Stretch: CI job with regression thresholds on the S profile.
Interview story potential: "Established a performance baseline before optimizing" — measure-first with receipts; feeds every performance interview question.

---

Self-grade any project — **Solid**: shipped per plan with tests. **Strong**: at least one architecture decision was *reversed* by evidence mid-project and documented; the rollback path was actually rehearsed once. (Seniority is visible in the decision log, not the diff.)
