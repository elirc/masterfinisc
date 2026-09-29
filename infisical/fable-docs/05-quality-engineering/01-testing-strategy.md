# Testing Strategy

## The layers this repo actually has

| Layer | Where | Runs against | Count/notes |
| --- | --- | --- | --- |
| **Unit** | `src/**/*.test.ts` next to source (27 files found) | pure functions, no I/O | e.g. [lib/casl/boundary.test.ts](../../backend/src/lib/casl/boundary.test.ts), [lib/validator/validate-url.test.ts](../../backend/src/lib/validator/validate-url.test.ts), [lib/cache/with-cache.test.ts](../../backend/src/lib/cache/with-cache.test.ts) |
| **Route e2e** | [backend/e2e-test/routes/](../../backend/e2e-test/routes/) (v1–v4) | full server + real Postgres/Redis, single-threaded | custom Vitest environment boots everything: [vitest-environment-knex.ts](../../backend/e2e-test/vitest-environment-knex.ts) (DB, Redis flush, HSM, seeds, mock SMTP at [e2e-test/mocks/smtp](../../backend/e2e-test/mocks/)) |
| **UI components** | Storybook (`npm run storybook`) | visual/dev harness, not assertions | no frontend unit-test setup found (*gap*) |
| **BDD / infra** | `docker-compose.bdd.yml`, `docker-compose.e2e-dbs.yml`, `cypress.config.js` at root | external-DB integrations, browser | read before claiming CI behavior — see verification log |

What the distribution tells you (transferable read): unit tests cluster around **pure, tricky logic** (permission glob subsets, URL validation, crypto, cron parsing) — the highest bug-density-per-line spots. Everything stateful is tested at the **route level with real infrastructure** — no mocked-DB middle layer. That's a deliberate tradeoff: route e2e catches integration bugs mocks would hide, at the price of slower, serial runs (`test:e2e` is single-threaded).

## What belongs at each layer (this repo's implicit rules)

- Pure function with branching (parsers, matchers, formatters) → colocated `*.test.ts`, Vitest globals, no setup.
- Anything touching DB/permissions/auth → e2e spec via `testServer.inject()` with the pre-authenticated `jwtAuthToken` global ([org.spec.ts:3-9](../../backend/e2e-test/routes/v1/org.spec.ts)).
- Don't test: `ormify` plumbing through every DAL (tested implicitly by every e2e), generated schemas, framework behavior.

## Fixtures, isolation, and flake prevention

- The e2e environment **flushes Redis** and runs seeds at boot ([vitest-environment-knex.ts:57-58](../../backend/e2e-test/vitest-environment-knex.ts) area) — shared state resets per run, not per test; specs must therefore create *their own* uniquely-named resources (see the CRUD helpers pattern in [testUtils/secrets.ts](../../backend/e2e-test/testUtils/secrets.ts)).
- Single-threaded e2e = no cross-test races by construction; the cost is wall time.
- SMTP is mocked at the boundary ([e2e-test/mocks/smtp](../../backend/e2e-test/mocks/)) — external effects stubbed at the *edge*, not the service.
- Time/randomness: crypto and cron logic are isolated in pure libs with their own tests — the classic flake sources are pushed to unit level where they can be controlled.

Transferable principles: **mock at boundaries you don't own; use real implementations for everything you do own** (DB included, if you can afford it); **flakes are architecture feedback** — a flaky test usually means hidden shared state or time dependence.

## What a junior misses vs a senior checks

Junior: "coverage %". Senior: *which failures would escape*. Here, the visible escape hatches: no webhook e2e (searched), no frontend hook tests (interceptor!), metadataFilter parser untested. Each is a contribution opportunity in [06-contribution-practice](../06-contribution-practice/01-good-first-tickets.md).

## Drill

Classify these five hypothetical changes by the cheapest layer that would catch their bugs: (1) tweak to glob-subset matching, (2) new secret route param, (3) changed 401 message, (4) new invalidation key, (5) migration adding a column. Answers: unit / route-e2e / route-e2e **plus a frontend test that doesn't exist** (that's the trap) / none-existing (manual or new UI test) / e2e + generate:schema compile check.

Interview angle: "How do you decide unit vs integration?" → highest-bug-density logic gets unit tests; stateful behavior gets real-infrastructure tests; mock only unowned boundaries. Concrete example: this repo unit-tests permission glob math but e2e-tests permission *enforcement*. See [08-interview-prep/05](../08-interview-prep/05-debugging-and-code-review-rounds.md).
