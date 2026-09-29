# Journal

## Mission Design Rationale

The missions are ordered from "where does the app start?" to "how do I own and change the system safely?" The chosen spine is secrets management because it crosses routing, permissions, state, typed API calls, Fastify validation, service boundaries, audit logs, telemetry, and encrypted persistence [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-360], [frontend/src/hooks/api/secrets/mutations.tsx:25-210], [backend/src/server/routes/v4/secret-router.ts:404-730], [backend/src/db/schemas/secrets.ts:10-38].

## Why This Order

Missions 1-8 teach navigation and syntax: boot, folders, TypeScript, components, routes, props, data, and navigation. Missions 9-17 teach system behavior: state, hooks, side effects, API contracts, middleware, full-stack tracing, diff reading, composition, and hidden TypeScript work. Missions 18-24 teach ownership: architecture inference, bug prediction, performance, security, missing tests, and git-story thinking.

## Code Paths Chosen

- App heartbeat: `frontend/src/main.tsx` and `backend/src/main.ts` [frontend/src/main.tsx:62-100], [backend/src/main.ts:35-148].
- API boundary: `frontend/src/config/request.ts` [frontend/src/config/request.ts:15-130].
- Secrets dashboard: `SecretDashboardPage.tsx`, `SecretListView.tsx`, and `SecretItem.tsx` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-1150], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:79-199], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:209-297].
- Backend secrets route: `backend/src/server/routes/v4/secret-router.ts` [backend/src/server/routes/v4/secret-router.ts:47-730].
- Persistence: generated secrets schema [backend/src/db/schemas/secrets.ts:10-38].

## Senior Behavior At Checkpoints

A senior engineer answers with evidence, then names the risk. For example, if asked "Where does secret create update the UI?" a senior cites mutation invalidation [frontend/src/hooks/api/secrets/mutations.tsx:57-86] and adds: "This is broad invalidation; I would centralize it before adding many more secret mutations."

