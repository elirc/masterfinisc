# Data Model and Persistence

## The shape of the data

PostgreSQL, 272 tables (count of generated schema files in [backend/src/db/schemas/](../../backend/src/db/schemas/)), 424 migrations. Core entity spine for the secrets product:

```text
Organization ─< Project ─< Environment ─< Folder (tree) ─< Secret ─< SecretVersion
                   │                                          │
                   ├─< ProjectMembership (users/identities)   ├─< SecretTag (m:n)
                   └─< Webhook / Integration / ApprovalPolicy └─ personal override (userId + type)
```

Key relationship facts (verify in schemas as you use them): secrets belong to folders, not directly to environments; `secretPath` is resolved to a `folderId` at the service layer ([secret-v2-bridge-service.ts:304-310](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)); versions are separate rows, giving history and rollback; personal secrets are rows with `type=personal` + a user id shadowing a shared key ([db/schemas/models.ts:363-366](../../backend/src/db/schemas/models.ts)).

## Access discipline

- All queries flow through DALs built on `ormify` ([lib/knex/index.ts:156-326](../../backend/src/lib/knex/index.ts)).
- **Reads** default to `db.replicaNode()` (lines 168, 184, 205) — cheap horizontal read scaling, at the price of replica lag. **Writes** always hit primary.
- **Transactions** thread as an optional trailing `tx` param on every DAL method; services open them via `dal.transaction(cb)` (lines 161-165). Rule of thumb in this codebase: *the service that owns the invariant owns the transaction.*
- `updateById`/`update` support atomic `$incr`/`$decr` — counters without read-modify-write races ([backend/CLAUDE.md](../../backend/CLAUDE.md)).
- Complex joins use `sqlNestRelationships` to map flat rows into nested objects (see usage imported in [secret-dal.ts:7](../../backend/src/services/secret/secret-dal.ts)).

**Consistency expectations** (interview vocabulary): within a transaction — full ACID; across the replica boundary — eventual consistency (a read may not see your own 100ms-old write); across queue jobs — eventual, with at-least-once execution.

## How schema changes actually happen here

Workflow: `npm run migration:new` → write `up`/`down` → `npm run migration:latest-dev` → **`npm run generate:schema`** (regenerates the Zod/TS types — skipping this leaves the compiler blind to your change) → commit migration + generated schemas together.

Study this real migration — it's a masterclass in production-safe DDL: [20260513182201_add-folder-id-indexes-for-snapshot-prune.ts](../../backend/src/db/migrations/20260513182201_add-folder-id-indexes-for-snapshot-prune.ts):

- `CREATE INDEX CONCURRENTLY IF NOT EXISTS` — builds without taking a write-blocking lock on a hot table.
- `const config = { transaction: false }` — because `CONCURRENTLY` cannot run inside a transaction.
- Sets `statement_timeout` (60 min) and `lock_timeout` (30 s), restoring originals in `finally` — a long build is fine; *waiting on a lock* must fail fast rather than queue up behind production traffic.
- Guards with `hasTable`/`hasColumn` — idempotent against divergent environments.
- A real `down()` that drops the indexes.

## "How to safely change the schema" checklist (transferable)

1. **Additive first.** New nullable column / new table / new index `CONCURRENTLY`. Never rename in place — add, backfill, switch readers, drop later (expand–contract).
2. **Backfills are their own migration** (this repo does this — see `20260508140759_backfill-org-custom-role-project-request-access.ts`), batched, with timeouts.
3. **Locks are the danger, not duration.** Know which DDL takes `ACCESS EXCLUSIVE`; set `lock_timeout`.
4. **`down()` must exist and be honest.** If it can't restore data (dropped column), say so in a comment — rollback strategy shifts to roll-forward.
5. **Regenerate types** and let the compiler find every consumer.
6. **Deploy order**: code that tolerates both shapes → migrate → code that requires the new shape.

## What a junior misses vs what a senior checks

Junior: writes `knex.schema.alterTable(...).notNullable()` on a big table and locks production for minutes. Senior: asks "what lock does this take, how long is the table, what's reading it, and what happens to in-flight old-code writes during deploy?"

## Drills

1. Read the newest five files in [migrations/](../../backend/src/db/migrations/) and classify each: additive / index / backfill / cleanup. Which could run on a live system without user impact?
2. Design (on paper) the expand–contract plan to rename `secrets.comment` to `secrets.note` with zero downtime — then check whether any repo migration does a rename and how.
3. Explain why `generate:schema` reads the *database* rather than the migration files, and one failure mode of that choice (dev DB drift produces wrong types).

Self-grade — Basic: correct classification. Solid: correct locking story for each. Strong: full expand–contract plan including deploy ordering and rollback.

Interview angle: "How do you do zero-downtime migrations?" is a top-5 mid-level question — answer with the real index migration above (concurrent build, lock timeout, no transaction) and the expand–contract recipe. Cross-linked in [08-interview-prep/03](../08-interview-prep/03-api-and-data-modeling-questions.md).
