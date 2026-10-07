# Verification Log

Authoring session: **2026-07-09**, against the working copy of the `infisical/` app directory (no git history available at the time to date the snapshot; upstream is github.com/infisical/infisical).

> **Status note (2026-10-06, frozen record).** The log is kept as written. A static re-check on 2026-10-06 against the repository snapshot (sparse checkout; nothing installed, built or run) found the tree unchanged since authoring — the newest migration is still `20260513182201_add-folder-id-indexes-for-snapshot-prune.ts` — and every relative link under `fable-docs/` resolves. Sampled anchors still hold: v4 secret-router `operationId` L56 and `verifyAuth` L168; `extractAuth` L93, `x-api-key` L94, `authTokenType` switch L112, plugin L155 and `AUTH_SECRET` use L218 in `inject-identity.ts`; `services` decorate L3291 and `/api/status` route L3507 in the 3,606-line `server/routes/index.ts`; `getOrgPermission` L170, `getProjectPermission` L405, `getProjectPermissions` L577; file sizes for `verify-auth.ts` (32), `inject-permission.ts` (79) and `config/request.ts` (132). One count was off: `backend/src/db/migrations/` holds **423** migrations plus a `utils/` folder (the "424" below was a directory listing that counted `utils/`); it was corrected across the curriculum. "272 schema files" is right, but two of them are `index.ts` and `models.ts`, so it is not a table count. The 27 backend unit-test files still hold. All inspection was **read-only**: `ls`, `grep -n`, `sed -n`, `wc -l`, `find`, `cat`. **No build, test, lint, or server commands were executed** — every command in the docs is marked *inferred* accordingly.

## Files read in full or in cited ranges (anchors re-checked at write time)

Backend: `CLAUDE.md` (root + backend + frontend); `server/routes/v4/secret-router.ts` (L40–120 + landmark grep: routes at 49/252/290/405/564/734/844/902, verifyAuth at 168/274/329/462/626/773/869, operationId L56); `server/plugins/auth/verify-auth.ts` (all 32 lines); `inject-permission.ts` (all 79); `inject-identity.ts` (landmarks: extractAuth 93, x-api-key 94, authTokenType switch 112, plugin 155, decorateRequest 157-158, AUTH_SECRET use 218); `services/secret/secret-service.ts` (dep type L109–147, factory 149; file 3,644 lines); `lib/knex/index.ts` (ormify 156–326; replicaNode 168/184/205); `services/secret/secret-dal.ts` (L1–60: update override 14–21, bulkUpdate 23–45); `services/secret-v2-bridge/secret-v2-bridge-service.ts` (L300–360; throwUnlessCan grep: 339, 560, 580, 599, 846, 1990; file 4,057 lines); `services/secret/secret-queue.ts` (landmarks 568–675; file 1,627 lines); `services/webhook/webhook-service.ts` (L1–60) + `webhook-fns.ts` exports (22/38/65/285/320); `lib/validator/validate-url.ts` (13, 171) and `validator/index.ts:13`; `ee/services/permission/permission-service.ts` (getOrgPermission 170, getProjectPermission 405–430, getProjectPermissions 577; file 829 lines); `ee/services/permission/project-permission.ts` (enums at 15/45/323; file 2,238 lines); `server/routes/index.ts` (3,606 lines; first DAL 538, last ~2997, decorate services 3291, plugin chain 3500–3504, /api/status 3507, route registration 3572–3591); `db/schemas/models.ts` (SecretType 363–366); migration `20260513182201_add-folder-id-indexes-for-snapshot-prune.ts` (full); `e2e-test/vitest-environment-knex.ts` (L1–60); `e2e-test/testUtils/secrets.ts` (L1–60; exports 10/43/68/95); `e2e-test/routes/` listings (v1/v2/v3/v4); `ee/services/audit-log/` listing; `Makefile` (L1–40); both `.npmrc` files; root `package.json`.

Frontend: `config/request.ts` (all 132); `hooks/api/secrets/queries.tsx` (secretKeys 33–58, useGetProjectSecrets 139–170, AllEnv 173–215; file 381 lines); `hooks/api/secrets/mutations.tsx` (useCreateSecretV3 25–90; file 628 lines); `hooks/api/reactQuery.tsx` (defaults 222–224); `routes.ts` (L1–40); `hoc/` and `context/` listings; `pages/secret-manager/` listing; OverviewPage hook usage (useProjectPermission L300, useGetProjectSecretsOverview L567; 3,759 lines); SecretDashboardPage 1,243 lines.

## Counts (verified)

424 migration files · 272 schema files · 27 backend unit tests (`find src -name "*.test.ts"`) · e2e spec listings as documented · `min-release-age=7` in both `.npmrc`s.

## Uncertainties / not covered (labeled "investigate" or "inferred" in the docs)

- Whether a DB unique constraint backs the duplicate-shared-secret check (R1) — migrations not exhaustively searched.
- Transaction-vs-enqueue ordering at each producer call site (R2) — structural read only.
- `triggerWebhookRequest` timeout value and send-time SSRF revalidation coverage (R7) — function located, body not read.
- Backoff jitter presence; BullMQ completed-jobId reuse semantics — asserted from options read, not tested.
- Permission/ability caching behavior; frontend test tooling absence (R11) — absence-of-evidence claims, re-verify before repeating to maintainers.
- All npm/make commands — never executed here.
- Areas not covered at all: KMS/crypto internals, SCIM/SSO flows, cert-manager/ssh/pam/ai products, WASM crates, CLI (`sink/`?), helm charts, CI workflow contents, `docs2/`, `upgrade-impact/`.

## Method note

Every `file:line` anchor was produced by grep/sed against this working copy immediately before writing, per the ground rules; a handful of ±1 drifts found during authoring were corrected in place (glossary env/approval anchors, operationId 55→56). If the tree changes, prefer symbol search over line numbers.
