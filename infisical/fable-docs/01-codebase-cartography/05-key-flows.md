# Key Flows

Six end-to-end traces, rotated across UI, API, persistence, async, auth, and client-session concerns. Each uses the same template. Do the drill before moving on — reading a trace is not the same as being able to reproduce it.

---

## Flow 1: Create a secret (UI → API → DB → queue fan-out)

Why this flow matters: it is the product's core write path and touches every layer — the single best flow to know cold for interviews.

Open these files first:
- [frontend/src/hooks/api/secrets/mutations.tsx:25-90](../../frontend/src/hooks/api/secrets/mutations.tsx) — the mutation and its invalidations
- [backend/src/server/routes/v4/secret-router.ts:405-462](../../backend/src/server/routes/v4/secret-router.ts) — `POST /:secretName`
- [backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts:300-360](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) — createSecret validation + authz

Trace:

| Step | Owner | File | What happens | Data shape | Risk |
| --- | --- | --- | --- | --- | --- |
| 1 | UI form | SecretDashboard/Overview pages | User submits key+value | react-hook-form values | Client validation is UX only — never trust it |
| 2 | React Query | [mutations.tsx:32-55](../../frontend/src/hooks/api/secrets/mutations.tsx) | `POST /api/v4/secrets/:secretKey` with `encodeURIComponent` | `TCreateSecretsV3DTO` | Forgetting to URL-encode keys with `/` |
| 3 | Axios | [request.ts:22-44](../../frontend/src/config/request.ts) | Injects `Authorization: Bearer <JWT>` | header | Token precedence: MFA temp > auth > signup temp |
| 4 | Fastify plugin | [inject-identity.ts:93-155](../../backend/src/server/plugins/auth/inject-identity.ts) | `extractAuth` sniffs headers, decodes JWT, sets `req.auth` | `{ authMode, actor, userId, orgId }` | Wrong mode detection = wrong permission path |
| 5 | Fastify plugin | [inject-permission.ts:12-23](../../backend/src/server/plugins/auth/inject-permission.ts) | Sets `req.permission` from actor | `{ type, id, orgId }` | — |
| 6 | Route | [secret-router.ts:405-462](../../backend/src/server/routes/v4/secret-router.ts) | Zod-parses body; `verifyAuth([JWT, SERVICE_TOKEN, IDENTITY_ACCESS_TOKEN])` | Zod-validated DTO | Schema is also the public OpenAPI contract |
| 7 | Service | [secret-v2-bridge-service.ts:304-336](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) | Folder must exist; duplicate shared secret rejected; personal must shadow shared; tags validated | folder id + input DTO | Checks read via DAL — TOCTOU window between check and insert (investigate) |
| 8 | Service | [secret-v2-bridge-service.ts:339-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) | CASL `throwUnlessCan(Create, subject(Secrets, {environment, secretPath, secretName, secretTags}))` | ability + subject attrs | Authorization is attribute-level, not just role-level |
| 9 | DAL | [secret-dal.ts](../../backend/src/services/secret/secret-dal.ts) / v2-bridge DAL | Insert row (encrypted value); version starts/increments | table row | Writes go to primary, never replica |
| 10 | Queue | [secret-queue.ts:594-660](../../backend/src/services/secret/secret-queue.ts) | `syncSecrets` enqueues sync/replication/webhook jobs | job payloads | Job runs after commit? verify ordering (investigate) |
| 11 | UI | [mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx) | Invalidates 9 query-key families | — | Miss one key → stale UI |

Validation and authorization: Zod at the route (step 6), business rules in the service (step 7), CASL at step 8 — three distinct layers with different jobs.
Persistence and side effects: DB write (step 9), then queue fan-out (step 10) — external effects are *not* awaited in the request.
Tests that cover it: [e2e-test/routes/v4/secrets.spec.ts](../../backend/e2e-test/routes/v4/secrets.spec.ts), [e2e-test/routes/v3/secrets-v2.spec.ts](../../backend/e2e-test/routes/v3/secrets-v2.spec.ts); helpers in [e2e-test/testUtils/secrets.ts:10-95](../../backend/e2e-test/testUtils/secrets.ts).
What juniors usually miss: that authorization happens *after* cheap validation (fail fast on 404/400 before the expensive permission computation), and that the UI's nine invalidations are manual cache bookkeeping, not magic.
What seniors notice: the duplicate check (step 7) and the insert (step 9) are separate statements — they ask whether a DB unique constraint backs the check, because two concurrent creates can both pass the read. Also: personal-shadows-shared is an invariant enforced only in service code.
Interview angle: "Walk me through what happens when a user submits a form" — this flow is a complete, concrete answer covering client cache, auth, validation layering, and async side effects.
Drill: without the doc, write the 11 steps from memory; then diff against this table.
Self-grade — Basic: got UI→route→service→DB. Solid: included both auth plugins and the queue fan-out. Strong: also named the TOCTOU concern and the three validation layers by responsibility.

---

## Flow 2: List secrets (read path with filters)

Why this flow matters: the canonical read path — replica reads, query-string parsing, and response shaping — and home of the repo's most instructive Zod transform.

Open these files first:
- [backend/src/server/routes/v4/secret-router.ts:48-170](../../backend/src/server/routes/v4/secret-router.ts) — `GET /` with `metadataFilter` transform
- [backend/src/lib/knex/index.ts:177-202](../../backend/src/lib/knex/index.ts) — `find()` with count/limit/offset/sort
- [frontend/src/hooks/api/secrets/queries.tsx:139-170](../../frontend/src/hooks/api/secrets/queries.tsx) — `useGetProjectSecrets`

Trace:

| Step | Owner | File | What happens | Data shape | Risk |
| --- | --- | --- | --- | --- | --- |
| 1 | UI hook | [queries.tsx:160-168](../../frontend/src/hooks/api/secrets/queries.tsx) | Query with key `[{projectId, environment, secretPath, viewSecretValue}, "secrets"]`; `select` merges personal overrides | key tuple | Key must contain *every* param or caches collide |
| 2 | Route | [secret-router.ts:64-96](../../backend/src/server/routes/v4/secret-router.ts) | `metadataFilter` string is `.transform()`ed into `{key,value}[]` and `.superRefine()`d (max 10 filters) | `key=a,value=b\|key=c` → array | Parser is hand-rolled; malformed input must 400, not 500 |
| 3 | Auth | [secret-router.ts:168](../../backend/src/server/routes/v4/secret-router.ts) | `verifyAuth([JWT, SERVICE_TOKEN, IDENTITY_ACCESS_TOKEN])` | — | — |
| 4 | Service | secret-v2-bridge `getSecrets` | Permission-filters results per env/path | — | Filtering must happen server-side, not in UI |
| 5 | DAL | [lib/knex/index.ts:184](../../backend/src/lib/knex/index.ts) | `(tx \|\| db.replicaNode())(tableName)` — read hits replica | rows | Replica lag: read-your-writes not guaranteed |
| 6 | UI | [queries.tsx:168](../../frontend/src/hooks/api/secrets/queries.tsx) | `select: mergePersonalSecrets(data.secrets)` reshapes for display | view model | `select` runs on every consumer render subscription |

Validation and authorization: Zod transform/superRefine at route; CASL filtering in service.
Persistence and side effects: pure read; replica node.
Tests that cover it: [e2e-test/routes/v4/secrets.spec.ts](../../backend/e2e-test/routes/v4/secrets.spec.ts), [e2e-test/routes/v3/secret-recursive.spec.ts](../../backend/e2e-test/routes/v3/secret-recursive.spec.ts).
What juniors usually miss: `staleTime: 60_000` global default ([reactQuery.tsx:222-224](../../frontend/src/hooks/api/reactQuery.tsx)) means a fresh mount may show 59-second-old data by design.
What seniors notice: Zod `.transform()` puts *parsing* in the contract layer, so the handler receives typed data — but a 60-line parser inside a schema is at the edge of what a schema should own; they'd consider extracting it to a tested function (the parser currently has no dedicated unit test — investigate).
Interview angle: "Where would you put input parsing and why?" — parse at the boundary, so everything inside works with typed values ("parse, don't validate").
Drill: feed the metadataFilter grammar three malformed strings on paper (`key=`, `key=a,value=`, 11 filters) and predict each outcome from [secret-router.ts:64-120](../../backend/src/server/routes/v4/secret-router.ts).
Self-grade — Basic: traced hook→route→service. Solid: explained the replica read and staleTime. Strong: critiqued transform-in-schema with the "parse at the boundary" principle and its testing gap.

---

## Flow 3: Who are you, what may you do (authn → authz)

Why this flow matters: every request passes through it; it's the security spine and the best auth interview material in the repo.

Open these files first:
- [inject-identity.ts:93-155](../../backend/src/server/plugins/auth/inject-identity.ts) — `extractAuth`
- [inject-permission.ts:12-79](../../backend/src/server/plugins/auth/inject-permission.ts) — actor → `req.permission`
- [verify-auth.ts:10-32](../../backend/src/server/plugins/auth/verify-auth.ts) — route gate
- [permission-service.ts:405-470](../../backend/src/ee/services/permission/permission-service.ts) — CASL ability construction

Trace:

| Step | Owner | File | What happens | Data shape | Risk |
| --- | --- | --- | --- | --- | --- |
| 1 | Plugin | [inject-identity.ts:94](../../backend/src/server/plugins/auth/inject-identity.ts) | Check `x-api-key` header (deprecated path) | header | Legacy path must not gain new powers |
| 2 | Plugin | [inject-identity.ts:112](../../backend/src/server/plugins/auth/inject-identity.ts) | Else decode Bearer JWT; `switch (decodedToken.authTokenType)` picks AuthMode | JWT claims | Signature verified with `AUTH_SECRET` (line 218) |
| 3 | Plugin | [inject-permission.ts:12-79](../../backend/src/server/plugins/auth/inject-permission.ts) | Map actor (USER/IDENTITY/SERVICE/SCIM/GATEWAY) → `req.permission` | `{type, id, orgId, rootOrgId, parentOrgId}` | orgId wrong ⇒ cross-tenant reads |
| 4 | Route hook | [verify-auth.ts:20-24](../../backend/src/server/plugins/auth/verify-auth.ts) | Reject if route's allowed modes don't include `req.auth.authMode` | — | Route forgetting `verifyAuth` = open endpoint |
| 5 | Route hook | [verify-auth.ts:27-29](../../backend/src/server/plugins/auth/verify-auth.ts) | JWT + `requireOrg` ⇒ must have `req.permission.orgId` | — | v1 auth routes opt out via `requireOrg: false` |
| 6 | Service | [permission-service.ts:405-430](../../backend/src/ee/services/permission/permission-service.ts) | `getProjectPermission`: requires `actorOrgId`; service tokens branch to their own evaluator; assumed-privilege context consulted | CASL ability | Fail-closed: missing org context throws |
| 7 | Service | e.g. [secret-v2-bridge-service.ts:339-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) | `ForbiddenError.from(permission).throwUnlessCan(action, subject(sub, attrs))` | action+subject | Attribute-level: env, path, name, tags all constrain |

Validation and authorization: this *is* the authorization flow; note the split — authn in plugins (framework layer), authz in services (domain layer).
Persistence and side effects: permission construction reads roles/memberships from DB; no writes.
Tests that cover it: [e2e-test/routes/v1/identity.spec.ts](../../backend/e2e-test/routes/v1/identity.spec.ts), [e2e-test/routes/v3/auth-idp-attacks.spec.ts](../../backend/e2e-test/routes/v3/auth-idp-attacks.spec.ts) (adversarial!), login specs in v1/v3.
What juniors usually miss: authn ≠ authz. `verifyAuth` only checks *how you logged in*; whether you can touch `/prod/db` is decided per-call in the service with CASL.
What seniors notice: authorization is enforced in services, not routes — safer (can't forget it when adding a route) but means every service method must receive full actor context; they'd grep for service methods missing `permissionService` calls. Also the fail-closed default at step 6.
Interview angle: "Explain the difference between authentication and authorization, with an example" — you now have a two-file concrete answer; also "how would you do row-level / attribute-level access control" → CASL subject attributes.
Drill: pick any route in [v4/secret-router.ts](../../backend/src/server/routes/v4/secret-router.ts) and write down its full auth story: allowed modes, org requirement, CASL action+subject checked in the service it calls.
Self-grade — Basic: found the modes. Solid: traced to the CASL check with the right action. Strong: articulated why service-layer authz beats route-layer here and what it costs (context threading).

---

## Flow 4: Async fan-out — syncing secrets after a change

Why this flow matters: the repo's flagship background/reliability flow: retries, backoff, deduplication, and at-least-once semantics in real code.

Open these files first:
- [secret-queue.ts:594-648](../../backend/src/services/secret/secret-queue.ts) — `syncSecrets` producer
- [secret-queue.ts:660](../../backend/src/services/secret/secret-queue.ts) — `queueService.start(QueueName.SecretSync, ...)` consumer
- [secret-queue.ts:568-591](../../backend/src/services/secret/secret-queue.ts) — integration-sync and replication producers

Trace:

| Step | Owner | File | What happens | Data shape | Risk |
| --- | --- | --- | --- | --- | --- |
| 1 | Service | after write, e.g. Flow 1 step 10 | `syncSecrets(dto)` called | `{projectId, environmentSlug, secretPath}` | Fire-and-forget: caller doesn't await completion |
| 2 | Producer | [secret-queue.ts:626-648](../../backend/src/services/secret/secret-queue.ts) | Enqueue with `jobId: $getJobKey(projectId, env, path)`, `attempts: 5`, exponential `backoff`, `removeOnComplete: true` | BullMQ job | Deterministic jobId dedupes concurrent bursts |
| 3 | Redis | BullMQ | Job persisted, delivered at-least-once | serialized payload | Redis down ⇒ enqueue fails; is that handled? (investigate) |
| 4 | Consumer | [secret-queue.ts:660+](../../backend/src/services/secret/secret-queue.ts) | Worker processes: resolves affected integrations, pushes to external APIs | — | External API flakiness absorbed by retries |
| 5 | On failure | [secret-queue.ts:652-656](../../backend/src/services/secret/secret-queue.ts) | `SendFailedIntegrationSyncEmails` job — failure made visible to humans | email payload | Silent failure would mean prod running stale secrets |

Validation and authorization: performed *before* enqueue in the request path; the worker trusts the job payload — which is why payloads carry ids, not user input.
Persistence and side effects: external API calls (the whole point); failure emails; replication jobs ([secret-queue.ts:582-591](../../backend/src/services/secret/secret-queue.ts)).
Tests that cover it: [e2e-test/routes/v1/secret-replication.spec.ts](../../backend/e2e-test/routes/v1/secret-replication.spec.ts); no direct unit test found for `$getJobKey` dedupe semantics (investigate).
What juniors usually miss: `attempts: 5` + at-least-once means the handler can run twice for one logical event — every effect inside must be idempotent (safe to repeat).
What seniors notice: dedupe by `jobId` collapses *pending* duplicates but not a job already running — a second change during a long sync must still be delivered; they'd verify BullMQ semantics for completed-job jobId reuse (`removeOnComplete: true` is what re-enables reuse — a subtle, load-bearing option).
Interview angle: "How do you handle a flaky third-party API?" — retries with exponential backoff, idempotent handlers, dedupe keys, and human-visible failure (the email job). All four are in this one file.
Drill: sketch what happens when the same secret is updated 3 times in one second: how many sync jobs run, and why.
Self-grade — Basic: named the queue and retries. Solid: explained jobId dedupe + idempotency need. Strong: raised the running-job race and the removeOnComplete interaction.

---

## Flow 5: Webhook trigger (outbound side effect + SSRF defense)

Why this flow matters: user-configured URLs called from the server = the classic SSRF setup; this flow shows the defense and the encrypt-at-rest pattern for stored credentials.

Open these files first:
- [webhook-service.ts:28-56](../../backend/src/services/webhook/webhook-service.ts) — factory deps + events filter
- [webhook-fns.ts:22-110](../../backend/src/services/webhook/webhook-fns.ts) — decrypt, payload, trigger
- [lib/validator/validate-url.ts:13](../../backend/src/lib/validator/validate-url.ts) — `blockLocalAndPrivateIpAddresses`

Trace:

| Step | Owner | File | What happens | Data shape | Risk |
| --- | --- | --- | --- | --- | --- |
| 1 | Admin UI/API | webhook routes → [webhook-service.ts:58+](../../backend/src/services/webhook/webhook-service.ts) | Create webhook: CASL check, URL validated by `blockLocalAndPrivateIpAddresses` (imported at line 9) | URL + optional secret | Without the guard: `http://169.254.169.254/` steals cloud creds |
| 2 | Storage | webhook-dal + KMS | URL/secret encrypted with project data key (`createCipherPairWithDataKey`, dep at [webhook-service.ts:33](../../backend/src/services/webhook/webhook-service.ts)) | ciphertext columns | Encrypt-at-rest for outbound credentials |
| 3 | Event | secret change → [secret-queue.ts:674-675](../../backend/src/services/secret/secret-queue.ts) | `SecretWebhook` job enqueued | event payload | Async: user's save isn't blocked by webhook latency |
| 4 | Worker | [webhook-fns.ts:285-320](../../backend/src/services/webhook/webhook-fns.ts) | `fnTriggerWebhook`: load matching webhooks, filter by `eventsFilter` ([webhook-service.ts:48-56](../../backend/src/services/webhook/webhook-service.ts)), decrypt, `triggerWebhookRequest` | HTTP POST | Receiving end is untrusted; timeouts required |
| 5 | Payload | [webhook-fns.ts:65](../../backend/src/services/webhook/webhook-fns.ts) | `getWebhookPayload` — event shape is a de-facto public contract | JSON | Renaming a field breaks consumers silently |

Validation and authorization: CASL Webhooks permission at create; SSRF validation of the URL at the trust boundary.
Persistence and side effects: encrypted row; outbound HTTP to arbitrary (validated) URLs.
Tests that cover it: URL guard unit-tested at [lib/validator/validate-url.test.ts](../../backend/src/lib/validator/validate-url.test.ts); no direct webhook e2e found under `e2e-test/` (searched for "webhook") — coverage gap worth a ticket.
What juniors usually miss: why the URL check exists at all — the *server* makes this request, so a private URL lets a user borrow the server's network position.
What seniors notice: validation at create-time only protects if DNS doesn't change later (DNS rebinding); they'd check whether `triggerWebhookRequest` re-validates at send time ([validate-url.ts:171](../../backend/src/lib/validator/validate-url.ts) shows a send-path validation — confirm which callers use it).
Interview angle: "What is SSRF and how do you prevent it?" — answer with this exact flow: user-supplied URL, server-side fetch, private-IP blocklist, and the rebinding caveat.
Drill: list three URLs that must be rejected and why (`localhost`, `169.254.169.254`, an RFC-1918 address), then read [validate-url.ts:13+](../../backend/src/lib/validator/validate-url.ts) and check the actual rules.
Self-grade — Basic: knew webhooks fire async. Solid: explained SSRF and encrypt-at-rest. Strong: raised rebinding/recheck-at-send and the payload-as-contract point.

---

## Flow 6: Session expiry and token refresh (client resilience)

Why this flow matters: pure client-side flow every SPA needs; concurrency bug bait (thundering-herd refresh) handled correctly here.

Open these files first:
- [frontend/src/config/request.ts](../../frontend/src/config/request.ts) — all 132 lines
- [frontend/src/hooks/api/reactQuery.tsx:220-226](../../frontend/src/hooks/api/reactQuery.tsx) — retry/staleTime defaults

Trace:

| Step | Owner | File | What happens | Data shape | Risk |
| --- | --- | --- | --- | --- | --- |
| 1 | Any query | React Query → Axios | Request goes out with current Bearer token ([request.ts:22-44](../../frontend/src/config/request.ts)) | header | — |
| 2 | Server | — | 401 with token-expired message | error body | Interceptor matches message text ([request.ts:54-57](../../frontend/src/config/request.ts)) — string matching an error contract is brittle |
| 3 | Interceptor | [request.ts:63-72](../../frontend/src/config/request.ts) | Only if: 401 + expired-message + have token + not already retried (`infisicalRetry` flag) | — | Flag prevents infinite retry loops |
| 4 | Refresh | [request.ts:75-84](../../frontend/src/config/request.ts) | `refreshPromise` deduped: N concurrent 401s → 1 refresh call | promise | Without dedupe: refresh stampede, races, random logouts |
| 5 | Replay | [request.ts:86-89](../../frontend/src/config/request.ts) | Original request retried with new token | — | Non-idempotent requests replayed — safe only because original never reached its handler (401 at auth layer) |
| 6 | Refresh fails | [request.ts:91-125](../../frontend/src/config/request.ts) | Clear tokens, notify, save redirect URL (5-min expiry) in sessionStorage, go to `/login` | — | `isRedirecting` flag prevents duplicate redirects |

Validation and authorization: n/a client-side; the server remains the authority.
Persistence and side effects: sessionStorage redirect bookmark; full page navigation.
Tests that cover it: none found in `frontend/` for the interceptor (no test setup colocated with `config/`) — an interceptor unit test is a great first contribution.
What juniors usually miss: step 4. They write "call refresh in the catch" and ship a stampede where 10 in-flight queries trigger 10 refreshes.
What seniors notice: expired-token detection via message substring (`isTokenExpiredError`) couples client behavior to server copy — an error *code* would be the robust contract. Also the interplay with React Query's `retry: 1`.
Interview angle: classic frontend interview question verbatim: "How do you handle token refresh with concurrent requests?" The `refreshPromise` singleton is the expected answer; you can cite real code.
Drill: whiteboard the timeline of 3 concurrent requests hitting an expired token — mark which awaits what, and where a bug would appear if `refreshPromise` were a boolean instead of a shared promise.
Self-grade — Basic: described 401→refresh→retry. Solid: explained dedupe and the retry flag. Strong: critiqued message-string matching and knew why replay is safe here.
