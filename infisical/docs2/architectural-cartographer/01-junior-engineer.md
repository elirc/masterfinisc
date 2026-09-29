# Junior Engineer Guide

## Local Setup

The fastest reconstructed dev setup is Docker compose. The Makefile exposes `make up-dev`, which runs `docker compose -f docker-compose.dev.yml up --build` [Makefile:7-8]. The dev compose stack starts nginx on `localhost:8080`, Postgres on `5432`, Redis on `6379`, backend on `4000`, and frontend behind nginx [docker-compose.dev.yml:4-19], [docker-compose.dev.yml:27-35], [docker-compose.dev.yml:94-120], [docker-compose.dev.yml:158-170]. Environment values can be copied from `.env.dev.example`; it includes sample `ENCRYPTION_KEY`, `AUTH_SECRET`, `DB_CONNECTION_URI`, `REDIS_URL`, and `SITE_URL=http://localhost:8080` [./.env.dev.example:1-24].

Commands:

```powershell
copy .env.dev.example .env
make up-dev
```

For package-level work, frontend scripts include `dev`, `build`, `lint`, and `type:check` [frontend/package.json:7-14]. Backend scripts include `dev`, `build`, `type:check`, `lint`, `test:unit`, `test:e2e`, migrations, and seeds [backend/package.json:7-44]. The root Makefile exposes `make reviewable-ui` and `make reviewable-api` for lint-fix plus type-check [Makefile:22-32].

## Folder Orientation

Frontend top-level folders include `components`, `config`, `context`, `hooks`, `layouts`, `lib`, `pages`, `types`, and `views` [terminal inspection: frontend/src directory listing]. Backend top-level folders include `db`, `ee`, `keystore`, `lib`, `queue`, `server`, and `services` [terminal inspection: backend/src directory listing].

Frontend folders to read first:

- `frontend/src/pages`: route-owned page screens; the secrets dashboard lives at `pages/secret-manager/SecretDashboardPage` [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-1150].
- `frontend/src/hooks/api`: typed API hooks; dashboard query and secret mutation conventions are visible in [frontend/src/hooks/api/dashboard/queries.tsx:29-136] and [frontend/src/hooks/api/secrets/mutations.tsx:25-210].
- `frontend/src/config`: shared request setup; Axios auth/refresh behavior lives in [frontend/src/config/request.ts:15-130].

Backend folders to read first:

- `backend/src/server`: Fastify app, plugins, and route registration [backend/src/server/app.ts:59-207].
- `backend/src/services`: business logic factories; secrets service dependencies are listed in [backend/src/services/secret/secret-service.ts:109-148].
- `backend/src/db`: Knex setup, migrations, seeds, and generated schemas; the secrets schema is generated and warns not to edit manually [backend/src/db/schemas/secrets.ts:1-4].

## Frontend Entry Point

```tsx
const router = createRouter({
  routeTree, // generated route tree imported from ./routeTree.gen
  context: { serverConfig: null, queryClient }, // route loaders can share React Query
  defaultPendingComponent: () => ( // global loading fallback
    <div className="flex h-full w-full items-center justify-center bg-bunker-800 [#root>&]:h-screen">
      <Lottie isAutoPlay icon="infisical_loading" className="h-32 w-32" />
    </div>
  ),
  defaultNotFoundComponent: NotFoundPage, // route miss
  defaultErrorComponent: ErrorPage // route error
});
```

Source: [frontend/src/main.tsx:62-72].

```tsx
root.render(
  <StrictMode>
    <RouterProvider router={router} /> {/* browser app starts here */}
  </StrictMode>
);
```

Source: [frontend/src/main.tsx:92-100].

## Backend Entry Point

```ts
const db = initDbConnection({ // database is created before server
  dbConnectionUri: databaseCredentials.dbConnectionUri,
  dbRootCert: databaseCredentials.dbRootCert,
  readReplicas: databaseCredentials.readReplicas
});

await runMigrations({ applicationDb: db, auditLogDb, clickhouseClient: clickhouse, logger });
// schema is migrated before HTTP traffic begins

const server = await main({ db, auditLogDb, smtp, logger, queue, keyStore, redis, clickhouse, envConfig });
// all core dependencies are injected into the Fastify app factory
```

Source: [backend/src/main.ts:52-104].

```ts
await server.register(registerRoutes, {
  smtp, queue, db, auditLogDb, keyStore, redis, clickhouse, hsmService, envConfig, superAdminDAL, kmsRootConfigDAL
}); // route graph receives service dependencies
```

Source: [backend/src/server/app.ts:180-192].

## TypeScript Orientation

The frontend raw secret type mirrors backend API fields such as `secretKey`, `secretValue`, `secretPath`, and `secretValueHidden` [frontend/src/hooks/api/secrets/types.ts:56-82]. The UI-friendly type renames those into `key`, `value`, `path`, and `env` [frontend/src/hooks/api/secrets/types.ts:21-54]. Think of raw secrets as sealed envelopes from the vault, and sanitized secrets as labeled cards the dashboard can sort, edit, and render.

## Component Anatomies

### Simple Component: Root Provider

```tsx
const RootPage = () => {
  return (
    <QueryClientProvider client={queryClient}> {/* API cache for the whole app */}
      <TooltipProvider> {/* shared tooltip behavior */}
        <Outlet /> {/* active route renders here */}
        <NotificationContainer /> {/* global toast/notification mount */}
      </TooltipProvider>
    </QueryClientProvider>
  );
};
```

Source: [frontend/src/pages/root.tsx:15-23].

### Complex Component: Secrets Dashboard Query Setup

```tsx
const {
  data,
  isPending: isDetailsLoading,
  isFetching: isDetailsFetching,
  isFetched
} = useGetProjectSecretsDetails({
  environment, // route param
  projectId, // current project context
  secretPath, // query param folder path
  offset,
  limit,
  orderBy,
  search: debouncedSearchFilter,
  orderDirection,
  includeImports: canReadSecretImports && (isResourceTypeFiltered ? filter.include.import : true),
  includeFolders: isResourceTypeFiltered ? filter.include.folder : true,
  includeDynamicSecrets: canReadDynamicSecret && (isResourceTypeFiltered ? filter.include.dynamic : true),
  includeSecrets: canReadSecret && (isResourceTypeFiltered ? filter.include.secret : true),
  includeSecretRotations: canReadSecretRotations && (isResourceTypeFiltered ? filter.include.rotation : true),
  includeHoneyTokens: true,
  tags: filter.tags
});
```

Source: [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:307-331].

### Row/List Component: Secret Operations

```tsx
const { mutateAsync: createSecretV3 } = useCreateSecretV3({ options: { onSuccess: undefined } });
const { mutateAsync: updateSecretV3 } = useUpdateSecretV3({ options: { onSuccess: undefined } });
const { mutateAsync: deleteSecretV3 } = useDeleteSecretV3({ options: { onSuccess: undefined } });
// the list view owns immediate CRUD calls and disables default mutation side effects
```

Source: [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:79-88].

## Backend Route Anatomies

### Read Many Secrets

```ts
server.route({
  method: "GET",
  url: "/",
  schema: { querystring: z.object({ projectId: z.string().trim().optional(), environment: z.string().trim().optional() }) },
  onRequest: verifyAuth([AuthMode.JWT, AuthMode.SERVICE_TOKEN, AuthMode.IDENTITY_ACCESS_TOKEN]),
  handler: async (req, reply) => {
    // validate auth, normalize service-token scope, then call the secret service
  }
});
```

Source: [backend/src/server/routes/v4/secret-router.ts:47-248].

### Create Secret

```ts
server.route({
  method: "POST",
  url: "/:secretName",
  schema: { body: z.object({ projectId: z.string().trim(), environment: z.string().trim(), secretValue: z.string() }) },
  onRequest: verifyAuth([AuthMode.JWT, AuthMode.SERVICE_TOKEN, AuthMode.IDENTITY_ACCESS_TOKEN]),
  handler: async (req) => {
    const secretOperation = await server.services.secret.createSecretRaw({ /* DTO from params/body/permission */ });
    // route returns either an approval request or the created secret
  }
});
```

Source: [backend/src/server/routes/v4/secret-router.ts:404-559].

### Update Secret

```ts
server.route({
  method: "PATCH",
  url: "/:secretName",
  schema: { body: z.object({ newSecretName: SecretNameSchema.optional(), secretComment: z.string().optional() }) },
  handler: async (req) => {
    const secretOperation = await server.services.secret.updateSecretRaw({ /* update fields */ });
    // audit and telemetry happen after service success
  }
});
```

Source: [backend/src/server/routes/v4/secret-router.ts:562-730].

## Domain Glossary

- Organization: top-level account context; the dashboard reads `currentOrg` before navigation [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-110].
- Project: workspace container for secret management; the page reads `currentProject` and checks project version [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:106-107], [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:842-847].
- Environment: route parameter such as dev/prod used in secret queries [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:114-117].
- Secret path: folder-like path for secrets, defaulting to `/` in UI and backend schemas [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:157-160], [backend/src/server/routes/v4/secret-router.ts:127-127].
- Secret: encrypted key/value resource; stored as ciphertext, IV, and tag fields [backend/src/db/schemas/secrets.ts:14-23].
- Personal override: a personal secret stitched onto a shared secret in `mergePersonalSecrets` [frontend/src/hooks/api/secrets/queries.tsx:82-137].

## Junior Socratic Checkpoint

Questions:

1. Which file first renders the React app?
2. Where is React Query installed globally?
3. Which file attaches `Authorization` headers to API requests?
4. Which backend file starts database connections and migrations?
5. Which backend file registers global Fastify plugins?
6. What endpoint does `useCreateSecretV3` call?
7. Where are encrypted secret fields represented?

How to self-grade: strong answers cite [frontend/src/main.tsx:92-100], [frontend/src/pages/root.tsx:15-23], [frontend/src/config/request.ts:22-44], [backend/src/main.ts:52-104], [backend/src/server/app.ts:107-201], [frontend/src/hooks/api/secrets/mutations.tsx:25-55], and [backend/src/db/schemas/secrets.ts:10-38].

