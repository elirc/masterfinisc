# Trace Tables

Fill each table yourself first (columns: Step, File:line, Value shape, Owner, Transformation, Risk), then compare with the completed version. Completed rows compress detail — your version should be *more* granular, not less.

## Trace 1 — UI to API: creating secret `DB_URL` in `/backend` at env `dev`

| Step | File:line | Value shape | Owner | Transformation | Risk |
| --- | --- | --- | --- | --- | --- |
| 1 | form submit | `{key: "DB_URL", value: "postgres://..."}` | UI | rhf values → DTO | client-only validation |
| 2 | [mutations.tsx:44](../../frontend/src/hooks/api/secrets/mutations.tsx) | `POST /api/v4/secrets/DB_URL` + body | API hook | key moves into URL path (`encodeURIComponent`) | key with `/` must encode |
| 3 | [request.ts:22-44](../../frontend/src/config/request.ts) | + `Authorization: Bearer eyJ...` | Axios | header injection | wrong token tier picked (mfa/signup/auth) |
| 4 | [secret-router.ts:405-462](../../backend/src/server/routes/v4/secret-router.ts) | Zod-parsed DTO | route | string body → typed DTO | schema drift = contract break |
| 5 | [secret-v2-bridge-service.ts:304](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) | `folder.id` | service | `(projectId, env, path)` → folderId | 404 if path wrong |
| 6 | [secret-v2-bridge-service.ts:339-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) | CASL decision | service | attrs → allow/throw | missing attr widens access |
| 7 | DAL insert | encrypted row + version | DAL | plaintext → ciphertext (KMS data key) | write must hit primary |
| 8 | [mutations.tsx:58-86](../../frontend/src/hooks/api/secrets/mutations.tsx) | 9 invalidated key families | UI cache | server truth refetched | missed family = stale view |

## Trace 2 — Persistence: what `ormify.updateById` does with `$incr`

Build this one entirely yourself from [lib/knex/index.ts](../../backend/src/lib/knex/index.ts) (read `updateById` below line 240): the value starts as `{ $incr: { version: 1 }, name: "x" }` — trace how regular fields and `$incr` fields diverge into `.update()` and `.increment()` calls, which SQL each produces, and why atomic increment beats read-modify-write under concurrency (two workers incrementing simultaneously). Risk column must include: partial update visibility, replica reads of pre-increment values.

## Trace 3 — Auth: one Bearer token, five outcomes

Start: `Authorization: Bearer eyJhbGciOi...` on `GET /api/v4/secrets`.

| Step | File:line | Value shape | Owner | Transformation | Risk |
| --- | --- | --- | --- | --- | --- |
| 1 | [inject-identity.ts:94](../../backend/src/server/plugins/auth/inject-identity.ts) | headers | plugin | `x-api-key`? no → Bearer path | deprecated path first |
| 2 | [inject-identity.ts:112](../../backend/src/server/plugins/auth/inject-identity.ts) | decoded JWT claims | plugin | signature verify (`AUTH_SECRET`, line 218) + `authTokenType` switch → `AuthMode` | forged/expired token rejected here |
| 3 | [inject-permission.ts:12-23](../../backend/src/server/plugins/auth/inject-permission.ts) | `req.permission = {type: USER, id, orgId, ...}` | plugin | actor → permission ctx | wrong orgId = tenant bleed |
| 4 | [verify-auth.ts:20-29](../../backend/src/server/plugins/auth/verify-auth.ts) | pass/throw | route hook | mode ∈ allowlist? org present? | route missing verifyAuth |
| 5 | [permission-service.ts:405+](../../backend/src/ee/services/permission/permission-service.ts) | CASL ability | service | roles+privileges → rules | stale role cache (**investigate** caching) |

Your job: redo this table for an `IDENTITY_ACCESS_TOKEN` instead of a user JWT — which rows change, which don't?

## Trace 4 — Error: expired session during a mutation

Trace `POST` → 401 `{message: "token expired..."}` → interceptor. Fill in: which of the four gate conditions ([request.ts:63-70](../../frontend/src/config/request.ts)) pass, what `refreshPromise` holds at each of three concurrent requests, what happens to the original request config (`infisicalRetry` flag), and both exits (refresh ok → replay; refresh fails → token clear, notification, sessionStorage redirect bookmark with 5-min expiry, `/login`). Risk column must include: replaying a non-idempotent POST (why safe here), message-string matching, and the `isRedirecting` window.

---

Self-grade — **Weak**: rows name files only. **Solid**: every row has a concrete value shape (not "the data"). **Strong**: every risk cell is a *scenario*, and you can walk any row's transformation from memory. These four tables are UI-to-API, persistence, auth, and error traces — one of each, which is exactly the spread debugging interviews sample from.
