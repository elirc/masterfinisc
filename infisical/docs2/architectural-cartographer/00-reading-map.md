# Reading Map

## Mental Model

Infisical is a secrets-management platform: the frontend lets a project member navigate organizations, projects, environments, folders, and secrets; React Query and Axios fetch and mutate those resources; Fastify validates/authenticates the request; services enforce business rules and persistence; encrypted secret fields live in PostgreSQL-backed schemas [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-360], [frontend/src/config/request.ts:15-44], [backend/src/server/routes/v4/secret-router.ts:47-248], [backend/src/db/schemas/secrets.ts:10-38].

## Top 10 Files To Read In Order

1. `CLAUDE.md` [CLAUDE.md:19-68]  
   Why now: it names the monorepo shape, stack, auth, DI, and API hook conventions. Understand folders before reading code. Explain after: why frontend and backend are separate packages.

2. `frontend/src/main.tsx` [frontend/src/main.tsx:1-100]  
   Why now: it is the browser boot sequence. Understand React, Vite, and TanStack Router basics. Explain after: how the app gets route context and loading UI.

3. `frontend/src/pages/root.tsx` [frontend/src/pages/root.tsx:1-35]  
   Why now: it shows global providers. Understand React context. Explain after: why every route can use React Query and notifications.

4. `frontend/src/config/request.ts` [frontend/src/config/request.ts:15-130]  
   Why now: it is the HTTP boundary. Understand Axios interceptors. Explain after: how auth tokens are attached and refreshed.

5. `frontend/src/pages/secret-manager/SecretDashboardPage/route.tsx` [frontend/src/pages/secret-manager/SecretDashboardPage/route.tsx:10-66]  
   Why now: it binds URL params/search to the secrets page. Understand route params. Explain after: how `envSlug` and `secretPath` reach the page.

6. `frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-360]  
   Why now: it is the complex UI coordinator. Understand hooks, permissions, and query params. Explain after: how permissions decide what data gets requested.

7. `frontend/src/hooks/api/dashboard/queries.tsx` [frontend/src/hooks/api/dashboard/queries.tsx:29-136]  
   Why now: it shows query-key design and dashboard API calls. Understand React Query. Explain after: why stable cache keys matter.

8. `frontend/src/hooks/api/secrets/mutations.tsx` [frontend/src/hooks/api/secrets/mutations.tsx:25-210]  
   Why now: mutations show data changing and cache invalidation. Understand optimistic vs refetch-driven UI updates. Explain after: which caches become stale after create/update/delete.

9. `backend/src/main.ts` [backend/src/main.ts:35-148]  
   Why now: it shows infrastructure boot. Understand dependency creation. Explain after: what must exist before Fastify listens.

10. `backend/src/server/routes/v4/secret-router.ts` [backend/src/server/routes/v4/secret-router.ts:47-730]  
   Why now: it is the API contract for raw secret operations. Understand Zod schema, `verifyAuth`, service calls, audit logs, telemetry. Explain after: how a secret create request moves from HTTP to service response.

## Three Most Important Data Flows

1. App boot: Vite loads `main.tsx`, builds a router with `routeTree`, passes `queryClient` in context, then renders `RouterProvider` [frontend/src/main.tsx:62-100].
2. Secret dashboard read: `SecretDashboardPage` computes project/environment/path and permission-gated include flags, then calls `useGetProjectSecretsDetails` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:157-331]; the hook calls `/api/v1/dashboard/secrets-details` [frontend/src/hooks/api/dashboard/queries.tsx:115-136].
3. Secret create: `SecretListView` calls `createSecretV3` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:187-199]; the mutation posts `/api/v4/secrets/:secretKey` and invalidates affected caches [frontend/src/hooks/api/secrets/mutations.tsx:25-89]; the backend validates, authenticates, calls `createSecretRaw`, logs audit data, sends telemetry, and returns either a secret or approval [backend/src/server/routes/v4/secret-router.ts:404-559].

## Pre-Reading Checklist

1. Can I identify frontend entry, root route, and generated route tree? Strong evidence: [frontend/src/main.tsx:12-13], [frontend/src/main.tsx:62-72].
2. Can I identify where React Query is globally installed? Strong evidence: [frontend/src/pages/root.tsx:15-22].
3. Can I explain how API auth headers are attached? Strong evidence: [frontend/src/config/request.ts:22-44].
4. Can I explain backend startup dependencies? Strong evidence: [backend/src/main.ts:52-104].
5. Can I find where Fastify plugins and routes are registered? Strong evidence: [backend/src/server/app.ts:107-201].
6. Can I find where v4 secrets routes mount? Strong evidence: [backend/src/server/routes/v4/index.ts:1-4].
7. Can I find the secret read route schema and handler? Strong evidence: [backend/src/server/routes/v4/secret-router.ts:47-248].
8. Can I find the secret create route schema and handler? Strong evidence: [backend/src/server/routes/v4/secret-router.ts:404-559].
9. Can I find persisted encrypted secret fields? Strong evidence: [backend/src/db/schemas/secrets.ts:10-38].
10. Can I name a risky frontend state area? Strong evidence: [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:301-483].

## Review Red Flags

- New API calls without query-key factories or invalidation beside existing hooks [frontend/src/hooks/api/dashboard/queries.tsx:29-88].
- Secret mutations that forget dashboard, raw secret, snapshot, commit, or approval invalidation [frontend/src/hooks/api/secrets/mutations.tsx:57-86].
- Backend routes that skip `verifyAuth` for sensitive resources [backend/src/server/routes/v4/secret-router.ts:168-168].
- Audit logs that expose encrypted metadata values instead of masking with `AUDIT_LOG_SENSITIVE_VALUE` [backend/src/server/routes/v4/secret-router.ts:515-519].
- UI permission checks that do not match backend permission expectations [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:194-248].
- More responsibilities added to `SecretDashboardPage.tsx` without extracting a hook or child component [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-1150].
- String query params not encoded like existing dashboard requests [frontend/src/hooks/api/dashboard/queries.tsx:95-130].
- Persistence changes made directly in generated schema files instead of through migrations and schema generation [backend/src/db/schemas/secrets.ts:1-4].

