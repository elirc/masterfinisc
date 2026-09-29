### Mission 9: State Has a Home and a Reason
**Tier:** Mid-Level
**Time Estimate:** 45 minutes
**Goal:** Explain why pending secret state lives in a page-scoped Zustand store.
**The Concept:** Pending changes are a staging tray before the vault writes become permanent.
**Design Intent Before You Read the Code:** Batch state needs typed creates/updates/deletes and duplicate checks before commit.
**Find It In The Code:** Open [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:15-108] and [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:301-483].

```ts
export type PendingSecretChange = PendingSecretCreate | PendingSecretUpdate | PendingSecretDelete; // discriminated union
export interface PendingChanges { secrets: PendingSecretChange[]; folders: PendingFolderChange[]; } // grouped staging area
```

**The Aha Moment:** State is not just storage; it encodes allowed transitions.
**Socratic Checkpoint:** Why discriminated unions? Where are duplicates blocked? What is a server key? How can a rename free a key? Why not put this in global app state?
How to self-grade: strong answers cite [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:21-108] and [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:322-368].
**Connects To:** Mission 11 and Mission 20.

### Mission 10: The Custom Hook Ecosystem
**Tier:** Mid-Level
**Time Estimate:** 45 minutes
**Goal:** Recognize query and mutation hook conventions.
**The Concept:** Hooks are named vault procedures: "get this shelf," "create this key," "invalidate these views."
**Design Intent Before You Read the Code:** Each domain should own query keys, fetchers, hooks, mutations, and types.
**Find It In The Code:** Open [frontend/src/hooks/api/dashboard/queries.tsx:29-88], [frontend/src/hooks/api/secrets/queries.tsx:33-80], and [frontend/src/hooks/api/secrets/mutations.tsx:25-89].

```ts
export const dashboardKeys = { all: () => ["dashboard"] as const }; // cache namespace
export const fetchProjectSecrets = async (...) => apiRequest.get("/api/v4/secrets", { params }); // HTTP
export const useCreateSecretV3 = () => useMutation({ mutationFn, onSuccess }); // write path
```

**The Aha Moment:** Hook files are the frontend's API client layer.
**Socratic Checkpoint:** What is a key factory? What is a fetcher? What is a mutation? Where does invalidation live? Why are hooks typed?
How to self-grade: strong answers cite [frontend/src/hooks/api/dashboard/queries.tsx:29-88] and [frontend/src/hooks/api/secrets/mutations.tsx:57-86].
**Connects To:** Mission 12 and Mission 15.

### Mission 11: Side Effects Are Promises to the System
**Tier:** Mid-Level
**Time Estimate:** 45 minutes
**Goal:** Trace side effects after a secret mutation.
**The Concept:** Creating a secret is not just storing a value; it also updates every view that promised to show that value.
**Design Intent Before You Read the Code:** Successful writes should invalidate all stale reads.
**Find It In The Code:** Open [frontend/src/hooks/api/secrets/mutations.tsx:25-210].

```ts
onSuccess: (_, { projectId, environment, secretPath }) => {
  queryClient.invalidateQueries({ queryKey: dashboardKeys.getDashboardSecrets({ projectId, secretPath }) }); // dashboard stale
  queryClient.invalidateQueries({ queryKey: secretKeys.getProjectSecret({ projectId, environment, secretPath }) }); // raw secrets stale
  queryClient.invalidateQueries({ queryKey: commitKeys.history({ projectId, environment, directory: secretPath }) }); // history stale
}
```

**The Aha Moment:** Cache invalidation is part of the feature, not cleanup.
**Socratic Checkpoint:** Which caches are invalidated on create? Why snapshots? Why commits? Which invalidation uses a predicate? What risk comes from duplication across mutations?
How to self-grade: strong answers cite [frontend/src/hooks/api/secrets/mutations.tsx:57-86], [frontend/src/hooks/api/secrets/mutations.tsx:131-165], and [frontend/src/hooks/api/secrets/mutations.tsx:190-210].
**Connects To:** Mission 15 and Mission 21.

### Mission 12: The Full API Contract
**Tier:** Mid-Level
**Time Estimate:** 50 minutes
**Goal:** Map frontend DTOs to backend route schemas.
**The Concept:** The API contract is the vault request form; both desk and vault must agree on every field.
**Design Intent Before You Read the Code:** Frontend mutation body should match backend Zod body.
**Find It In The Code:** Open [frontend/src/hooks/api/secrets/mutations.tsx:25-55] and [backend/src/server/routes/v4/secret-router.ts:404-481].

```ts
apiRequest.post(`/api/v4/secrets/${encodeURIComponent(secretKey)}`, { secretPath, type, environment, projectId, secretValue });
// frontend sends contract fields
```

```ts
body: z.object({ projectId: z.string(), environment: z.string(), secretPath: z.string().default("/"), secretValue: z.string() });
// backend validates contract fields
```

**The Aha Moment:** A contract bug is usually visible on both sides if you compare them line by line.
**Socratic Checkpoint:** Which fields are in both places? Which frontend fields are optional? Which backend transforms `secretValue`? Where is `secretName` encoded? What response shapes are possible?
How to self-grade: strong answers cite [frontend/src/hooks/api/secrets/mutations.tsx:32-55] and [backend/src/server/routes/v4/secret-router.ts:420-460].
**Connects To:** Mission 14 and Mission 23.

### Mission 13: The Middleware Chain
**Tier:** Mid-Level
**Time Estimate:** 45 minutes
**Goal:** Understand Fastify plugin order and request context.
**The Concept:** Middleware is the security checkpoint line before the vault counter.
**Design Intent Before You Read the Code:** Global plugins should parse, secure, measure, contextualize, and route requests.
**Find It In The Code:** Open [backend/src/server/app.ts:107-201].

```ts
await server.register(cookie, { secret: appCfg.COOKIE_SECRET_SIGN_KEY }); // signed cookies
await server.register(cors, ...); // origin rules
await server.register(fastifyErrHandler); // consistent errors
await server.register(fastifyRequestContext, { defaultStoreValues: (...) }); // request-scoped data
await server.register(registerRoutes, { db, queue, redis, envConfig }); // actual API graph
```

**The Aha Moment:** Route handlers inherit a prepared request environment.
**Socratic Checkpoint:** Why register error handling? What goes in request context? Where does CORS become permissive? Why register routes after plugins? Where is UI served?
How to self-grade: strong answers cite [backend/src/server/app.ts:107-201].
**Connects To:** Mission 14 and Mission 22.

### Mission 14: End-to-End Feature Trace
**Tier:** Mid-Level
**Time Estimate:** 60 minutes
**Goal:** Trace secret creation from UI to DB-shaped data.
**The Concept:** A secret travels like a sealed envelope: label in UI, transport through API, validation at vault, encrypted storage.
**Design Intent Before You Read the Code:** Every boundary should preserve project, environment, path, key, value, and actor.
**Find It In The Code:** Open [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretListView.tsx:187-199], [frontend/src/hooks/api/secrets/mutations.tsx:25-89], [frontend/src/config/request.ts:22-44], [backend/src/server/routes/v4/secret-router.ts:404-559], [backend/src/db/schemas/secrets.ts:10-38].

```text
SecretListView -> useCreateSecretV3 -> apiRequest -> POST /api/v4/secrets/:secretName -> createSecretRaw -> audit/telemetry -> encrypted fields
```

**The Aha Moment:** Full-stack tracing is just following ownership across boundaries.
**Socratic Checkpoint:** Where does the key enter? Where is it URL-encoded? Where is auth added? Where is schema validation? Where is encrypted persistence represented?
How to self-grade: strong answers cite every file listed in this mission.
**Connects To:** Mission 18 and Mission 23.

### Mission 15: Read the Diff Like an Engineer
**Tier:** Mid-Level
**Time Estimate:** 45 minutes
**Goal:** Practice reviewing a realistic secret-field change.
**The Concept:** A diff is a map of promises changed. Review promises, not lines.
**Design Intent Before You Read the Code:** New fields must cross type, UI, API, backend validation, service, DB, audit, and cache.
**Find It In The Code:** Open [frontend/src/hooks/api/secrets/types.ts:21-82], [frontend/src/hooks/api/secrets/mutations.tsx:25-130], [backend/src/server/routes/v4/secret-router.ts:423-648], [backend/src/db/schemas/secrets.ts:1-38].

```text
Review checklist:
type -> query transform -> mutation body -> route schema -> service DTO -> DB schema -> audit masking -> tests
```

**The Aha Moment:** The missing file in a diff is often the bug.
**Socratic Checkpoint:** What files must change for a persisted field? What files must not be hand-edited? Where should cache invalidation remain unchanged? How do you check audit safety? What test proves it?
How to self-grade: strong answers cite [backend/src/db/schemas/secrets.ts:1-4] and route/type lines above.
**Connects To:** Mission 19 and Mission 23.

### Mission 16: Composition Over Inheritance
**Tier:** Mid-Level
**Time Estimate:** 35 minutes
**Goal:** See how the dashboard composes feature sections.
**The Concept:** The page is a vault room with stations: folders, imports, dynamic secrets, rotations, honey tokens, and static secrets.
**Design Intent Before You Read the Code:** Parent should compose child views and pass scope props.
**Find It In The Code:** Open [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1057-1124].

```tsx
<SecretImportListView ... /> // imports station
<FolderListView ... /> // folders station
<DynamicSecretListView ... /> // dynamic secrets station
<SecretRotationListView ... /> // rotations station
<SecretListView secrets={mergedSecrets} ... /> // static secrets station
```

**The Aha Moment:** Composition lets one dashboard coordinate many resource types without inheritance.
**Socratic Checkpoint:** Which child renders static secrets? Which renders folders? Which props define scope? Which sections are permission-gated? Where does pending commit UI appear?
How to self-grade: strong answers cite [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:1057-1124].
**Connects To:** Mission 18 and Mission 21.

### Mission 17: TypeScript's Hidden Work
**Tier:** Mid-Level
**Time Estimate:** 40 minutes
**Goal:** Notice type inference and validation layers.
**The Concept:** TypeScript is the vault map; Zod is the guard checking the actual visitor.
**Design Intent Before You Read the Code:** Compile-time types and runtime schemas should support each other.
**Find It In The Code:** Open [frontend/src/hooks/api/secrets/types.ts:172-180], [backend/src/server/routes/v4/secret-router.ts:420-452], and [backend/src/db/schemas/secrets.ts:10-38].

```ts
export type TCreateSecretsV3DTO = { secretKey: string; secretValue: string; projectId: string; environment: string; type: SecretType; };
// compile-time frontend shape
```

```ts
body: z.object({ projectId: z.string().trim(), environment: z.string().trim(), secretValue: z.string().transform(...) });
// runtime backend shape
```

**The Aha Moment:** TypeScript prevents bad code you write; Zod rejects bad input users send.
**Socratic Checkpoint:** What is compile-time only? What runs at request time? Where does DB schema type come from? What happens if frontend type changes but backend schema does not? What happens in reverse?
How to self-grade: strong answers cite [frontend/src/hooks/api/secrets/types.ts:172-180], [backend/src/server/routes/v4/secret-router.ts:420-452], and [backend/src/db/schemas/secrets.ts:10-38].
**Connects To:** Mission 19 and Mission 23.

