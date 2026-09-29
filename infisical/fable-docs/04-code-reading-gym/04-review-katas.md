# Review Katas

Eight fake PRs. For each: read the summary, write your review (findings graded **Blocking / Important / Optional**), then compare with the expected findings. All diffs are invented; the "Files this resembles" anchor shows the real pattern being violated or followed. Practice *kind, specific* language — findings phrased as questions where uncertainty exists, always with a reason and preferably a suggestion.

---

## Kata 1: "Add endpoint to fetch secret by ID for the mobile app"

Author intent: quick read endpoint for a new client.
Fake diff summary: new route `GET /api/v4/secrets/mobile/:secretId` with `verifyAuth([AuthMode.JWT])`; handler calls `secretDAL.findById(secretId)` directly and returns the row.
Files this resembles: [secret-router.ts:252-274](../../backend/src/server/routes/v4/secret-router.ts)
Your task: review it.
Expected findings — **Blocking**: DAL called from the route (layer violation) and, worse, no project-permission check → IDOR: any authenticated user reads any secret by id. Also returns the raw row (encrypted blobs/internal columns) — response schema missing, so it becomes accidental public contract. **Important**: no rate-limit config; duplicate of the existing `/id/:secretId` route — why a new one? **Optional**: naming (`/mobile/` in a version-scoped API smells like client-specific coupling).
Good review comment example: > This handler skips `getProjectPermission` — as written any logged-in user can fetch any secret id across orgs. Can we route this through `secretV2BridgeService.getSecretById` like `GET /id/:secretId` does, so CASL and response shaping come for free?

## Kata 2: "Speed up bulk secret import"

Author intent: importing 5k secrets is slow.
Fake diff summary: replaces a serial loop with `Promise.all(items.map(i => dal.create(i)))` — *outside* any transaction — and bumps the request timeout.
Files this resembles: [secret-dal.ts:23-45](../../backend/src/services/secret/secret-dal.ts) (parallel writes *inside* a tx), `insertMany`/`batchInsert` in [lib/knex/index.ts:221-243](../../backend/src/lib/knex/index.ts)
Expected findings — **Blocking**: partial-failure state — item 3,001 fails, 3,000 rows are committed, no rollback, no report of which failed. Use `insertMany`/`batchInsert` inside a transaction. **Important**: unbounded parallelism can exhaust the pool (pool size vs 5k concurrent inserts); duplicate-key behavior unspecified. **Optional**: request-timeout bump treats symptom; consider queueing the import as a job with progress.

## Kata 3: "Fix flaky sync by increasing retries"

Author intent: integration syncs sometimes fail.
Fake diff summary: `attempts: 5` → `attempts: 20` on IntegrationSync; removes the failed-sync email job "since it retries more now."
Files this resembles: [secret-queue.ts:568-577, 652-656](../../backend/src/services/secret/secret-queue.ts)
Expected findings — **Blocking**: removing the escalation email deletes the only human-visibility channel — permanent failures (revoked creds, 403s) now rot silently. **Important**: 20 exponential attempts = hours of retry for a deterministic failure; better: classify errors (retry 5xx/network, fail-fast 4xx). **Optional**: no metric/log added to learn *why* syncs flake.

## Kata 4: "Show secret count badge in sidebar"

Author intent: nice UX addition.
Fake diff summary: new `useEffect` in the layout that `axios.get("/api/v4/secrets?projectId=...")` on every route change, stores `count` in `useState`, no cleanup.
Files this resembles: the API-hook discipline of [hooks/api/secrets/queries.tsx](../../frontend/src/hooks/api/secrets/queries.tsx)
Expected findings — **Blocking**: bypasses the API layer (raw axios in a component — no auth-refresh interplay issues here since shared instance, but no caching/dedupe, no query key, unabortable race on fast navigation writing stale counts). **Important**: fetches the full secret list to show a count — needs a count endpoint or reuse of an existing cached query; new derived view must be added to mutation invalidations or the badge goes stale ([mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx)). **Optional**: permission gate — sidebar may render for users who can't read secrets.

## Kata 5: "Add `notes` column to secrets"

Author intent: users want freeform notes.
Fake diff summary: migration `alterTable("secrets", t => t.string("notes").notNullable().defaultTo(""))`; no `down()`; schema types edited by hand in `db/schemas/`.
Files this resembles: [20260513182201...](../../backend/src/db/migrations/20260513182201_add-folder-id-indexes-for-snapshot-prune.ts); generated schemas policy in [backend/CLAUDE.md](../../backend/CLAUDE.md)
Expected findings — **Blocking**: hand-edited generated schemas (next `generate:schema` reverts them); on Postgres <11-style concerns aside, `NOT NULL DEFAULT` on a huge hot table needs a lock story — verify Postgres version behavior and table size; missing `down()`. **Important**: is `notes` sensitive? Every other secret field is encrypted — plaintext notes on a secrets table is a product/security question, not a nit. **Optional**: string vs text length limit.

## Kata 6: "Refactor: extract webhook URL validation"

Author intent: cleanup, move `blockLocalAndPrivateIpAddresses` call from create-time into a shared helper called... only at create.
Fake diff summary: pure move + rename; tests updated; behavior identical.
Files this resembles: [webhook-service.ts](../../backend/src/services/webhook/webhook-service.ts), [validate-url.ts:13, 171](../../backend/src/lib/validator/validate-url.ts)
Expected findings — **Important**: the refactor is fine; the *review opportunity* is asking whether send-time revalidation exists (DNS rebinding: URL passes at create, resolves privately later). A pure-move PR is the right moment to confirm the invariant's coverage, not expand scope. **Optional**: naming, docstring. **Blocking**: none — approve with the question. (Kata lesson: not every review needs blood; knowing when to approve is a skill.)

## Kata 7: "Make error messages friendlier"

Author intent: copy polish.
Fake diff summary: rewrites backend auth error strings, including `"token expired"` → `"Your session timed out"`.
Files this resembles: [request.ts:54-57](../../frontend/src/config/request.ts) (`isTokenExpiredError` matches message text)
Expected findings — **Blocking**: the frontend interceptor string-matches `"token expired"` — this copy change logs users out instead of refreshing (silent, cross-repo contract). Requires either keeping the substring, or (better) migrating to an error code first. **Important**: audit for other message-matching consumers (CLI? SDKs?). **Optional**: centralize user-facing copy.
Kata lesson: greppability of implicit contracts — before changing any string, search for who consumes it.

## Kata 8: "Add admin bypass for approval policies"

Author intent: admins are blocked by their own approval flows in emergencies.
Fake diff summary: in the approval check, `if (membership.role === "admin") return { allowed: true }` before policy evaluation.
Files this resembles: approval deps in [secret-service.ts:130-135](../../backend/src/services/secret/secret-service.ts); ABAC philosophy in [project-permission.ts](../../backend/src/ee/services/permission/project-permission.ts)
Expected findings — **Blocking**: hardcoded role-name check bypasses the entire permission system's vocabulary (custom roles named differently get nothing; renamed role = silent privilege change); no audit trail for the bypass — in a *secrets product*, an unaudited emergency bypass is a compliance incident. **Important**: the legitimate need is real — propose "break-glass" as an explicit, audited, time-boxed privilege (the repo already has assumed-privilege machinery: [inject-assume-privilege.ts](../../backend/src/server/plugins/auth/inject-assume-privilege.ts)). **Optional**: product question — should the *policy* have an emergency path instead?

---

## Grading yourself

Count your findings against expected: **Weak** — caught style issues but missed a Blocking. **Solid** — all Blockings, most Importants, phrased with reasons. **Strong** — all of that, plus at least once you (a) approved something imperfect on purpose, and (b) turned a finding into a question that invites the author's context. Review-round interviews ([08-interview-prep/05](../08-interview-prep/05-debugging-and-code-review-rounds.md)) grade exactly this: severity triage + communication tone.
