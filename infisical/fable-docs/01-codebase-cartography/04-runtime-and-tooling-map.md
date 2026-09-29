# Runtime and Tooling Map

## Package management

Two independent npm packages (`backend/`, `frontend/`) — no workspaces. Each has its own lockfile and an `.npmrc` with `min-release-age=7` (*verified*): npm resolves only versions published ≥7 days ago, a supply-chain-attack damage limiter. Path alias `@app/*` → `./src/*` in both packages.

## Commands (see [09-reference/command-cheatsheet.md](../09-reference/command-cheatsheet.md) for the full table)

| Task | Command | Source |
| --- | --- | --- |
| Full dev stack | `make up-dev` | [Makefile:7-8](../../Makefile) — docker compose dev file (Postgres, Redis, backend, frontend, nginx) |
| Backend dev | `cd backend && npm run dev` | tsx watch + pino-pretty ([backend/CLAUDE.md](../../backend/CLAUDE.md)) |
| Frontend dev | `cd frontend && npm run dev` | Vite on port 3000 |
| Pre-PR gate | `make reviewable-api` / `make reviewable-ui` | [Makefile:22-30](../../Makefile) — lint:fix + type:check |
| Migrations | `npm run migration:new`, `migration:latest-dev`, `migration:rollback-dev` | backend package scripts |
| Schema types | `npm run generate:schema` after any migration | regenerates Zod types in `src/db/schemas/` |
| Tests | `npm run test:unit` / `npm run test:e2e` | e2e needs DB+Redis, single-threaded |
| Scaffolding | `npm run generate:component` | generates DAL/service/router boilerplate |

All *inferred* (read from scripts, not executed) unless the verification log says otherwise.

## Runtime boundaries — know which world your code runs in

| Boundary | Runtime | Constraints to respect |
| --- | --- | --- |
| Browser SPA | React 18 in the browser | No secrets in code; everything shipped is public; auth token lives in memory (see [request.ts:22-44](../../frontend/src/config/request.ts)) |
| API server | Node (Fastify 4) | Single-threaded event loop; long CPU work blocks every request — heavy work goes to queues |
| Queue workers | Same Node process family, BullMQ consumers over Redis | At-least-once delivery: handlers must be idempotent ([secret-queue.ts:638](../../backend/src/services/secret/secret-queue.ts) uses deterministic `jobId` for dedupe) |
| PostgreSQL | Primary + optional read replicas | Reads may hit `db.replicaNode()` and see slightly stale data ([lib/knex/index.ts:168](../../backend/src/lib/knex/index.ts)); writes always hit primary |
| Redis | Keystore, locks, queues | Not durable storage; treat as cache/coordination |
| WASM | Rust compiled for the browser | Bindings are committed; frontend builds without a Rust toolchain ([CLAUDE.md](../../CLAUDE.md)) |

**Interview vocabulary — "boundary"**: a line across which assumptions change (trust, latency, failure modes, data freshness). The browser/API line is a *trust* boundary; the API/replica line is a *consistency* boundary; the API/queue line is a *reliability* boundary. Naming which assumption changes at each line is a mid-level-vs-junior discriminator in system design rounds.

## Environment variables

Backend config is centralized (grep `AUTH_SECRET` usage at [inject-identity.ts:218](../../backend/src/server/plugins/auth/inject-identity.ts) — `appCfg.AUTH_SECRET` comes from an env-config module in `backend/src/lib/config/`). High-level groups: DB/Redis connection, `AUTH_SECRET` for JWT signing, encryption root keys, SMTP, integration credentials. Never enumerate or copy real values into docs or tests.

## Build & deploy surfaces

- `Dockerfile.standalone-infisical` — one container serving frontend + backend.
- `Dockerfile.fips.standalone-infisical` — FIPS-compliant build; new backend dependencies must not break FIPS ([CLAUDE.md](../../CLAUDE.md)).
- `docker-compose.prod.yml` — backend + Postgres + Redis.

## Drill

Answer without looking: (1) Why must queue handlers here tolerate running twice? (2) Why can a `find()` right after a `create()` return stale data? (3) Why does the frontend never read env vars for secrets? Check yourself against the runtime-boundary table. Strong answers name the mechanism (at-least-once delivery + retries; replica lag; browser code is public artifact), not just the rule.
