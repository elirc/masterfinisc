### Mission 1: The App's Heartbeat
**Tier:** Junior
**Time Estimate:** 30 minutes
**Goal:** Find where the frontend and backend start.
**The Concept:** Every app has a heartbeat: browser boot and server boot. In Infisical, this is like opening the vault lobby and starting the vault machinery.
**Design Intent Before You Read the Code:** Frontend boot should create routing and render React; backend boot should create infrastructure before listening.
**Find It In The Code:** Open [frontend/src/main.tsx:62-100] and [backend/src/main.ts:35-148].

```tsx
const router = createRouter({ // create the navigation brain
  routeTree, // generated map of pages
  context: { serverConfig: null, queryClient }, // shared loader/query context
  defaultPendingComponent: () => <div>...</div> // fallback while routes load
});
root.render(<RouterProvider router={router} />); // mount app into #root
```

```ts
const db = initDbConnection({ ... }); // connect before serving requests
await runMigrations({ applicationDb: db, auditLogDb, clickhouseClient: clickhouse, logger }); // schema readiness
const server = await main({ db, auditLogDb, smtp, logger, queue, keyStore, redis, clickhouse, envConfig }); // inject dependencies
await server.listen({ port: envConfig.PORT, host: envConfig.HOST }); // heartbeat begins
```

**The Aha Moment:** The frontend starts by routing; the backend starts by dependency assembly.
**Socratic Checkpoint:** What creates the router? What renders React? What runs migrations? What listens on a port? Why before/after order matters?
How to self-grade: strong answers cite [frontend/src/main.tsx:62-100] and [backend/src/main.ts:52-145].
**Connects To:** Mission 2 and Mission 8, because folder shape and navigation explain where heartbeat code leads.

### Mission 2: The Folder Mental Map
**Tier:** Junior
**Time Estimate:** 25 minutes
**Goal:** Build a first mental map of frontend and backend folders.
**The Concept:** Folders are neighborhoods. In Infisical, `pages` is where users walk; `services` is where vault rules live.
**Design Intent Before You Read the Code:** Top-level folders should separate UI, API hooks, server routes, services, and persistence.
**Find It In The Code:** Open root map [CLAUDE.md:19-35], backend details [backend/CLAUDE.md:5-15], and route/service/persistence anchors [backend/src/server/app.ts:41-42], [backend/src/services/secret/secret-service.ts:109-148], [backend/src/db/schemas/secrets.ts:10-38].

```text
frontend/src/pages        # route-owned screens
frontend/src/hooks/api    # typed HTTP hooks
backend/src/server        # Fastify app and routes
backend/src/services      # business logic factories
backend/src/db            # migrations, schemas, Knex
```

**The Aha Moment:** The repo is easier when you separate "screen," "HTTP contract," "business rule," and "stored shape."
**Socratic Checkpoint:** Which folder owns pages? API hooks? Fastify routes? Services? DB schemas?
How to self-grade: strong answers cite [CLAUDE.md:33-68] and [backend/CLAUDE.md:236-238].
**Connects To:** Mission 3 and Mission 5.

### Mission 3: TypeScript Is a Contract
**Tier:** Junior
**Time Estimate:** 35 minutes
**Goal:** Understand raw API types versus UI types.
**The Concept:** Types are labels on vault drawers. A wrong label means the next engineer opens the wrong drawer.
**Design Intent Before You Read the Code:** Raw API fields should preserve server shape; UI fields should be convenient for components.
**Find It In The Code:** Open [frontend/src/hooks/api/secrets/types.ts:21-82] and [frontend/src/hooks/api/secrets/queries.tsx:82-137].

```ts
export type SecretV3Raw = { // server/API shape
  secretKey: string; // backend field name
  secretValue?: string; // may be hidden
  secretPath: string; // folder path
};
export type SecretV3RawSanitized = { // dashboard shape
  key: string; // component-friendly name
  value?: string; // rendered value
  path?: string; // component-friendly path
};
```

**The Aha Moment:** Good TypeScript lets the API and UI speak different dialects without confusion.
**Socratic Checkpoint:** Which type comes from the server? Which type is for rendering? Where is conversion done? What does `secretValueHidden` protect? Why keep both types?
How to self-grade: strong answers cite [frontend/src/hooks/api/secrets/types.ts:21-82] and [frontend/src/hooks/api/secrets/queries.tsx:88-136].
**Connects To:** Mission 6 and Mission 17.

### Mission 4: Your First React Component
**Tier:** Junior
**Time Estimate:** 25 minutes
**Goal:** Read a simple provider component.
**The Concept:** A provider is a shared power strip. Components plug into query cache, tooltips, and notifications.
**Design Intent Before You Read the Code:** The root route should wrap child routes with global providers.
**Find It In The Code:** Open [frontend/src/pages/root.tsx:15-35].

```tsx
<QueryClientProvider client={queryClient}> {/* makes React Query available */}
  <TooltipProvider> {/* shared tooltip behavior */}
    <Outlet /> {/* child route renders here */}
    <NotificationContainer /> {/* global notifications */}
  </TooltipProvider>
</QueryClientProvider>
```

**The Aha Moment:** Most pages do not import global providers because the root route already wraps them.
**Socratic Checkpoint:** What is `Outlet`? Why wrap notifications at root? Where does `queryClient` come from? What does `beforeLoad` fetch? Why context matters?
How to self-grade: strong answers cite [frontend/src/pages/root.tsx:15-35].
**Connects To:** Mission 7 and Mission 9.

### Mission 5: Your First Node.js Route
**Tier:** Junior
**Time Estimate:** 40 minutes
**Goal:** Read a Fastify route anatomy.
**The Concept:** A route is a vault counter: it checks ID, validates the request slip, asks a specialist, then records what happened.
**Design Intent Before You Read the Code:** Routes should define method, URL, schema, auth, handler, service call, and response.
**Find It In The Code:** Open [backend/src/server/routes/v4/secret-router.ts:404-559].

```ts
server.route({
  method: "POST", // HTTP action
  url: "/:secretName", // URL parameter
  schema: { body: z.object({ projectId: z.string(), environment: z.string(), secretValue: z.string() }) }, // validation
  onRequest: verifyAuth([...]), // authentication
  handler: async (req) => server.services.secret.createSecretRaw({ ... }) // business logic handoff
});
```

**The Aha Moment:** Fastify route files are contracts plus orchestration, not raw database code.
**Socratic Checkpoint:** Which line validates body? Which line authenticates? Where does service call happen? What can the route return? Where is audit logged?
How to self-grade: strong answers cite [backend/src/server/routes/v4/secret-router.ts:423-481] and [backend/src/server/routes/v4/secret-router.ts:503-558].
**Connects To:** Mission 12 and Mission 13.

### Mission 6: Props Are a Typed Contract
**Tier:** Junior
**Time Estimate:** 30 minutes
**Goal:** Read component props as an interface.
**The Concept:** Props are a work order. A secret row list needs the exact environment, project, path, and row data to act safely.
**Design Intent Before You Read the Code:** Props should say what a child component needs and what the parent owns.
**Find It In The Code:** Open [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:37-70].

```ts
type Props = {
  secrets?: SecretV3RawSanitized[]; // data to render
  environment: string; // route environment
  projectId: string; // project boundary
  secretPath?: string; // folder path
  isProtectedBranch?: boolean; // editing constraint
};
```

**The Aha Moment:** Props tell you what a component is allowed to know.
**Socratic Checkpoint:** Which props identify the secret scope? Which props are optional? Which prop carries data? Why does `projectId` belong here? What would be risky to omit?
How to self-grade: strong answers cite [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:37-70].
**Connects To:** Mission 9 and Mission 16.

### Mission 7: Following Data Into the App
**Tier:** Junior
**Time Estimate:** 35 minutes
**Goal:** Trace one data fetch from page to hook.
**The Concept:** Fetching secrets is like asking the vault clerk for a specific shelf: project, environment, folder, filters.
**Design Intent Before You Read the Code:** Page state should build a query DTO; hooks should own HTTP details.
**Find It In The Code:** Open [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:307-331] and [frontend/src/hooks/api/dashboard/queries.tsx:115-136].

```tsx
useGetProjectSecretsDetails({
  environment, projectId, secretPath, offset, limit, search, tags
  // page decides what to ask for
});
```

```ts
apiRequest.get("/api/v1/dashboard/secrets-details", { params: { ...params, tags: encodeURIComponent(...) } });
// hook decides how to ask the server
```

**The Aha Moment:** Pages assemble intent; hooks translate intent into HTTP.
**Socratic Checkpoint:** What inputs come from route? What inputs come from UI state? Which hook calls HTTP? Why encode tags? What would happen if `projectId` is empty?
How to self-grade: strong answers cite [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:157-331] and [frontend/src/hooks/api/dashboard/queries.tsx:115-136].
**Connects To:** Mission 12 and Mission 14.

### Mission 8: Navigation Is the App's Skeleton
**Tier:** Junior
**Time Estimate:** 30 minutes
**Goal:** Understand app navigation wiring.
**The Concept:** Navigation is the skeleton; pages are muscles attached to route bones.
**Design Intent Before You Read the Code:** Generated routes should feed a typed router; pages should read params/search through TanStack hooks.
**Find It In The Code:** Open [frontend/src/main.tsx:12-13], [frontend/src/main.tsx:62-89], and [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:108-117].

```tsx
const navigate = useNavigate({ from: ROUTE_PATHS.SecretManager.SecretDashboardPage.path }); // typed navigation
const environment = useParams({ from: ROUTE_PATHS.SecretManager.SecretDashboardPage.id, select: (el) => el.envSlug }); // typed params
```

**The Aha Moment:** Route typing makes URL data safer to use inside pages.
**Socratic Checkpoint:** What is generated? What does `useParams` select? What does `useSearch` read? Why pass `from`? Where does router type registration happen?
How to self-grade: strong answers cite [frontend/src/main.tsx:85-89] and [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:108-117].
**Connects To:** Mission 14 and Mission 18.

