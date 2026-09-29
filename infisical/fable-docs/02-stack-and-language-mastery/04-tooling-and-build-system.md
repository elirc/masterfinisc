# Tooling and Build System

## The toolchain at a glance

| Concern | Backend | Frontend |
| --- | --- | --- |
| Dev runner | `tsx watch` + pino-pretty (`npm run dev`) | Vite dev server, port 3000 |
| Prod build | `tsup` (bundler for Node targets, with sourcemaps) | `tsc` check + `vite build` |
| Type check | `npm run type:check` (8GB heap — the codebase is that big) | `npm run type:check` (`tsconfig.app.json`) |
| Lint | ESLint (classic `.eslintrc.js`, airbnb-ts base) | ESLint 9 flat config, airbnb-ts + prettier, double quotes |
| Import order | `simple-import-sort`, 7 groups (side-effects → node: → 3rd-party → `@app/` → `@lib/` → `@server/` → relative) | same idea, own group order |
| Tests | Vitest (unit + custom e2e environment) | Storybook for components; no unit-test setup found for hooks (*verify before claiming in interviews*) |
| Path alias | `@app/*` → `src/*` | `@app/*` → `src/*` |

Sources: [backend/CLAUDE.md](../../backend/CLAUDE.md), [frontend/CLAUDE.md](../../frontend/CLAUDE.md), both `package.json` files. Commands *inferred* unless marked verified in [09-reference/verification-log.md](../09-reference/verification-log.md).

## Why two different dev runners (transferable)

`tsx` executes TS directly with esbuild transforms — fast start, no bundling, ideal for a server where Node resolves modules at runtime. Vite serves the browser over native ESM with on-demand transforms — instant HMR regardless of app size. Production inverts it: the server gets bundled by `tsup` (fewer files, faster cold start, prod-only deps), the SPA gets a fully optimized Rollup build. Interviewers ask "what does your build actually do?" more often than juniors expect; "transpile + bundle + tree-shake, different tradeoffs per runtime" with these concrete choices is a strong answer.

## Generated code — the "do not edit" map

| Artifact | Generator | Regenerate when |
| --- | --- | --- |
| [frontend/src/routeTree.gen.ts](../../frontend/src/routeTree.gen.ts) | TanStack Router from [routes.ts](../../frontend/src/routes.ts) | routes.ts changes (dev server does it) |
| [backend/src/db/schemas/*](../../backend/src/db/schemas/) | `npm run generate:schema` from live DB | after every migration |
| `frontend/src/lib/<crate>/` | wasm-pack from [wasm/](../../wasm/) crates | after editing crate src (see each crate's CLAUDE.md) |

Rule: if you edit generated code, the next regeneration silently destroys your work. Recognize generated files by header comments and by being listed in a generator's output path — check before "fixing" anything inside them.

## Guardrails wired into the workflow

- `make reviewable-api` / `make reviewable-ui` ([Makefile:22-30](../../Makefile)) — the pre-PR gate: lint:fix + type:check. Run them; CI runs equivalents.
- Husky hooks from the root [package.json](../../package.json) (`prepare: husky install`).
- `min-release-age=7` in both `.npmrc` files — npm resolves only ≥7-day-old package versions (supply-chain damage limiter, *verified*).
- Scaffolding: `backend npm run generate:component` creates DAL/service/router skeletons — read its templates once to see the house style distilled.

## Drills

1. Run `npm run type:check` in backend (safe, read-only). Time it. Now explain why the heap flag exists and what you'd try if it OOM'd anyway (project references / incremental builds).
2. Open [routeTree.gen.ts](../../frontend/src/routeTree.gen.ts), find the overview route entry, and trace it back to the exact line in [routes.ts](../../frontend/src/routes.ts) that produced it.
3. Explain to a rubber duck what breaks if you add a migration but skip `generate:schema` (compiler keeps old table types → your new column is invisible/`any`).

## Interview angle

- "Walk me through what happens when you run the dev server" → esbuild/ESM story above. ([08-interview-prep/01](../08-interview-prep/01-js-ts-node-deep-dive.md) Q11)
- "How do you keep DB types honest?" → schema generation from the database, not hand-written interfaces.
- "How do you defend against malicious npm packages?" → min-release-age, lockfiles, minimal dep policy (FIPS constraint in [CLAUDE.md](../../CLAUDE.md)) — a supply-chain answer with receipts.
