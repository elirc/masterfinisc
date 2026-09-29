# Type System and Contracts

TypeScript in this repo isn't decoration — it's the enforcement mechanism for architectural contracts. Three ideas carry most of the weight.

## 1. `Pick` as a dependency contract

Every service factory narrows its dependencies to the exact methods it uses:

```ts
// Real code — backend/src/services/secret/secret-service.ts:113-114
projectDAL: Pick<TProjectDALFactory, "checkProjectUpgradeStatus" | "findProjectBySlug" | "findById">;
projectEnvDAL: Pick<TProjectEnvDALFactory, "findOne">;
```

Why it matters: this is *interface segregation* without interfaces. The type tells you the true coupling surface (secret-service can only ever call three project methods), tests can stub two functions instead of forty, and widening the contract is a visible diff a reviewer will question. Failure mode of the alternative: `projectDAL: TProjectDALFactory` silently grants everything, and coupling grows undetected.

The factory return type is inferred, then exported: `export type TSecretServiceFactory = ReturnType<typeof secretServiceFactory>` ([secret-service.ts:148](../../backend/src/services/secret/secret-service.ts)) — implementation is the source of truth; consumers get the type for free. Transferable: `ReturnType`, `Pick`, `Omit` let you *derive* types instead of duplicating them.

## 2. Zod as the runtime half of the type system

TS types vanish at runtime; every trust boundary needs a runtime check. This repo's rule: **each boundary owns a Zod schema.**

- HTTP boundary: route schemas — including transforms that parse (`metadataFilter` string → array, [secret-router.ts:64-96](../../backend/src/server/routes/v4/secret-router.ts)) and recursive types (`SecretReferenceNodeTree` with `z.lazy`, lines 42-44).
- DB boundary: generated schemas in [backend/src/db/schemas/](../../backend/src/db/schemas/) — 272 tables, regenerated from the live DB by `npm run generate:schema`, so the compiler learns about every migration.
- Env/config boundary: config module validates env vars at boot (fail fast, not on first use).

The phrase to internalize (and use in interviews): **"parse, don't validate."** A transform returns *typed, reshaped* data; a mere boolean check leaves you holding a `string` you must re-interpret everywhere.

`z.infer<typeof Schema>` bridges back to compile time — one definition, both worlds (used at [secret-router.ts:40](../../backend/src/server/routes/v4/secret-router.ts)).

## 3. Narrowing, unions, and the `unknown` discipline

- Discriminated-union narrowing in the wild: `switch (decodedToken.authTokenType)` ([inject-identity.ts:112](../../backend/src/server/plugins/auth/inject-identity.ts)) — each case narrows to a different auth path; adding a new token type without handling it should fail the `switch`'s exhaustiveness (check whether it does — good drill).
- Actor branching in [inject-permission.ts:12-79](../../backend/src/server/plugins/auth/inject-permission.ts) narrows `req.auth` per `ActorType` before touching actor-specific fields.
- `unknown` vs `any`: `any` switches the compiler off transitively — one `any` DTO poisons every function it flows through. `unknown` forces a parse/narrow first. Rule of thumb this repo mostly follows: `any` only at generated/serialization edges, never in service signatures.
- `satisfies` (know it for interviews): checks a value against a type *without widening* it — ideal for config objects where you want both checking and literal inference.

## Where the repo bends its own rules

`as never` / `as` casts inside `ormify` ([lib/knex/index.ts:168-240](../../backend/src/lib/knex/index.ts)) — the generic table-name-to-row-type mapping is beyond what Knex's types express, so the boundary of the ORM helper is cast-heavy while its *consumers* stay fully typed. That's the pragmatic pattern: contain unsafety in one audited file, export clean types. If you find yourself casting in service code, you're on the wrong side of that line.

## Drills

1. Take `TSecretServiceFactoryDep` ([secret-service.ts:109-146](../../backend/src/services/secret/secret-service.ts)) and count deps narrowed with `Pick` vs taken whole. What does each whole-type dep say about coupling?
2. Write (scratch file) a Zod schema for the webhook payload in [webhook-fns.ts:65+](../../backend/src/services/webhook/webhook-fns.ts) as if you were a consumer defending against changes.
3. Add a fake new `AuthTokenType` case on paper: list every file the compiler would *and would not* force you to update. The "would not" list is your risk.

## Interview angle

- "How do you keep API types and runtime validation in sync?" → Zod schema as single source, `z.infer`, generated DB schemas. ([08-interview-prep/01](../08-interview-prep/01-js-ts-node-deep-dive.md) Q8–Q10)
- "`unknown` vs `any`?" → poisoning argument + where this repo tolerates casts (contained in `ormify`).
- "What are generics for, practically?" → `ormify<Tname>` returns table-specific CRUD types from one implementation.
- "How do you design module boundaries in TS?" → `Pick`-narrowed deps as compile-checked least privilege — a genuinely senior answer most candidates don't have.
