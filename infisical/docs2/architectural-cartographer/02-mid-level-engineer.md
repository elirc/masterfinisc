# Mid-Level Engineer Guide

## Architecture Diagram

```text
Browser
  |
  | React 18 root + TanStack Router [frontend/src/main.tsx:62-100]
  v
Route tree + root providers
  |
  | QueryClientProvider + notifications [frontend/src/pages/root.tsx:15-23]
  v
SecretDashboardPage
  |
  | permission-gated query DTO [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:194-331]
  v
React Query hook + Axios
  |
  | /api/v1/dashboard/secrets-details [frontend/src/hooks/api/dashboard/queries.tsx:115-136]
  | /api/v4/secrets/:secretKey [frontend/src/hooks/api/secrets/mutations.tsx:25-210]
  v
Fastify app
  |
  | plugins, request context, routes [backend/src/server/app.ts:107-201]
  v
Route handler
  |
  | Zod schema + verifyAuth + service call [backend/src/server/routes/v4/secret-router.ts:404-481]
  v
Service + DAL + DB
  |
  | encrypted secret fields [backend/src/db/schemas/secrets.ts:10-38]
  v
Audit log / telemetry / response
```

## Type System Deep Dive

The raw secret API type uses backend vocabulary: `secretKey`, `secretValue`, `secretPath`, `secretValueHidden`, `type`, and encryption-aware metadata [frontend/src/hooks/api/secrets/types.ts:56-82]. The dashboard type normalizes that into UI vocabulary: `key`, `value`, `path`, `env`, `valueOverride`, `pendingAction`, and display-only flags [frontend/src/hooks/api/secrets/types.ts:21-54]. This split lets the HTTP layer preserve server contract shape while the UI renders an ergonomic model.

Annotated transformation:

```ts
const decryptedSecret: SecretV3RawSanitized = {
  id: el.id, // stable row identity from API
  env: el.environment, // backend name becomes dashboard env
  key: el.secretKey, // API key name becomes UI key
  value: el.secretValueHidden ? HIDDEN_SECRET_VALUE : el.secretValue, // permission-sensitive masking
  secretValueHidden: el.secretValueHidden, // keep original permission signal
  path: el.secretPath, // folder path survives normalization
  secretMetadata: el.secretMetadata // metadata stays attached to the secret
};
```

Source: [frontend/src/hooks/api/secrets/queries.tsx:82-137].

## State Management Deep Dive

The most important local state is batch pending changes. It uses Zustand with typed unions for pending secret creates, updates, deletes, folder creates, folder updates, and folder deletes [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:15-108]. The dashboard overlays pending changes onto fetched data so a user can review changes before commit [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-781].

The design intent is similar to staging secrets before opening the vault door: fetched server state is the actual vault inventory, while `pendingChanges` is a staging clipboard. The clipboard blocks navigation when non-empty [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:90-103].

## API Contract Map

- `GET /api/v1/dashboard/secrets-overview`: dashboard overview list; frontend builds params and encodes environment/tag lists [frontend/src/hooks/api/dashboard/queries.tsx:90-113].
- `GET /api/v1/dashboard/secrets-details`: detailed folder/environment view; frontend sends pagination, filters, and tags [frontend/src/hooks/api/dashboard/queries.tsx:115-136].
- `GET /api/v4/secrets`: raw secrets route with metadata filters, project/environment/path, visibility, imports, recursion, personal overrides, and tags [backend/src/server/routes/v4/secret-router.ts:47-168].
- `POST /api/v4/secrets/:secretKey`: create raw secret; frontend posts body fields [frontend/src/hooks/api/secrets/mutations.tsx:25-55], backend validates and calls `createSecretRaw` [backend/src/server/routes/v4/secret-router.ts:404-481].
- `PATCH /api/v4/secrets/:secretKey`: update secret; frontend patch body includes rename, value, tags, reminder, metadata [frontend/src/hooks/api/secrets/mutations.tsx:91-130], backend validates and calls `updateSecretRaw` [backend/src/server/routes/v4/secret-router.ts:562-648].
- `DELETE /api/v4/secrets/:secretKey`: delete secret; frontend sends `projectId`, `environment`, `type`, `secretPath`, and `secretId` in request body [frontend/src/hooks/api/secrets/mutations.tsx:170-210].

## Component Interaction Map

`SecretDashboardPage` owns route params, permission checks, filters, pagination, data fetching, pending merge, and child rendering [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-360], [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-1150]. It passes `mergedSecrets` to `SecretListView` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1101-1113]. `SecretListView` owns create/update/delete mutation calls and navigation blocking [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:79-103]. `SecretItem` owns form state and auto-save behavior for an individual row [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:209-297].

## Full-Stack Feature Trace: Create Secret

1. UI operation starts in `SecretListView.handleSecretOperation`; for create, it calls `createSecretV3` with `environment`, `projectId`, `secretPath`, `secretKey`, `secretValue`, and `type` [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:187-199].
2. The mutation posts to `/api/v4/secrets/${encodeURIComponent(secretKey)}` and sends the secret fields in JSON [frontend/src/hooks/api/secrets/mutations.tsx:25-55].
3. On success, the mutation invalidates dashboard, imported secret, raw secret, snapshot, commit, and approval request caches [frontend/src/hooks/api/secrets/mutations.tsx:57-86].
4. Axios attaches `Authorization` unless the caller already supplied it [frontend/src/config/request.ts:22-44].
5. Backend route validates params/body with Zod and requires JWT, service token, or identity access token auth [backend/src/server/routes/v4/secret-router.ts:404-463].
6. Handler calls `server.services.secret.createSecretRaw` with actor, org, environment, project, path, value, tags, reminder, and metadata [backend/src/server/routes/v4/secret-router.ts:464-481].
7. If protection policy returns approval, the route logs `SECRET_APPROVAL_REQUEST` and returns approval [backend/src/server/routes/v4/secret-router.ts:482-500].
8. Otherwise, the route logs `CREATE_SECRET`, masks encrypted metadata values in audit metadata, sends telemetry, and returns `{ secret }` [backend/src/server/routes/v4/secret-router.ts:503-558].
9. Secret persistence uses encrypted key/value/comment ciphertext, IV, and tag columns in the generated schema [backend/src/db/schemas/secrets.ts:14-23].

## Diff Reading Exercise

Hypothetical change: "Add a `secretOwner` field to secrets."

Read the diff in this order:

1. Backend schema/migration: is generated schema updated through migration and `generate:schema`, not hand-edited? Generated warning: [backend/src/db/schemas/secrets.ts:1-4].
2. Backend route DTO: is `secretOwner` validated in create/update body near existing metadata fields? Existing create body: [backend/src/server/routes/v4/secret-router.ts:423-452].
3. Service: is the field persisted and returned consistently from `createSecretRaw`/`updateSecretRaw`? Service dependencies and factory boundary: [backend/src/services/secret/secret-service.ts:109-148].
4. Frontend types: is raw and sanitized type shape updated? Existing raw/sanitized split: [frontend/src/hooks/api/secrets/types.ts:21-82].
5. UI: is the field displayed or edited in `SecretItem` form state? Existing form setup: [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:209-231].
6. Cache invalidation: does create/update still invalidate all views where owner appears? Existing invalidation: [frontend/src/hooks/api/secrets/mutations.tsx:57-86].

## Non-Obvious Patterns

- Query keys are domain APIs, not incidental arrays; this makes invalidation reviewable [frontend/src/hooks/api/dashboard/queries.tsx:29-88].
- Server services are accessed through Fastify decoration instead of direct route imports, which keeps route files focused on HTTP contract and service call shape [backend/src/server/routes/v4/secret-router.ts:184-204].
- Audit logging lives in the route after service success, so reviewers must verify it alongside each route behavior change [backend/src/server/routes/v4/secret-router.ts:503-523].
- The UI can intentionally fetch less data based on permission checks, reducing forbidden or unnecessary backend calls [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:194-331].

## Mid-Level Socratic Checkpoint

Questions:

1. Why are dashboard query keys built from `projectId`, `secretPath`, environment, filters, and params?
2. What makes `SecretV3Raw` different from `SecretV3RawSanitized`?
3. Why does a secret create invalidate more than one cache?
4. Where does the backend enforce authentication for v4 secrets?
5. How does the route avoid leaking encrypted metadata values into audit logs?
6. Why can service-token scope override user-supplied `projectId`/`environment`/`secretPath`?
7. What local state can diverge from server state before commit?
8. Where would you add a new field so it survives UI, API, service, and DB boundaries?

How to self-grade: strong answers cite [frontend/src/hooks/api/dashboard/queries.tsx:29-88], [frontend/src/hooks/api/secrets/types.ts:21-82], [frontend/src/hooks/api/secrets/mutations.tsx:57-86], [backend/src/server/routes/v4/secret-router.ts:168-168], [backend/src/server/routes/v4/secret-router.ts:515-519], [backend/src/server/routes/v4/secret-router.ts:170-182], [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:15-108], and [backend/src/db/schemas/secrets.ts:10-38].

