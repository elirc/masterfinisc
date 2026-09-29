# Mid-Level Feature Tickets (10)

Cross-layer work: schema and/or API and/or UI and/or tests. **Rule: write a half-page design note (approach, alternatives, risk, rollback) before any code** — reviewing your own design against the outcome is where the mid-level growth happens. Format: Story · Layers · Anchors · Design questions you must answer · Risk & rollback · Interview story potential.

## M1: Error codes for auth failures (API + client)
Story: As a client developer, I want machine-readable `errorCode` on auth errors so clients stop matching message strings.
Layers: backend error types → 401 bodies → frontend interceptor.
Anchors: [request.ts:54-57](../../frontend/src/config/request.ts), [lib/errors](../../backend/src/lib/errors/), [lib/error-codes](../../backend/src/lib/error-codes/) (check what already exists — this may be partially built!).
Design questions: additive contract change strategy? transition period matching both code and message? which errors first?
Risk & rollback: additive field = trivially reversible; client keeps legacy matching as fallback during transition.
Interview story potential: "Migrated an implicit string contract to typed error codes across a client/server boundary."

## M2: Count endpoint for secrets (API + UI)
Story: As a UI developer, I want `GET .../secrets/count` so badges don't fetch full secret lists.
Layers: route (v4) + service method (with CASL filtering!) + DAL count + frontend hook.
Anchors: `countDocuments`/count support in [lib/knex/index.ts:177-190](../../backend/src/lib/knex/index.ts); route shape [secret-router.ts:48+](../../backend/src/server/routes/v4/secret-router.ts); Kata 4 motivation.
Design questions: does count respect permission filtering (it must — a count can leak existence)? cache key + invalidation additions?
Risk & rollback: new endpoint, zero existing consumers; remove cleanly if rejected.
Interview story potential: designing an endpoint where *authorization applies to aggregates*.

## M3: Send-time SSRF revalidation for webhooks (security hardening)
Story: As a security engineer, I want webhook URLs re-validated at send time so DNS rebinding can't bypass create-time checks.
Layers: webhook-fns + tests.
Anchors: [validate-url.ts:13, 171](../../backend/src/lib/validator/validate-url.ts), [webhook-fns.ts:38-64](../../backend/src/services/webhook/webhook-fns.ts). First verify current behavior — it may already exist; the ticket then becomes "add the test proving it."
Design questions: performance cost of DNS resolution per send? failure semantics (skip vs retry)?
Risk & rollback: guard behind config flag if latency-sensitive.
Interview story potential: textbook SSRF-defense-in-depth story.

## M4: Pagination for a list endpoint that lacks it (API + UI)
Story: As a user with thousands of items, I want a paginated list instead of an unbounded query.
Layers: find a v1/v2 list endpoint without limit/offset (audit first — that audit is deliverable #1), add limit/offset/cursor per existing conventions, thread through UI.
Anchors: `TFindOpt` limit/offset/sort in [lib/knex/index.ts:177-196](../../backend/src/lib/knex/index.ts).
Design questions: offset vs cursor (justify by access pattern); default+max page size; response envelope with total (`count: true` window trick)?
Risk & rollback: additive params defaulting to old behavior.
Interview story potential: THE pagination interview answer, with a shipped example.

## M5: Audit event for a mutation missing one (compliance)
Story: As a compliance officer, I want every secret-adjacent mutation audited.
Layers: audit — find one mutating route without an audit event (audit-log types enumerate events), wire it per the pattern of a sibling.
Anchors: [ee/services/audit-log/](../../backend/src/ee/services/audit-log/), `injectAuditLogInfo` ([routes/index.ts:3504](../../backend/src/server/routes/index.ts)).
Design questions: event naming consistency; what metadata is safe to record (no secret values!).
Risk & rollback: additive; feature-flag not needed.
Interview story potential: "Extended an audit pipeline — and can explain why audit writes are queued."

## M6: Frontend test harness + first three hook tests
Story: As a frontend maintainer, I want a vitest+RTL setup with tests for `secretKeys` factory behavior, one query hook, one mutation's invalidation set.
Layers: tooling + tests. This is M-level because *introducing tooling* needs design buy-in (do it as an RFC-lite issue first — see [07/02](../07-career-and-collaboration/02-writing-prs-and-rfcs.md)).
Anchors: [queries.tsx](../../frontend/src/hooks/api/secrets/queries.tsx), [mutations.tsx](../../frontend/src/hooks/api/secrets/mutations.tsx).
Design questions: msw vs axios-mock; where test files live; CI wiring.
Risk & rollback: dev-only.
Interview story potential: "Introduced a testing culture beachhead" — leadership-flavored.

## M7: Split OverviewPage — first slice (UI refactor)
Story: As a frontend contributor, I want the overview toolbar extracted from the 3,759-line page with zero behavior change.
Layers: UI only, mechanical.
Anchors: [OverviewPage.tsx](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx); local `components/` convention in sibling pages.
Design questions: prop surface vs context for the extracted piece; how to *prove* no behavior change (visual diff, DOM snapshot).
Risk & rollback: single revertable commit; no logic edits allowed in the same PR (that's the discipline being trained).
Interview story potential: "Refactored a giant component safely" — pairs with the render-perf question.

## M8: Reminder/TTL surfacing (full-stack, product-flavored)
Story: As a user, I want to see which secrets have reminders configured in the list view.
Layers: check API response fields for reminder data (reminderService dep at [secret-service.ts:141](../../backend/src/services/secret/secret-service.ts)) → surface a column/badge → tests.
Design questions: is the data already in the list response or does it need a join? cost of widening the list payload?
Risk & rollback: UI-only if data exists; otherwise scope up consciously (and note that scoping decision — it's the lesson).
Interview story potential: feature work requiring payload-cost judgment.

## M9: Idempotency audit of one queue consumer (reliability)
Story: As an operator, I want documented proof that the SecretSync consumer tolerates duplicate delivery.
Layers: analysis + tests (+ fix if a non-idempotent step is found).
Anchors: [secret-queue.ts:660+](../../backend/src/services/secret/secret-queue.ts).
Design questions: what's the idempotency key of each step? which steps are convergent (sync-to-state) vs additive (emails)?
Risk & rollback: analysis-first; any fix follows its own mini-design.
Interview story potential: "Audited at-least-once semantics in a production queue" — senior-signal vocabulary throughout.

## M10: Contract test for webhook payload shape
Story: As an integration consumer, I want the webhook payload shape pinned so refactors can't break receivers.
Layers: types + tests.
Anchors: [webhook-fns.ts:65+](../../backend/src/services/webhook/webhook-fns.ts), webhook-types.
Design questions: snapshot vs schema assertion (schema — snapshots rot); where does the "public contract" doc live?
Risk & rollback: tests only.
Interview story potential: "Treated an event payload as a public API" — API-versioning discussion fuel.

---

Completion bar for M-tickets: design note written *before* coding and revisited after; `reviewable-*` clean; tests cover the negative path; PR description includes risk + rollback. If your design note's chosen approach survived implementation unchanged, either you designed well or you didn't look hard — the retro sentence saying which is required.
