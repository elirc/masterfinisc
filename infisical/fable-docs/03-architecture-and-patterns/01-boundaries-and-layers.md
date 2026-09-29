# Boundaries and Layers

## The backend's four layers and their contracts

```text
Route (HTTP)  →  Service (domain)  →  DAL (data)  →  DB
                     ↘ Queue (async side effects)
```

| Layer | Owns | Must NOT do | Real example |
| --- | --- | --- | --- |
| **Route** | HTTP shape: Zod schemas, rate limits, auth-mode gate, OpenAPI metadata; translating DTO ↔ service call | Business rules; DB access; permission decisions | [v4/secret-router.ts:48-170](../../backend/src/server/routes/v4/secret-router.ts) |
| **Service** | Business rules, invariants, *authorization*, orchestration across DALs, transaction boundaries, enqueueing side effects | Raw SQL/knex outside its DALs; HTTP concerns (status codes leak in via typed errors, translated at the edge) | [secret-v2-bridge-service.ts:300-360](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) |
| **DAL** | Query construction, `tx` threading, replica routing, data-level invariants (version increment) | Permission checks; calling services; business branching | [secret-dal.ts:11-45](../../backend/src/services/secret/secret-dal.ts) |
| **Queue** | Deferred/retryable work; owning idempotency | Trusting raw user input in payloads; making authz decisions | [secret-queue.ts:594-660](../../backend/src/services/secret/secret-queue.ts) |

The frontend mirrors it: page → API hook (queries/mutations) → Axios instance; pages never call Axios directly, hooks never render.

## Good boundaries, observed

- **Authorization lives one layer below HTTP.** Routes gate only *auth mode*; the CASL check happens in the service ([secret-v2-bridge-service.ts:339-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)). Consequence: an internal caller (another service, a CLI runner) cannot bypass permissions by skipping the route. Cost: actor context (`actor, actorId, actorOrgId, actorAuthMethod`) must thread through every service signature.
- **Data invariant enforced at the DAL.** Secret version increments inside the DAL's `update` override ([secret-dal.ts:14-21](../../backend/src/services/secret/secret-dal.ts)) — no service can forget it. The signature even removes the temptation: `data: Omit<TSecretsUpdate, "version">`.
- **Coupling made visible.** `Pick`-narrowed factory deps ([secret-service.ts:109-146](../../backend/src/services/secret/secret-service.ts)) turn "what does this module depend on" from archaeology into a type definition.
- **One unsafe file, many safe consumers.** Type casts are contained in [lib/knex/index.ts](../../backend/src/lib/knex/index.ts) so DALs stay clean.

## Boundary leaks and pressure points (labeled honestly)

- **Parsing logic inside a route schema.** The 60-line `metadataFilter` parser ([secret-router.ts:64-96](../../backend/src/server/routes/v4/secret-router.ts)) does real work in the schema layer with no dedicated unit test. Not a bug — a boundary stretch. *Possible improvement*: extract to a pure, tested function.
- **God file for wiring.** [routes/index.ts](../../backend/src/server/routes/index.ts) (3,606 lines) is the whole DI graph. Readable, but every new service touches it → merge-conflict magnet and a "who depends on whom" tangle at scale. This is the *accepted cost* of no-container DI; name it as a tradeoff, not a flaw.
- **Giant page components.** [OverviewPage.tsx](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx) at 3,759 lines mixes data fetching, permission logic, and rendering — the UI layer's version of a service doing everything. (Refactor kata material, not a drive-by PR.)
- **Two secrets engines.** `services/secret/` (legacy blind-index) and `services/secret-v2-bridge/` (current) both live; the service layer routes between them. Transitional architecture — the risk is new features landing on the legacy side by copy-paste. Check which engine a file belongs to before imitating it.

## Transferable: how to find layer contracts in any repo

1. Find one obviously-good vertical slice (here: secrets v4).
2. For each file in the slice, write the one sentence "this layer exists so that ___ never has to know about ___."
3. Grep for violations of that sentence — that's where the bodies are.
4. Ask "what enforces this?" — type system (best), convention + review (okay), nothing (risk).

## Drill

Pick the webhook module ([webhook-service.ts](../../backend/src/services/webhook/webhook-service.ts), [webhook-dal.ts](../../backend/src/services/webhook/webhook-dal.ts), [webhook-fns.ts](../../backend/src/services/webhook/webhook-fns.ts)) and write the layer-contract sentence for each file, then find one thing in each you'd flag in review.

Self-grade — Basic: correct sentences. Solid: flagged something concrete per file with a reason. Strong: at least one flag is about *what enforces the contract*, not just style.

Interview angle: "How do you structure a Node service?" and "Where do you put authorization?" both come straight from this page — answer with layers + what each must never do + one enforcement mechanism. See [08-interview-prep/03](../08-interview-prep/03-api-and-data-modeling-questions.md) and [04-system-design](../08-interview-prep/04-system-design-from-this-repo.md).
