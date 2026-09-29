# Good First Tickets (15)

Compact ticket format: Story · Why good · Anchors · Plan · Risks/Checks · Interview story potential. Difficulty Easy/Medium; all are docs-, test-, or narrowly-scoped-code changes with small blast radius. Ticket IDs J1–J15 are referenced elsewhere in the curriculum.

---

## J1: Unit-test the metadataFilter parser (Easy, ~3h)
Story: As a maintainer, I want the query-string metadata parser covered by tests so malformed input can't 500.
Why good: pure logic, zero runtime risk, closes a real gap.
Anchors: [secret-router.ts:64-120](../../backend/src/server/routes/v4/secret-router.ts).
Plan: extract the transform body to `parse-metadata-filter.ts` (or test via the Zod schema directly to avoid any code move); cases: happy, missing value, >10 filters, `=`/`,` junk, empty string.
Risks/Checks: behavior must not change — tests first, extraction second. Reject-risk: maintainer may prefer no extraction; testing the schema as-is is the safe variant.
Interview story potential: "Found an untested hand-rolled parser at a public API boundary and pinned its behavior with tests before touching it."

## J2: Interceptor unit tests for token refresh (Medium, ~1d)
Story: As a maintainer, I want the 401-refresh logic tested so auth changes can't silently break session recovery.
Why good: highest-value untested file in the frontend; pure logic with axios-mock.
Anchors: [request.ts:59-131](../../frontend/src/config/request.ts).
Plan: introduce vitest for frontend (or follow any existing test setup — check first); cases: single 401 refresh+replay, concurrent dedupe (one refresh for three 401s), refresh failure → redirect path, `infisicalRetry` loop guard.
Risks/Checks: adding a test framework is a tooling decision — propose in an issue first (maintainer-rejection risk if they have other plans).
Interview story potential: "Wrote the concurrency test for a deduplicated token refresh — and can now whiteboard the pattern."

## J3: Cross-tenant secret access e2e (Medium, ~1d)
Story: As a security-minded maintainer, I want an e2e proving org A's token cannot read org B's secrets by id.
Why good: converts the repo's most important invariant into an executable check.
Anchors: [secret-router.ts:252-274](../../backend/src/server/routes/v4/secret-router.ts), precedent [auth-idp-attacks.spec.ts](../../backend/e2e-test/routes/v3/auth-idp-attacks.spec.ts), helpers [testUtils/secrets.ts](../../backend/e2e-test/testUtils/secrets.ts).
Plan: seed/create second org+user, create secret in A, attempt id and name reads with B's token, assert 403/404; assert the *same* for update/delete.
Risks/Checks: none to prod; flake risk if fixtures collide — unique names.
Interview story potential: "Added adversarial multi-tenant tests to a secrets manager" — gold for security questions.

## J4: Webhook trigger e2e (Medium, ~1d)
Story: As a maintainer, I want webhook firing covered by e2e so payload/filter regressions get caught.
Why good: identified coverage gap (no webhook spec found in `e2e-test/`).
Anchors: [webhook-fns.ts:285-320](../../backend/src/services/webhook/webhook-fns.ts), [webhook-service.ts:48-56](../../backend/src/services/webhook/webhook-service.ts).
Plan: local HTTP listener as receiver (mirror the SMTP-mock pattern, [e2e-test/mocks/](../../backend/e2e-test/mocks/)); create webhook → change secret → bounded-poll receiver; assert payload shape and eventsFilter behavior.
Risks/Checks: SSRF validator may block localhost receivers — discover the test seam (that discovery is the learning).
Interview story potential: "Built test infrastructure for outbound side effects, working around SSRF guards correctly."

## J5: Document the auth-mode decision table (Easy, ~2h)
Story: As a new contributor, I want a table of AuthMode × typical actor × where it's valid, so route `verifyAuth` lists stop being cargo-culted.
Anchors: [inject-identity.ts:93-155](../../backend/src/server/plugins/auth/inject-identity.ts), [verify-auth.ts](../../backend/src/server/plugins/auth/verify-auth.ts), [CLAUDE.md](../../CLAUDE.md).
Plan: markdown table in backend docs (or extend backend/CLAUDE.md); flag deprecated modes prominently.
Risks/Checks: docs-only. Reject-risk: duplicate of CLAUDE.md — make it *more specific* (per-mode examples), not restated.
Interview story potential: "Reverse-engineered and documented an auth matrix from code."

## J6: Add a missing `down()` audit note (Easy, ~3h)
Story: As an operator, I want to know which recent migrations are irreversible so rollback plans are honest.
Anchors: newest 15 files in [migrations/](../../backend/src/db/migrations/).
Plan: read 15 migrations; produce a table (migration, reversible?, why); PR as docs or issue comment.
Risks/Checks: read-only. The skill practiced: reading DDL for lock/rollback implications.
Interview story potential: feeds the zero-downtime-migration interview answer with specifics.

## J7: Improve a confusing error message (Easy, ~2h)
Story: As an API consumer, when a folder path doesn't exist I want the error to tell me the project and environment it searched.
Anchors: [secret-v2-bridge-service.ts:305-309](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) (message already includes path+env — find a *worse* one nearby, e.g. bare "Secret already exists" at 322).
Plan: add key/path context to 1–2 messages; grep frontend for message-string matching first (Kata 7 lesson!).
Risks/Checks: THE risk is machine-parsed messages — demonstrate the grep in the PR description.
Interview story potential: "Learned that error strings are contracts the hard way — by checking before changing."

## J8: Storybook story for a v3 component (Easy, ~3h)
Story: As a UI developer, I want a story for one undocumented `components/v3/generic` component.
Anchors: [frontend/src/components/v3/](../../frontend/src/components/v3/), `npm run storybook`.
Plan: pick a component without a story; cover variants/disabled/error states.
Risks/Checks: none. Learn the cva variant pattern while you're in there.
Interview story potential: modest — component API thinking.

## J9: JSDoc the `ormify` contract (Easy, ~3h)
Story: As a backend contributor, I want `ormify`'s replica/tx semantics documented at the source.
Anchors: [lib/knex/index.ts:156-326](../../backend/src/lib/knex/index.ts).
Plan: doc comments on the factory + 3 subtle methods (find's count-over-window, updateById's `$incr`, transaction); note "reads hit replicaNode unless tx".
Risks/Checks: comments-only; keep them about *contract*, not implementation trivia.
Interview story potential: forces total understanding of the repo's data layer — pays off in every DB question.

## J10: Rate-limit preset audit (Easy, ~3h)
Story: As a security reviewer, I want a list of v4 routes and their rate-limit presets to spot inconsistencies.
Anchors: `config.rateLimit` usages in [v4 routers](../../backend/src/server/routes/v4/); presets in `server/config/rateLimiter`.
Plan: grep + table; flag any route without a preset; file as issue with evidence.
Risks/Checks: read-only.
Interview story potential: "Audited rate limiting across an API surface" — nice defense-in-depth story.

## J11: Bounded-poll helper for e2e (Medium, ~4h)
Story: As a test author, I want a `waitFor(assertion, {timeout, interval})` helper so async e2e specs stop hand-rolling polling.
Anchors: polling patterns in [secret-replication.spec.ts](../../backend/e2e-test/routes/v1/secret-replication.spec.ts); home: [e2e-test/testUtils/](../../backend/e2e-test/testUtils/).
Plan: implement helper + refactor one existing usage as demonstration.
Risks/Checks: touch only tests. Reject-risk: vitest's `expect.poll` may already suffice — check first and say so in the PR.
Interview story potential: "Reduced flake surface in an e2e suite" — flake stories always land.

## J12: Add `operationId` / docs polish to one undocumented route (Easy, ~2h)
Story: As an API consumer, I want every route to appear correctly in generated OpenAPI docs.
Anchors: schema fields in [secret-router.ts:54-58](../../backend/src/server/routes/v4/secret-router.ts) as the model; hunt v1/v2 routes missing `operationId` or descriptions.
Plan: find 1–3 routes with missing/wrong OpenAPI metadata; fix to match house style.
Risks/Checks: metadata-only; confirm docs generation still passes type-check.
Interview story potential: "Treating API docs as generated contract, not prose."

## J13: Frontend permission-gate consistency check (Medium, ~1d)
Story: As a user without create rights, I should never see a Create button that 403s on click.
Anchors: `useProjectPermission` ([OverviewPage.tsx:300](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx)), HOCs in [frontend/src/hoc/](../../frontend/src/hoc/).
Plan: pick one page; enumerate its mutating actions; verify each has a UI gate matching the backend CASL action; fix one mismatch or report none found.
Risks/Checks: UI-only; backend remains the enforcer (state that in the PR).
Interview story potential: "Aligned client permission UX with server-side ABAC" — great authz talking point.

## J14: Seed-data documentation (Easy, ~3h)
Story: As a new contributor, I want to know what `seed-data` creates so e2e tests are writable without archaeology.
Anchors: [backend/src/db/seed-data.ts](../../backend/src/db/seed-data.ts), seeds dir, usage in [vitest-environment-knex.ts](../../backend/e2e-test/vitest-environment-knex.ts).
Plan: document seeded org/project/users/tokens in a short md; link from e2e docs.
Risks/Checks: docs-only; never include real-looking credentials in examples.
Interview story potential: onboarding-empathy story for "how do you ramp up on a codebase."

## J15: Reproduce and file one `staleTime` UX quirk (Medium, ~4h)
Story: As a user, when I change data in one browser tab I want the other tab to converge within a predictable window.
Anchors: [reactQuery.tsx:222-224](../../frontend/src/hooks/api/reactQuery.tsx) (`refetchOnWindowFocus: false` + 60s staleTime).
Plan: reproduce two-tab staleness; write it up with the exact config lines, the design rationale (it's intentional), and options (focus refetch for specific queries, shorter staleTime, broadcast channel) with costs. File as a discussion issue, not a "bug."
Risks/Checks: none — the deliverable is the *analysis*.
Interview story potential: "Investigated a caching tradeoff and wrote a balanced proposal" — pure mid-level judgment signal.

---

Self-grading any completed ticket — **Weak**: it works on your machine. **Solid**: acceptance criteria met, `reviewable-*` clean, negative-path test included. **Strong**: PR description covers why/how-tested/risks/rollback, plus the observability trio from [05/06](../05-quality-engineering/06-observability-and-operations.md).
