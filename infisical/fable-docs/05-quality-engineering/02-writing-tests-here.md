# Writing Tests Here — Six Recipes

Commands (all from `backend/`, *inferred* from package.json): `npm run test:unit`, `npm run test:e2e`, `npm run test:e2e-watch`. E2E needs running Postgres/Redis and `.env.test` (loaded by [vitest-environment-knex.ts:27](../../backend/e2e-test/vitest-environment-knex.ts)); it boots the full server and injects globals `testServer` (Fastify) and `jwtAuthToken` (pre-authenticated user).

House style, from real specs: helpers wrap route calls and assert inside ([testUtils/secrets.ts:10-41](../../backend/e2e-test/testUtils/secrets.ts) — note `expect(...)` *inside* the helper), tests hit routes via `testServer.inject()` — never call services directly in e2e.

## Recipe 1 — Happy path (create + read back)

```ts
// Illustrative fake code: not from this repo (composed from real helpers).
import { createSecretV2, getSecretByNameV2, deleteSecretV2 } from "../../testUtils/secrets";
import { seedData1 } from "@app/db/seed-data";

test("creates and reads a secret", async () => {
  const secret = await createSecretV2({
    workspaceId: seedData1.projectV3.id, environmentSlug: "dev",
    secretPath: "/", key: "T1_KEY", value: "v1", authToken: jwtAuthToken
  });
  expect(secret.version).toBe(1);
  const read = await getSecretByNameV2({ ...sameScope, key: "T1_KEY", authToken: jwtAuthToken });
  expect(read.secretValue).toBe("v1");
  await deleteSecretV2({ ...sameScope, key: "T1_KEY", authToken: jwtAuthToken }); // cleanup!
});
```

Study a real one first: [e2e-test/routes/v3/secrets-v2.spec.ts](../../backend/e2e-test/routes/v3/secrets-v2.spec.ts). Unique key names per test — the DB is shared across the run.

## Recipe 2 — Validation failure (400, not 500)

Inject a malformed body directly (skip helpers — they assert success): missing `environment`, or a `metadataFilter` violating the max-10 rule ([secret-router.ts:104-110](../../backend/src/server/routes/v4/secret-router.ts)). Assert `statusCode === 400` **and** that the error body names the field. A 500 here is a bug worth filing.

## Recipe 3 — Permission failure (403)

Create a second identity/user with a role lacking `ProjectPermissionSecretActions.Create`, then attempt a create with its token; assert 403. The seeded data ([db/seed-data](../../backend/src/db/seed-data.ts)) and identity specs ([e2e-test/routes/v1/identity.spec.ts](../../backend/e2e-test/routes/v1/identity.spec.ts)) show how to mint scoped actors. This is the test class that catches IDOR regressions.

## Recipe 4 — Cross-tenant rejection

Two orgs, token from org A, resource ids from org B, assert 403/404 on read *and* write. Adversarial precedent to imitate: [e2e-test/routes/v3/auth-idp-attacks.spec.ts](../../backend/e2e-test/routes/v3/auth-idp-attacks.spec.ts). No secrets-focused cross-tenant spec was found — writing one is ticket J14 in [06-contribution-practice](../06-contribution-practice/01-good-first-tickets.md).

## Recipe 5 — Async side effect (replication)

Pattern from the real [secret-replication.spec.ts](../../backend/e2e-test/routes/v1/secret-replication.spec.ts): trigger the write, then poll the *observable outcome* (replicated secret appears) with a bounded retry loop rather than `sleep(5000)`. Bounded-poll beats fixed-sleep on both speed and flake rate — say that sentence in interviews.

## Recipe 6 — Pure-function unit test (the cheap layer)

Colocate `foo.test.ts` next to `foo.ts`; Vitest globals, no imports of test framework needed. Model: [lib/validator/validate-url.test.ts](../../backend/src/lib/validator/validate-url.test.ts). Candidate target with no current test: extract and test the metadataFilter parser (cases: valid pair, missing value, >10 filters, junk separators).

## Self-grade for any test you write

- **Weak**: asserts only status code; depends on other tests' data; magic sleeps.
- **Solid**: asserts response shape + a DB-visible consequence; owns its fixtures; cleans up.
- **Strong**: also covers the failure branch (403/400), names the invariant it defends in the test title, and would fail loudly (not flake) if the invariant broke.
