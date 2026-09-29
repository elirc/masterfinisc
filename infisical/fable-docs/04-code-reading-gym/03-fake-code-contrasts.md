# Fake-Code Contrasts

Eight bad-vs-better pairs. All snippets are **illustrative fake code, not from this repo** — each pair ends with the real repo pattern it contrasts with. Read the bad one first and articulate what's wrong *before* reading the fix.

## 1. Coupling UI shape to DB shape

```ts
// Illustrative fake code: not from this repo.
// BAD: component renders raw DB rows; every schema change breaks the UI
const { data } = useQuery(["secrets"], fetchSecrets);
return data.rows.map(r => <Row key={r.id} name={r.key_ciphertext_meta.k} />);

// BETTER: transform at the query layer into a view model
useQuery({ queryKey, queryFn, select: (d) => toSecretViewModel(d) });
```

Real pattern: `select: mergePersonalSecrets(data.secrets)` at [queries.tsx:168](../../frontend/src/hooks/api/secrets/queries.tsx) — the merge/reshape lives with the query, components see a stable shape.

## 2. Missing permission filter (IDOR)

```ts
// Illustrative fake code: not from this repo.
// BAD: authenticated ≠ authorized; any logged-in user reads any secret by id
app.get("/secrets/:id", verifyAuth([JWT]), async (req) =>
  secretDAL.findById(req.params.id));

// BETTER: resolve through the caller's scope and assert the ability
const secret = await secretDAL.findById(id);
const { permission } = await permissionService.getProjectPermission({ ...actorCtx, projectId: secret.projectId });
ForbiddenError.from(permission).throwUnlessCan(Read, subject(Secrets, { environment, secretPath }));
```

Real pattern: every secret operation in [secret-v2-bridge-service.ts](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) (e.g. 339-347, 560-605).

## 3. N+1 queries

```ts
// Illustrative fake code: not from this repo.
// BAD: one query per secret to fetch its tags — 200 secrets = 201 queries
for (const s of secrets) s.tags = await tagDAL.find({ secretId: s.id });

// BETTER: one join (or one IN query) + in-memory grouping
const rows = await db(TableName.Secret).leftJoin(TableName.SecretTag, ...).select(...);
const secrets = sqlNestRelationships(rows, ...);
```

Real pattern: DALs use joins + `sqlNestRelationships` (imported at [secret-dal.ts:7](../../backend/src/services/secret/secret-dal.ts)); batch loads use `$in` filters ([secret-dal.ts:48-53](../../backend/src/services/secret/secret-dal.ts)).

## 4. Stale cache keys

```ts
// Illustrative fake code: not from this repo.
// BAD: key ignores environment — switching env shows the previous env's secrets
useQuery({ queryKey: ["secrets", projectId], queryFn: () => fetch(projectId, environment, path) });

// BETTER: every input to queryFn appears in the key
useQuery({ queryKey: [{ projectId, environment, secretPath }, "secrets"], ... });
```

Real pattern: [queries.tsx:33-41](../../frontend/src/hooks/api/secrets/queries.tsx) — key factory includes all four params, even `viewSecretValue`.

## 5. Side effects in unreliable places

```ts
// Illustrative fake code: not from this repo.
// BAD: webhook inside the transaction; partner latency holds a DB lock,
// partner success + tx rollback = phantom notification
await db.transaction(async (tx) => {
  await secretDAL.create(data, tx);
  await notifyWebhooks(event);
});

// BETTER: commit, then enqueue retryable, idempotent work
await db.transaction(async (tx) => secretDAL.create(data, tx));
await queue.enqueue(QueueName.SecretWebhook, event, { attempts: 5, backoff });
```

Real pattern: [secret-queue.ts:674-675](../../backend/src/services/secret/secret-queue.ts).

## 6. Swallowed errors

```ts
// Illustrative fake code: not from this repo.
// BAD: failure becomes `null`, surfaces later as an unrelated crash
try { return await dal.findById(id); } catch { return null; }

// BETTER: wrap with typed context and let the edge translate
try { return await dal.findById(id); }
catch (error) { throw new DatabaseError({ error, name: "Find by id" }); }
```

Real pattern: every `ormify` method ([lib/knex/index.ts:166-173](../../backend/src/lib/knex/index.ts)); typed domain errors (`NotFoundError`, `BadRequestError`) thrown in services and translated once at the Fastify error handler.

## 7. `any` overuse

```ts
// Illustrative fake code: not from this repo.
// BAD: one `any` DTO disables checking for everything downstream
async function updateSecret(dto: any) { return dal.update({ id: dto.id }, dto.patch); }

// BETTER: typed DTO in *-types.ts; unknown + parse at true boundaries
async function updateSecret(dto: TUpdateSecretDTO) { ... }
```

Real pattern: every service has a `*-types.ts` (e.g. [secret-types.ts](../../backend/src/services/secret/secret-types.ts)); casts are contained inside [lib/knex/index.ts](../../backend/src/lib/knex/index.ts), not in service signatures.

## 8. Casual public-contract change

```ts
// Illustrative fake code: not from this repo.
// BAD: renaming a response field "because it reads better" — every API consumer breaks
- secretValue: z.string()
+ value: z.string()

// BETTER: additive + deprecate; version if the shape must truly change
secretValue: z.string(),            // deprecated: use `value`; remove in v5
value: z.string(),
```

Real pattern: the repo maintains four parallel API versions ([routes/index.ts:3572-3591](../../backend/src/server/routes/index.ts)) precisely so shapes can evolve without breaking old consumers; route Zod schemas *are* the published OpenAPI contract ([secret-router.ts:56](../../backend/src/server/routes/v4/secret-router.ts)).

---

Drill: for each pair, name the *test* that would catch the bad version (e.g. #2: cross-tenant e2e; #4: switch-env-and-assert UI test; #5: kill the worker mid-tx chaos test). Self-grade — Weak: saw the bug after reading the fix. Solid: named it cold, plus the fix. Strong: also named the detecting test and the repo file enforcing the good pattern.
