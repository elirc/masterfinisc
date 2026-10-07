# Command Cheatsheet

**Verified** = executed during curriculum authoring. **Inferred** = read from Makefile/package.json/CLAUDE.md but not executed. When in doubt, open the script definition before running.

## Repo root ([Makefile](../../Makefile))

| Command | Does | Status |
| --- | --- | --- |
| `make up-dev` | full dev stack via docker-compose.dev.yml (Postgres, Redis, backend, frontend, nginx) | inferred |
| `make up-dev-metrics` | dev stack + Prometheus/OTel profile | inferred |
| `make down` | stop dev stack | inferred |
| `make reviewable-api` | backend lint:fix + type:check — run before any PR | inferred |
| `make reviewable-ui` | frontend lint:fix + type:check | inferred |
| `make reviewable` | both | inferred |

## Backend (`cd backend`)

| Command | Does | Status |
| --- | --- | --- |
| `npm run dev` | tsx watch + pino-pretty | inferred |
| `npm run build` | tsup production build | inferred |
| `npm run type:check` | tsc (8GB heap) | inferred |
| `npm run lint:fix` | ESLint autofix | inferred |
| `npm run test:unit` | Vitest on `src/**/*.test.ts` (no DB needed) | inferred |
| `npm run test:e2e` | Vitest e2e (needs Postgres+Redis+`.env.test`; single-threaded) | inferred |
| `npm run test:e2e-watch` | e2e watch mode | inferred |
| `npm run migration:new` | scaffold migration (interactive) | inferred |
| `npm run migration:latest-dev` | run pending migrations (dev knexfile) | inferred |
| `npm run migration:rollback-dev` | roll back last batch | inferred |
| `npm run generate:schema` | regenerate Zod/TS types from live DB — **always after migrations** | inferred |
| `npm run seed-dev` | run seeds | inferred |
| `npm run generate:component` | scaffold DAL/service/router | inferred |

## Frontend (`cd frontend`)

| Command | Does | Status |
| --- | --- | --- |
| `npm run dev` | Vite dev server, port 3000 | inferred |
| `npm run build` | tsc check + vite build | inferred |
| `npm run type:check` | tsc only | inferred |
| `npm run lint:fix` | ESLint autofix | inferred |
| `npm run storybook` | Storybook, port 6006 | inferred |

## Facts verified directly (see [verification-log](verification-log.md))

- `min-release-age=7` in both `.npmrc` files (read the files)
- 423 migration files (plus the `migrations/utils/` helpers); 272 schema files; 27 backend unit-test files (counted)
- Line anchors throughout the curriculum (grep/sed against this working copy, 2026-07-09)

## Useful inspection one-liners (safe, read-only)

```bash
rg -n "verifyAuth\(" backend/src/server/routes/v4/   # auth modes per route
rg -n "throwUnlessCan" backend/src/services/<domain>/ # authz checks in a service
rg -n "queueService.queue" backend/src/services/      # every producer
rg --files backend/src/db/migrations | tail -20       # newest migrations
```
