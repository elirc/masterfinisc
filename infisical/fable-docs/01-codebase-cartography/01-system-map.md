# System Map

## Repo shape: a two-app monorepo (not npm workspaces)

`backend/` and `frontend/` are separate npm packages with their own `package.json`, lockfiles, `.npmrc`, and lint configs. The root [package.json](../../package.json) exists mostly for husky hooks and a couple of shared overrides — this is *not* an npm/pnpm workspaces monorepo. Cross-cutting commands live in the [Makefile](../../Makefile) (`reviewable-api`, `reviewable-ui`, `up-dev`).

```text
infisical/
├── backend/          Fastify 4 API server (TypeScript, Knex/PostgreSQL, BullMQ/Redis)
│   └── src/
│       ├── server/   HTTP layer: plugins (auth), routes v1–v4, config
│       ├── services/ 100+ service modules: dal + service + types (+ queue, fns)
│       ├── ee/       Enterprise: permission engine, audit logs, EE routes/services
│       ├── db/       knexfile, 423 migrations, generated Zod schemas (272 files)
│       ├── lib/      shared: knex/ormify, errors, validator (SSRF), logger, crypto
│       ├── queue/    BullMQ queue service wrapper
│       └── keystore/ Redis-backed key-value + locks
├── frontend/         React 18 SPA (Vite 6, TanStack Router+Query, Tailwind v4)
│   └── src/
│       ├── pages/    route-level components per product area (+ route.tsx files)
│       ├── components/ v3 (preferred) and v2 (legacy) shared UI
│       ├── hooks/api/  100+ API domains: queries.tsx / mutations.tsx / types.tsx
│       ├── context/  User, Org, Project, permissions, server config providers
│       ├── routes.ts TanStack virtual route DSL → routeTree.gen.ts (generated)
│       └── config/   Axios instance with auth interceptors
├── wasm/             Rust crates → WASM; generated bindings committed to frontend
├── docs/             Mintlify product docs site
├── docker-compose.dev.yml   local stack: Postgres, Redis, backend, frontend, nginx
└── Makefile          reviewable-api / reviewable-ui / up-dev
```

## Ownership map

| Concern | Lives in | Entry point / example |
| --- | --- | --- |
| HTTP routing | `backend/src/server/routes/{v1..v4}/` | [v4/secret-router.ts](../../backend/src/server/routes/v4/secret-router.ts) |
| AuthN (who are you) | `backend/src/server/plugins/auth/` | [inject-identity.ts:93-155](../../backend/src/server/plugins/auth/inject-identity.ts) |
| AuthZ (what may you do) | `backend/src/ee/services/permission/` | [permission-service.ts:405](../../backend/src/ee/services/permission/permission-service.ts) |
| Business logic | `backend/src/services/<domain>/<domain>-service.ts` | [secret-v2-bridge-service.ts](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) |
| Data access | `backend/src/services/<domain>/<domain>-dal.ts` over [ormify](../../backend/src/lib/knex/index.ts) | [secret-dal.ts](../../backend/src/services/secret/secret-dal.ts) |
| Schema & migrations | `backend/src/db/migrations/` (423 migrations + `utils/`), generated Zod in `db/schemas/` | `npm run migration:new`, `npm run generate:schema` |
| Async jobs | `backend/src/services/<domain>/<domain>-queue.ts` via `backend/src/queue/` | [secret-queue.ts](../../backend/src/services/secret/secret-queue.ts) |
| UI routes | [frontend/src/routes.ts](../../frontend/src/routes.ts) (virtual DSL) | secret-manager routes at lines 19-40 |
| Server state (UI) | `frontend/src/hooks/api/<domain>/` | [secrets/queries.tsx:33-58](../../frontend/src/hooks/api/secrets/queries.tsx) |
| UI permissions | `frontend/src/context/*Permission*`, `frontend/src/hoc/` | `useProjectPermission()` used in [OverviewPage.tsx:300](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx) |
| Tests | `backend/src/**/*.test.ts` (unit), `backend/e2e-test/` (route e2e) | [e2e-test/routes/v1/org.spec.ts](../../backend/e2e-test/routes/v1/org.spec.ts) |

## The dependency-wiring center of gravity

Everything meets in **[backend/src/server/routes/index.ts](../../backend/src/server/routes/index.ts)** (3,606 lines):

- ~line 538 onward: every DAL factory instantiated with `db` (e.g. `userDAL = userDALFactory(db)` at line 538, through ~line 2997).
- After DALs: every service factory receives its DALs + peer services.
- Line 3291: `server.decorate("services", {...})` exposes them all as `server.services.*`.
- Lines 3572–3591: route registration — **EE routes registered before community routes** per API version (v1 at 3572-3573), then v2 (3580), v3 (3587), v4 (3591).

This one file is the whole dependency graph, readable top to bottom. There is no IoC container to reverse-engineer.

## Public vs private surfaces

- **Public**: the versioned REST API (`/api/v1..v4`) — Zod schemas double as the OpenAPI contract (`operationId`, `tags` in every route). Changing a response schema is a public-contract change. Also public-ish: webhook payload shapes ([webhook-fns.ts:65](../../backend/src/services/webhook/webhook-fns.ts)).
- **Private/internal**: service factory signatures, DAL methods, query-key shapes, `ee/` internals. Free to refactor with type-checker support.
- **Generated — do not hand-edit**: `frontend/src/routeTree.gen.ts`, `backend/src/db/schemas/*` (regenerate with `npm run generate:schema`), `frontend/src/lib/<crate>/` WASM bindings.

## Senior noticing

- The `ee/` boundary is a **license boundary**, not just a folder: EE routes register first so they can shadow community routes. When you can't find where a route is handled, check [ee/routes](../../backend/src/ee/routes/) before community routes.
- Two generations of secrets engine coexist: `services/secret/` (v1, blind-index era) and `services/secret-v2-bridge/` (current). The "bridge" naming is migration residue — see [03-domain-glossary.md](03-domain-glossary.md).
- Deprecated auth modes (`API_KEY`, `SERVICE_TOKEN`) are still wired for backward compatibility but banned in new code ([CLAUDE.md](../../CLAUDE.md)). Recognizing "kept for compat, closed for new use" is a senior read of any codebase.

## Drill

Without looking back at this page, sketch the request path for `DELETE /api/v4/secrets/:secretName` naming the five layers it must pass (route → auth plugin chain → service → DAL → queue side effects), then verify against [secret-router.ts:734-773](../../backend/src/server/routes/v4/secret-router.ts).

Self-grade — **Basic**: named route and service. **Solid**: included `verifyAuth` + permission injection and the DAL. **Strong**: also predicted the post-write queue fan-out and named the file where services get wired (`routes/index.ts`).
