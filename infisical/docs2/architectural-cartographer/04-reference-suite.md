# Reference Suite

## Doc 1: Junior Onboarding Guide

Start with the repo shape in `CLAUDE.md`: frontend, backend, wasm, Docker compose, and deployment files [CLAUDE.md:19-27]. Run local dev with `.env.dev.example` copied to `.env` and `make up-dev` [./.env.dev.example:1-24], [Makefile:7-8]. Open `http://localhost:8080` because nginx maps `8080:80` [docker-compose.dev.yml:4-14]. Read frontend boot [frontend/src/main.tsx:62-100], root providers [frontend/src/pages/root.tsx:15-35], backend boot [backend/src/main.ts:35-148], and Fastify app setup [backend/src/server/app.ts:59-207].

## Doc 2: Mid-Level Architecture Guide

Use this mental path: route page -> query hook -> Axios -> Fastify route -> service -> DB schema -> audit/telemetry -> cache invalidation. The secrets dashboard computes route params and permission-gated include flags [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:157-331]. Dashboard query hooks call `/api/v1/dashboard/secrets-details` [frontend/src/hooks/api/dashboard/queries.tsx:115-136]. Secret mutations call `/api/v4/secrets/:secretKey` and invalidate caches [frontend/src/hooks/api/secrets/mutations.tsx:25-210]. The backend route validates and authenticates [backend/src/server/routes/v4/secret-router.ts:404-463], then calls secret service and records audit/telemetry [backend/src/server/routes/v4/secret-router.ts:464-558].

## Doc 3: Senior Ownership Guide

Watch the boundaries. Frontend type boundaries are `SecretV3Raw` and `SecretV3RawSanitized` [frontend/src/hooks/api/secrets/types.ts:21-82]. API-cache boundaries are query-key factories [frontend/src/hooks/api/dashboard/queries.tsx:29-88]. Backend HTTP boundaries are Zod schemas plus `verifyAuth` [backend/src/server/routes/v4/secret-router.ts:64-168]. Persistence boundaries are generated schemas and migrations, not manual schema edits [backend/src/db/schemas/secrets.ts:1-4].

## Doc 4: Code Review Guide

Review order:

1. URL and route: does TanStack route/search shape match page usage? Anchor: [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:111-160].
2. Types: does raw API data become UI data intentionally? Anchor: [frontend/src/hooks/api/secrets/queries.tsx:82-137].
3. Query keys: are cache keys specific and invalidated? Anchor: [frontend/src/hooks/api/dashboard/queries.tsx:29-88].
4. Auth: does backend route call `verifyAuth`? Anchor: [backend/src/server/routes/v4/secret-router.ts:168-168].
5. Audit: are sensitive values masked? Anchor: [backend/src/server/routes/v4/secret-router.ts:515-519].
6. DB: are generated schemas updated via migration/generation? Anchor: [backend/src/db/schemas/secrets.ts:1-4].

## Doc 5: Debugging Guide

For a UI data bug: inspect `SecretDashboardPage` query params and permissions [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:194-331], then inspect `useGetProjectSecretsDetails` query key and fetch call [frontend/src/hooks/api/dashboard/queries.tsx:282-376]. For a mutation bug: inspect `SecretListView` operation dispatch [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:110-199], then mutation URL/body and invalidation [frontend/src/hooks/api/secrets/mutations.tsx:25-210]. For a backend bug: inspect Zod route input, `verifyAuth`, service DTO, audit, telemetry [backend/src/server/routes/v4/secret-router.ts:404-558].

## Doc 6: Change Playbook

To add a secret field:

1. Create migration, run dev migration, regenerate schema because schema files are generated [backend/src/db/schemas/secrets.ts:1-4].
2. Update backend route body/response schemas near existing metadata fields [backend/src/server/routes/v4/secret-router.ts:423-452].
3. Update service DTO and persistence where `createSecretRaw`/`updateSecretRaw` handle fields [backend/src/server/routes/v4/secret-router.ts:464-481], [backend/src/server/routes/v4/secret-router.ts:628-648].
4. Update frontend raw/sanitized types [frontend/src/hooks/api/secrets/types.ts:21-82].
5. Update query transformation [frontend/src/hooks/api/secrets/queries.tsx:82-137].
6. Update row form and mutation body [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:209-231], [frontend/src/hooks/api/secrets/mutations.tsx:25-130].
7. Run `make reviewable-api` and `make reviewable-ui` [Makefile:22-32].

## Doc 7: Interview Walkthrough

Short explanation: "Infisical is a TypeScript monorepo. The frontend is a Vite React app using TanStack Router and React Query [frontend/src/main.tsx:62-100], [frontend/src/pages/root.tsx:15-35]. The backend is Fastify with Zod validation and explicit dependency wiring [backend/src/main.ts:35-104], [backend/src/server/app.ts:75-201]. The core secrets workflow starts in the dashboard, goes through typed hooks and Axios, reaches Fastify routes under `/api/v4/secrets`, calls secret services, persists encrypted fields, logs audit events, and invalidates frontend caches after mutation [frontend/src/hooks/api/secrets/mutations.tsx:25-210], [backend/src/server/routes/v4/secret-router.ts:404-558], [backend/src/db/schemas/secrets.ts:10-38]."

