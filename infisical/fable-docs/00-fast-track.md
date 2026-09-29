# 00 — Fast Track (one weekend)

Goal: by Sunday night you can run Infisical locally, trace one request from browser to database, make one safe change, run one test, and explain a real flow aloud as if in an interview.

## Saturday morning — run it

All commands below are **inferred** from [Makefile](../Makefile), [backend/package.json](../backend/package.json), and [frontend/package.json](../frontend/package.json) — they were read, not executed, during curriculum authoring. Docker Desktop is required for the dev stack.

```bash
# From repo root — starts PostgreSQL, Redis, backend, frontend, nginx (inferred)
make up-dev            # = docker compose -f docker-compose.dev.yml up --build
```

Alternative without full Docker: run Postgres+Redis in containers, then in separate terminals:

```bash
cd backend && npm install && npm run migration:latest-dev && npm run dev   # inferred
cd frontend && npm install && npm run dev                                  # inferred, port 3000
```

Note: both packages enforce `min-release-age=7` in their `.npmrc` (*verified* — [backend/.npmrc](../backend/.npmrc), [frontend/.npmrc](../frontend/.npmrc)): npm will only resolve package versions published ≥7 days ago. This is a supply-chain defense — remember it; it's a good interview story about dependency risk.

Sanity checks:

```bash
cd backend && npm run type:check     # inferred; uses 8GB heap per package.json
make reviewable-api                  # inferred; lint:fix + type:check (Makefile:27-30)
```

## Saturday afternoon — the first 10 files, in order

Open these in order. Don't read every line; answer the question next to each.

1. [CLAUDE.md](../CLAUDE.md) — the maintainers' own map. What are the two deprecated auth modes?
2. [backend/CLAUDE.md](../backend/CLAUDE.md) — how is dependency injection done here? (Hint: no container.)
3. [backend/src/server/routes/v4/secret-router.ts](../backend/src/server/routes/v4/secret-router.ts) lines 47–170 — one route definition: method, url, rate limit, Zod schema, `onRequest: verifyAuth(...)`, handler. This shape repeats hundreds of times.
4. [backend/src/server/plugins/auth/verify-auth.ts](../backend/src/server/plugins/auth/verify-auth.ts) (32 lines, read all) — how a route declares which auth modes it accepts.
5. [backend/src/services/secret/secret-service.ts](../backend/src/services/secret/secret-service.ts) lines 109–162 — a service factory's dependency list. Why is every dependency narrowed with `Pick<...>`?
6. [backend/src/lib/knex/index.ts](../backend/src/lib/knex/index.ts) lines 156–240 — `ormify()`, the tiny homegrown ORM every DAL wraps. Which methods read from `db.replicaNode()` and which write to `db`?
7. [backend/src/services/secret/secret-dal.ts](../backend/src/services/secret/secret-dal.ts) lines 11–45 — a DAL that overrides `update` to auto-increment `version`. Why in the DAL and not the service?
8. [frontend/src/config/request.ts](../frontend/src/config/request.ts) (132 lines, read all) — the Axios instance: token injection, 401 refresh with a deduplicated `refreshPromise`, redirect-to-login.
9. [frontend/src/hooks/api/secrets/queries.tsx](../frontend/src/hooks/api/secrets/queries.tsx) lines 33–58 — the query-key factory (`secretKeys`). Every API domain repeats this.
10. [frontend/src/hooks/api/secrets/mutations.tsx](../frontend/src/hooks/api/secrets/mutations.tsx) lines 25–90 — `useCreateSecretV3`: mutation + the nine query invalidations that follow. Predict before reading: which caches must go stale when a secret is created?

## Saturday evening — trace one flow end to end

**Flow: user creates a secret in the dashboard.**

| Step | Where | Anchor |
| --- | --- | --- |
| 1 | UI mutation fires `POST /api/v4/secrets/:secretName` | [mutations.tsx:44](../frontend/src/hooks/api/secrets/mutations.tsx) |
| 2 | Axios injects `Authorization: Bearer <JWT>` | [request.ts:22-44](../frontend/src/config/request.ts) |
| 3 | Fastify extracts identity from the token | [inject-identity.ts:93-155](../backend/src/server/plugins/auth/inject-identity.ts) |
| 4 | Route checks allowed auth modes | [secret-router.ts:462](../backend/src/server/routes/v4/secret-router.ts), [verify-auth.ts:10-32](../backend/src/server/plugins/auth/verify-auth.ts) |
| 5 | Service validates folder, duplicates, tags | [secret-v2-bridge-service.ts:304-336](../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) |
| 6 | CASL authorization on the exact secret path | [secret-v2-bridge-service.ts:339-347](../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) |
| 7 | DAL writes; version increments | [secret-dal.ts:14-21](../backend/src/services/secret/secret-dal.ts) |
| 8 | Queue jobs fan out (sync, webhooks, replication) | [secret-queue.ts:594-660](../backend/src/services/secret/secret-queue.ts) |
| 9 | UI invalidates nine query keys | [mutations.tsx:58-86](../frontend/src/hooks/api/secrets/mutations.tsx) |

Full version with risks and drills: [01-codebase-cartography/05-key-flows.md](01-codebase-cartography/05-key-flows.md).

## Sunday — one safe change, one test, one teach-back

1. **Safe change** (do not commit): in [backend/src/server/routes/v4/secret-router.ts](../backend/src/server/routes/v4/secret-router.ts), find the `description` string of the list route (~line 57) and reword it. Run `npm run type:check`. Revert. The point is proving you can edit-verify-revert without fear.
2. **One test**: `cd backend && npm run test:unit` (*inferred*; unit tests are `src/**/*.test.ts`, pure functions, no DB needed). E2E tests need running DB/Redis — skip them today.
3. **Teach-back** (the interview rep): stand up and explain the create-secret flow aloud in under 3 minutes, naming: where validation happens, where authorization happens, what's synchronous vs queued, and what the UI does to stay consistent. Record yourself. If you said "and then it just saves it," you skipped steps 5–8 — do it again.

## What the fast track skips

Encryption/KMS internals, the enterprise (`ee/`) permission machinery beyond the entry points, secret approval workflows, the WASM crates, SCIM/SSO, and all of the drills. That's what the other nine modules are for.
