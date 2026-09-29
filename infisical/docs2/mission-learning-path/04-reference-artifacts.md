# Mission 25: Write the Docs That Don't Exist

## Doc 1: Junior Onboarding Checklist

- Copy `.env.dev.example` to `.env`; it contains required sample keys and local URLs [./.env.dev.example:1-24].
- Run `make up-dev`; it runs Docker compose dev with build [Makefile:7-8].
- Open the app at `localhost:8080` because nginx maps `8080:80` [docker-compose.dev.yml:4-14].
- First PR checklist: read `frontend/src/main.tsx`, `frontend/src/pages/root.tsx`, `backend/src/main.ts`, and `backend/src/server/app.ts` [frontend/src/main.tsx:62-100], [frontend/src/pages/root.tsx:15-35], [backend/src/main.ts:35-148], [backend/src/server/app.ts:59-207].

## Doc 2: Architecture Guide For New Engineers

Navigate by layers: page -> API hook -> Axios -> Fastify route -> service -> schema. For secrets, start at dashboard query setup [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:307-331], then dashboard fetch [frontend/src/hooks/api/dashboard/queries.tsx:115-136], then mutation hooks [frontend/src/hooks/api/secrets/mutations.tsx:25-210], then backend v4 secret route [backend/src/server/routes/v4/secret-router.ts:47-730].

## Doc 3: Code Review Checklist

- Does the frontend type reflect the backend response? [frontend/src/hooks/api/secrets/types.ts:21-82]
- Does the hook call the expected endpoint? [frontend/src/hooks/api/secrets/queries.tsx:60-80]
- Does mutation invalidation cover every affected view? [frontend/src/hooks/api/secrets/mutations.tsx:57-210]
- Does backend route validate and authenticate? [backend/src/server/routes/v4/secret-router.ts:404-463]
- Does audit logging mask encrypted metadata? [backend/src/server/routes/v4/secret-router.ts:515-519]

## Doc 4: Debugging Playbook

1. Stale UI: inspect mutation invalidation [frontend/src/hooks/api/secrets/mutations.tsx:57-210].
2. Missing data: inspect permission-gated include flags [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:194-331].
3. Unauthorized error: inspect token injection/refresh [frontend/src/config/request.ts:22-130].
4. Backend 400: inspect Zod route schema [backend/src/server/routes/v4/secret-router.ts:64-166].
5. Wrong stored shape: inspect generated schema and migration path [backend/src/db/schemas/secrets.ts:1-38].

## Doc 5: Change Playbook

Branch, implement, verify, review, merge:

1. Add/modify route or service with explicit DTO and schema [backend/src/server/routes/v4/secret-router.ts:404-648].
2. Update frontend types and hooks [frontend/src/hooks/api/secrets/types.ts:21-180], [frontend/src/hooks/api/secrets/mutations.tsx:25-210].
3. Update UI component props and render paths [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:37-70].
4. Run reviewable commands [Makefile:22-32].

## Doc 6: Senior Ownership Notes

Monitor broad cache invalidation [frontend/src/hooks/api/secrets/mutations.tsx:57-210], dashboard responsibility growth [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-1150], route audit/telemetry consistency [backend/src/server/routes/v4/secret-router.ts:503-558], and generated schema discipline [backend/src/db/schemas/secrets.ts:1-4].

## Doc 7: Interview Walkthrough

Practice answer: "I worked in a TypeScript security platform where the frontend was React/Vite with TanStack Router and React Query [frontend/src/main.tsx:62-100], [frontend/src/pages/root.tsx:15-35]. The backend was Fastify with Zod route schemas, explicit dependency injection, PostgreSQL via Knex, and route-level auth [backend/src/main.ts:35-104], [backend/src/server/app.ts:75-201]. I traced a secret create from `SecretListView` through `useCreateSecretV3`, Axios auth, the v4 Fastify route, service call, audit/telemetry, and encrypted DB schema [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:187-199], [frontend/src/hooks/api/secrets/mutations.tsx:25-89], [backend/src/server/routes/v4/secret-router.ts:404-559], [backend/src/db/schemas/secrets.ts:10-38]."

