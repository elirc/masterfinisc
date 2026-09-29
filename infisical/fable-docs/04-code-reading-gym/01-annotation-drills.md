# Annotation Drills

For each excerpt, open the real file and write six annotations: **Inputs** (and who controls them), **Outputs**, **Dependencies**, **Invariants** (what must always hold), **Side effects**, **Failure modes** (concrete inputs/states → concrete bad outcomes). Then grade with the rubric at the bottom.

## Drill 1 — `verifyAuth` ([verify-auth.ts:10-32](../../backend/src/server/plugins/auth/verify-auth.ts))

Whole file, 32 lines. Extra questions: why does it pass through non-GET requests when `shouldForwardWritesToPrimaryInstance` is set (line 13-15)? What happens to a request with *no* Authorization header at all — where does it get rejected, here or earlier?

## Drill 2 — `ormify.find` ([lib/knex/index.ts:177-202](../../backend/src/lib/knex/index.ts))

Extra questions: what does `count: true` do to the SQL (`COUNT(*) OVER()` window — why a window function instead of a second query)? Which caller mistake would this method hide rather than surface?

## Drill 3 — secret `update` override ([secret-dal.ts:14-21](../../backend/src/services/secret/secret-dal.ts))

Extra questions: the filter is `Partial<TSecrets>` — what happens if a service passes `{}`? Is that a failure mode or a feature? What stops a caller from setting `version` directly?

## Drill 4 — `createSecret` validation block ([secret-v2-bridge-service.ts:304-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts))

The richest drill. Annotate the *ordering*: folder 404 → personal/actor check → duplicate check → tag check → CASL. Extra questions: which checks are reads that could race with concurrent writes? Why does the CASL check come after the cheap validations (two defensible answers: fail-fast economics, and the subject needs the loaded tags)?

## Drill 5 — `syncSecrets` producer ([secret-queue.ts:594-648](../../backend/src/services/secret/secret-queue.ts))

Extra questions: list every option object property and what removing it would break (`jobId`, `attempts`, `backoff`, `removeOnComplete`). What is the *unit of idempotency* here?

## Drill 6 — refresh interceptor ([request.ts:59-131](../../frontend/src/config/request.ts))

Extra questions: enumerate the four conditions gating the refresh path (lines 63-70) and construct one scenario per condition where skipping refresh is correct. Why `finally` on line 80-82?

## Drill 7 — `useGetProjectSecrets` ([queries.tsx:139-170](../../frontend/src/hooks/api/secrets/queries.tsx))

Extra questions: what re-runs when `secretPath` changes and why (key identity)? What does `select` buy over transforming in the component? Where would a personal-override merging bug live — fetch, cache, or select?

## Drill 8 — index migration ([20260513182201_add-folder-id-indexes-for-snapshot-prune.ts](../../backend/src/db/migrations/20260513182201_add-folder-id-indexes-for-snapshot-prune.ts))

Extra questions: why restore timeouts in `finally` rather than at the end? Why is `config = { transaction: false }` *required* rather than an optimization? What could make `down()` fail?

---

## Self-grading rubric (apply per drill)

| Grade | Observable behavior |
| --- | --- |
| **Weak** | Named the file's purpose and inputs/outputs; annotations restate the code ("it updates the secret") |
| **Solid** | Traced data shapes in and out; named at least one real invariant and one dependency's contract; failure modes are concrete ("filter `{}` updates every row in the table") |
| **Strong** | Identified a risk the code doesn't handle, proposed the test that would catch it, and named an alternative design with its tradeoff; used precise vocabulary (invariant, idempotent, race, boundary) correctly |

Interview note: drills 4, 5, and 6 map directly to spoken code-walkthrough rounds — practice narrating them in under three minutes each ([08-interview-prep/05](../08-interview-prep/05-debugging-and-code-review-rounds.md) reuses them under time pressure).
