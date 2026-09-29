# Senior Engineer Guide

## Architectural Critique

- Scalability: 4/5. Backend dependency injection is explicit and infrastructure is built before server listen [backend/src/main.ts:35-145], but the central route/service graph is very large [backend/src/server/routes/index.ts:1783-2068].
- TypeScript discipline: 4/5. Frontend and backend contracts use typed DTOs and Zod schemas [frontend/src/hooks/api/secrets/types.ts:21-180], [backend/src/server/routes/v4/secret-router.ts:64-166]. Risk remains where `any` appears in pending folder merge [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:789-801].
- Separation of concerns: 3/5. Backend route files combine contract, auth, service call, audit, and telemetry [backend/src/server/routes/v4/secret-router.ts:404-558]. Frontend dashboard combines many responsibilities in one page [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-1150].
- Testability: 3/5. Backend has unit/e2e scripts [backend/package.json:15-18], but the large dashboard component would benefit from extracted pure helpers around pending merge [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-837].
- Maintainability: 3/5. Query-key factories and explicit invalidation are maintainable [frontend/src/hooks/api/dashboard/queries.tsx:29-88], but every mutation has broad invalidation that can drift [frontend/src/hooks/api/secrets/mutations.tsx:57-210].
- Security posture: 4/5. Auth is explicit, request tokens refresh centrally, and audit masks encrypted metadata [frontend/src/config/request.ts:22-130], [backend/src/server/routes/v4/secret-router.ts:168-168], [backend/src/server/routes/v4/secret-router.ts:515-519]. Review CORS exceptions carefully [backend/src/server/app.ts:114-144].
- Performance: 3/5. React Query placeholder data and cache keys help [frontend/src/hooks/api/dashboard/queries.tsx:312-376], but large page-level recomputation and broad cache invalidation can cause avoidable refetches [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-839].

## Performance Audit

Finding: `getMergedSecretsWithPending` rebuilds arrays and applies every pending change during render [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-781]. Corrected shape:

```tsx
const mergedSecrets = useMemo(
  () => getMergedSecretsWithPending(),
  [isBatchMode, pendingChanges.secrets, secrets, projectId]
); // memoize derived rows so unrelated renders do less work
```

Finding: mutation success invalidates several caches separately [frontend/src/hooks/api/secrets/mutations.tsx:57-86]. Corrected shape:

```ts
const invalidateSecretScope = ({ projectId, environment, secretPath }) => {
  // centralize invalidation so create/update/delete cannot drift
  queryClient.invalidateQueries({ queryKey: dashboardKeys.getDashboardSecrets({ projectId, secretPath }) });
  queryClient.invalidateQueries({ queryKey: secretKeys.getProjectSecret({ projectId, environment, secretPath }) });
};
```

## Security Audit

Finding: CORS intentionally allows permissive origin for MCP OAuth routes [backend/src/server/app.ts:114-129]. This is acceptable only while route matching remains narrow. Safer review pattern:

```ts
const isMcpOAuthRoute =
  req.url.startsWith("/.well-known/oauth-protected-resource") ||
  req.url.startsWith("/.well-known/oauth-authorization-server") ||
  req.url.startsWith("/mcp-endpoints/") ||
  (req.url.includes("/ai/mcp/endpoints/") && req.url.includes("/oauth/"));
// keep this list explicit; do not replace it with a broad "/oauth" match
```

Finding: audit logs correctly mask encrypted metadata values [backend/src/server/routes/v4/secret-router.ts:515-519]. Maintain this invariant when adding fields:

```ts
value: meta.isEncrypted ? AUDIT_LOG_SENSITIVE_VALUE : meta.value
// never log encrypted metadata plaintext into audit metadata
```

## TypeScript Discipline Review

Strengths: discriminated unions model pending secret/folder changes [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:21-108], and Zod schemas validate HTTP input/output [backend/src/server/routes/v4/secret-router.ts:64-166].

Weaknesses: the dashboard pending folder create casts to `any` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:793-801]. Replace that with a typed view model so render-only pending folders do not escape as real backend folders.

## Custom Abstractions Inventory

- `apiRequest`: Axios instance with auth injection, refresh deduplication, redirect preservation [frontend/src/config/request.ts:15-130].
- `dashboardKeys` and `secretKeys`: query-key factories for cache ownership [frontend/src/hooks/api/dashboard/queries.tsx:29-88], [frontend/src/hooks/api/secrets/queries.tsx:33-58].
- `verifyAuth`: route-level auth gate used by v4 secret routes [backend/src/server/routes/v4/secret-router.ts:168-168].
- Fastify request context: per-request id, logger, IP, user-agent, and memoizer [backend/src/server/app.ts:170-178].
- Generated DB schemas: generated Zod types from database schema [backend/src/db/schemas/secrets.ts:1-38].

## Testing Assessment And Runnable Test

Risky untested behavior: frontend duplicate/merge logic for pending secret updates can drift from backend constraints [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:322-483].

Proposed runnable unit test file:

```ts
// frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.test.tsx
import { describe, expect, it } from "vitest";
import { PendingAction } from "@app/hooks/api/secretFolders/types";

describe("secret pending changes", () => {
  it("removes an update when fields are reverted to their original values", () => {
    // Build a store with an existing key, add an update, then add a reverted update.
    // Assert pendingChanges.secrets is empty.
  });
});
```

This test should be implemented after extracting store creation helpers from `SecretMainPage.store.tsx`, because the current store is context-coupled [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:1-13].

## Bug Injection Exercise

Do not edit production code. Use these as test scenarios:

1. Symptom: after creating a secret, the dashboard list does not update until refresh. Scenario: remove dashboard invalidation and assert stale UI [frontend/src/hooks/api/secrets/mutations.tsx:57-60].
2. Symptom: a user without edit permission sees editable secret values. Scenario: break `canEditSecretValue` in `SecretItem` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:175-183].
3. Symptom: service-token reads secrets outside its scoped path. Scenario: bypass service-token scope normalization [backend/src/server/routes/v4/secret-router.ts:170-182].
4. Symptom: encrypted metadata appears in audit logs. Scenario: log `meta.value` unconditionally [backend/src/server/routes/v4/secret-router.ts:515-519].
5. Symptom: expired sessions trigger many refresh calls. Scenario: remove `refreshPromise` deduplication [frontend/src/config/request.ts:52-88].

## Git History Learning Exercise

1. `feat(secrets): add v4 secret metadata filters` implies review of Zod transform/refinement [backend/src/server/routes/v4/secret-router.ts:64-124].
2. `fix(auth): dedupe token refresh retries` implies concurrency around `refreshPromise` [frontend/src/config/request.ts:52-88].
3. `perf(dashboard): memoize pending secret merge` implies render hot path in dashboard [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-839].
4. `refactor(api): centralize secret cache invalidation` implies repeated mutation invalidation [frontend/src/hooks/api/secrets/mutations.tsx:57-210].
5. `security(audit): mask encrypted secret metadata` implies audit-log payload review [backend/src/server/routes/v4/secret-router.ts:515-519].

## If I Owned This Codebase

- Extract dashboard query/filter state into a hook. Effort: M. Impact: high. Anchor: [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-360].
- Centralize secret mutation invalidation. Effort: S. Impact: medium. Anchor: [frontend/src/hooks/api/secrets/mutations.tsx:57-210].
- Extract pending-change merge into pure tested utilities. Effort: M. Impact: high. Anchor: [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-837].
- Add route-level audit helper for secret metadata masking. Effort: S. Impact: medium. Anchor: [backend/src/server/routes/v4/secret-router.ts:503-558].
- Add contract tests for v4 secret route schemas. Effort: M. Impact: high. Anchor: [backend/src/server/routes/v4/secret-router.ts:47-730].

