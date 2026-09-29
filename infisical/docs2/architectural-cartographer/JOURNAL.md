# Journal

## First-Pass Mental Model

This repo is a monorepo with a React 18/Vite frontend and a Fastify 4 TypeScript backend. The root repo identifies `frontend/`, `backend/`, `wasm/`, Docker compose files, and standalone deployment Dockerfiles as major areas [CLAUDE.md:19-27]. The backend is described locally as Fastify 4 with TypeScript, PostgreSQL through Knex, and BullMQ queues [backend/CLAUDE.md:5-15]. The frontend stack is Vite, TanStack Router, React Query, and Tailwind according to the root architecture notes [CLAUDE.md:33-35].

## Important Discoveries

- Frontend boot is compact: `createRouter` receives generated `routeTree`, a `queryClient`, default pending UI, and error/not-found components [frontend/src/main.tsx:62-72].
- Frontend root wraps all route content in `QueryClientProvider`, `TooltipProvider`, and `NotificationContainer`, so query cache and global notifications are available to pages below it [frontend/src/pages/root.tsx:15-35].
- Backend startup builds infrastructure first: logger, HSM, database, migrations, SMTP, queue, key store, Redis, then passes those dependencies into `main` [backend/src/main.ts:35-104].
- The Fastify app factory registers validation/serialization, cookies, CORS, ETag, Swagger, form body, websocket, error handling, security headers, request context, routes, and UI serving [backend/src/server/app.ts:75-201].
- API route registration is centralized: v4 routes mount `registerSecretRouter` at `/api/v4/secrets` [backend/src/server/routes/index.ts:3591-3591] and [backend/src/server/routes/v4/index.ts:1-4].
- The secrets feature has a full teaching path: page state and permissions in `SecretDashboardPage`, React Query hooks in `dashboard/queries.tsx` and `secrets/queries.tsx`, mutations in `secrets/mutations.tsx`, validation/auth in `secret-router.ts`, and encrypted persistence fields in `db/schemas/secrets.ts` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-360], [frontend/src/hooks/api/dashboard/queries.tsx:29-136], [frontend/src/hooks/api/secrets/mutations.tsx:25-89], [backend/src/server/routes/v4/secret-router.ts:404-559], [backend/src/db/schemas/secrets.ts:10-38].

## Why These Teaching Anchors

I chose the secrets dashboard because it is the domain center of Infisical: projects hold environments, environments hold folders, folders contain secrets, and users or identities need permission to read, edit, or delete those secrets. That model is visible in the dashboard permissions [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:194-248], the query parameters sent to the details endpoint [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:307-331], and the backend v4 route validation/auth [backend/src/server/routes/v4/secret-router.ts:64-168].

## Where A Junior Might Get Confused

- Generated routing can feel invisible because `routeTree.gen.ts` is imported rather than hand-written [frontend/src/main.tsx:12-13].
- React Query cache keys are arrays built by factories, not plain strings [frontend/src/hooks/api/dashboard/queries.tsx:29-88].
- The backend service graph is wired centrally, so route files often call `server.services.*` without importing the implementation directly [backend/src/server/routes/v4/secret-router.ts:184-204].

## Where A Mid-Level Engineer Should Slow Down

- Query invalidation is part of correctness. Creating a secret invalidates dashboard, imported secret, raw secret, snapshot, commit, and approval request caches [frontend/src/hooks/api/secrets/mutations.tsx:57-86].
- The dashboard fetch is permission-aware before the HTTP call: it includes secrets, folders, imports, dynamic secrets, and rotations based on CASL checks [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:194-331].
- Service tokens can narrow `projectId`, `environment`, and `secretPath` from token scope, which changes how route inputs are trusted [backend/src/server/routes/v4/secret-router.ts:170-182].

## Where A Senior Engineer Should Be Skeptical

- `SecretDashboardPage.tsx` owns routing state, permissions, filtering, querying, pending-change merging, rendering, and pagination in one large component [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-1150].
- `SecretMainPage.store.tsx` contains domain merge logic and duplicate detection in frontend state; this is useful but risky if it diverges from backend validation [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:301-483].
- Backend route handlers combine validation, service calls, audit logs, and telemetry; that is explicit, but changes need careful audit-log coverage [backend/src/server/routes/v4/secret-router.ts:464-558].

## How To Use Checkpoints

Use each checkpoint as an oral exam. A strong answer names files, line ranges, inputs, outputs, and failure modes. If your answer cannot point to a line range such as [frontend/src/hooks/api/secrets/queries.tsx:60-80] or [backend/src/server/routes/v4/secret-router.ts:404-481], treat that as a signal to reopen the code.

