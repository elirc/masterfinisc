# File Reading Order

28 files. For each: why it matters, what to look for, what to ignore. Read with the file open — this list is useless as prose.

## Junior path (files 1–12): understand one vertical slice

| # | File | Why / look for | Ignore |
| --- | --- | --- | --- |
| 1 | [CLAUDE.md](../../CLAUDE.md) | Maintainer-written map; deprecated auth modes; `ee/` rule | Deployment sections |
| 2 | [backend/CLAUDE.md](../../backend/CLAUDE.md) | Factory DI, DAL pattern, route pattern, test layout | — |
| 3 | [frontend/CLAUDE.md](../../frontend/CLAUDE.md) | Router DSL, query-key factories, React Query defaults, v2 vs v3 components | — |
| 4 | [backend/src/server/routes/v4/secret-router.ts](../../backend/src/server/routes/v4/secret-router.ts) L47–170 | The canonical route shape: rateLimit, Zod schema, `operationId`, `verifyAuth`, handler calling `server.services.*` | The other 1,300 lines — same shape repeated |
| 5 | [backend/src/server/plugins/auth/verify-auth.ts](../../backend/src/server/plugins/auth/verify-auth.ts) (all 32 lines) | Allowed-auth-modes gate; the `requireOrg` option | — |
| 6 | [backend/src/server/plugins/auth/inject-permission.ts](../../backend/src/server/plugins/auth/inject-permission.ts) (all 79 lines) | How `req.permission` gets its actor type/id/orgId per actor | — |
| 7 | [backend/src/services/secret/secret-service.ts](../../backend/src/services/secret/secret-service.ts) L109–162 | Factory deps narrowed with `Pick` = explicit contracts | The 3,400 lines of methods, for now |
| 8 | [backend/src/lib/knex/index.ts](../../backend/src/lib/knex/index.ts) L156–326 | `ormify()`: every CRUD method; reads → `db.replicaNode()`, writes → `db`; `tx` threading | Type gymnastics above L156 |
| 9 | [backend/src/services/secret/secret-dal.ts](../../backend/src/services/secret/secret-dal.ts) L11–45 | Overriding `update` to `.increment("version", 1)` — an invariant enforced at the data layer | — |
| 10 | [frontend/src/config/request.ts](../../frontend/src/config/request.ts) (all 132 lines) | Interceptors: token injection, 401→refresh with deduped promise, redirect | — |
| 11 | [frontend/src/hooks/api/secrets/queries.tsx](../../frontend/src/hooks/api/secrets/queries.tsx) L33–58, L139–170 | Query-key factory; `useGetProjectSecrets` with `select` transform | — |
| 12 | [frontend/src/hooks/api/secrets/mutations.tsx](../../frontend/src/hooks/api/secrets/mutations.tsx) L25–90 | Mutation + 9 invalidations — cache consistency by hand | Repeats for update/delete |

## Mid path (files 13–21): cross-layer safety

| # | File | Why / look for |
| --- | --- | --- |
| 13 | [backend/src/server/plugins/auth/inject-identity.ts](../../backend/src/server/plugins/auth/inject-identity.ts) L93–155, L218 | `extractAuth`: header sniffing (`x-api-key` first, then Bearer + `authTokenType` switch) → `AuthMode` |
| 14 | [backend/src/ee/services/permission/permission-service.ts](../../backend/src/ee/services/permission/permission-service.ts) L405–470 | `getProjectPermission`: org context required; service tokens branch separately; assumed-privilege context |
| 15 | [backend/src/ee/services/permission/project-permission.ts](../../backend/src/ee/services/permission/project-permission.ts) L15–60, L323+ | The CASL action/subject vocabulary (`ProjectPermissionSecretActions` at L45, `ProjectPermissionSub` at L323) |
| 16 | [backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) L300–360 | createSecret: folder lookup → duplicate check → tag validation → CASL `throwUnlessCan` with attribute-level subject |
| 17 | [backend/src/services/secret/secret-queue.ts](../../backend/src/services/secret/secret-queue.ts) L594–660 | `syncSecrets`: queueing with `jobId` dedupe, `attempts: 5`, exponential `backoff`, `removeOnComplete` |
| 18 | [backend/src/services/webhook/webhook-fns.ts](../../backend/src/services/webhook/webhook-fns.ts) L22–110, L285+ | Webhook trigger path; payload shapes; where decryption happens |
| 19 | [backend/src/lib/validator/validate-url.ts](../../backend/src/lib/validator/validate-url.ts) L13+ | `blockLocalAndPrivateIpAddresses` — SSRF defense for user-supplied URLs |
| 20 | [backend/e2e-test/routes/v1/org.spec.ts](../../backend/e2e-test/routes/v1/org.spec.ts) + [testUtils/secrets.ts](../../backend/e2e-test/testUtils/secrets.ts) | e2e style: `testServer.inject()`, injected `jwtAuthToken`, CRUD helpers |
| 21 | [frontend/src/routes.ts](../../frontend/src/routes.ts) L1–60 | Virtual route DSL; `middleware()` wrapper; layout nesting |

## Senior path (files 22–28): where risk concentrates

| # | File | Why / look for |
| --- | --- | --- |
| 22 | [backend/src/server/routes/index.ts](../../backend/src/server/routes/index.ts) L538+, L3291, L3572–3591 | The whole DI graph; `decorate("services")`; EE-before-community registration order |
| 23 | [backend/src/db/migrations/](../../backend/src/db/migrations/) (skim newest 5 of 423) | Migration style: additive, index-adding, backfills as separate migrations |
| 24 | [backend/src/queue/queue-service.ts](../../backend/src/queue/queue-service.ts) | The BullMQ wrapper all `*-queue.ts` files use |
| 25 | [frontend/src/hooks/api/reactQuery.tsx](../../frontend/src/hooks/api/reactQuery.tsx) L220–226 | Global defaults: `staleTime: 60_000`, `refetchOnWindowFocus: false`, `retry: 1` — and why some queries override to `staleTime: 0` |
| 26 | [frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx) (3,759 lines — skim L290–600) | A giant real page: permission hook at L300, data hook at L567; ask "how would I split this?" |
| 27 | [backend/src/services/auth/auth-login-service.ts](../../backend/src/services/auth/auth-login-service.ts) (skim) | Login/MFA/session issuance — read for structure, not detail |
| 28 | [Makefile](../../Makefile) + both `.npmrc` files | The review gate (`reviewable`), the supply-chain guard (`min-release-age=7`) |

## How to read (transferable technique)

For every file, answer in writing: (1) who calls this, (2) what does it own, (3) what must it never do (e.g., a DAL must never check permissions; a router must never contain business logic), (4) what breaks if it lies. Question 3 is the layer contract — being able to state it is the difference between "I read the code" and "I understand the architecture," and it is precisely what code-walkthrough interview rounds probe.
