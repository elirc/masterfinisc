# Code Review Mindset

## The five layers (review in this order)

1. **Does it work?** — happy path, obvious errors.
2. **Is it correct?** — edge cases, concurrency, invariants. *Here*: races on check-then-write ([critique table](../03-architecture-and-patterns/06-architecture-critique.md)), `tx` threading completeness, idempotency of queued work.
3. **Will it stay correct?** — tests that pin behavior; types that forbid misuse (an `Omit<..., "version">` beats a comment — [secret-dal.ts:14](../../backend/src/services/secret/secret-dal.ts)).
4. **Does it fit?** — the house patterns: DAL/service/route split, `Pick` deps, query-key factories, verifyAuth + CASL pairing, audit events on mutations.
5. **Is it kind to future maintainers?** — names, dead code, doc updates, greppable contracts.

Blocking findings live in layers 1–2 (and security anywhere); layer 4–5 findings are important/optional. Tagging severity is respect for the author's time.

## Repo-specific review checklist

- [ ] New route: `verifyAuth` modes deliberate; rate-limit preset; Zod schema with `operationId`; no deprecated auth modes
- [ ] New service method: CASL assertion present; actor context threaded; deps added as `Pick`
- [ ] DB: DAL-only access; `tx` passed to every call inside a transaction; migration has `down()` + `generate:schema` rerun
- [ ] Queue: retry config deliberate; idempotent handler; failure visible to a human
- [ ] Frontend: query keys via factory; mutation invalidations complete; permission-gated UI matches backend action
- [ ] Strings machines parse: grepped for consumers before changing
- [ ] Security checklist pass ([05/05](../05-quality-engineering/05-security-checklist.md))

## Comment language that works

> **Blocking**: `findById(req.params.id)` skips project scoping — user B can read org A's webhook by id. Can we resolve through `getProjectPermission` + CASL like `webhook-service.createWebhook` does?

> **Important (question)**: This adds a fourth place we compute `secretPath` normalization — worth extracting to `lib/`, or is there a reason they differ?

> **Optional/nit**: `data2` → maybe `decryptedWebhook`? Feel free to ignore.

Anatomy: severity tag → observed fact → concrete consequence → suggested direction phrased as a question when you might be missing context. Never "this is wrong" without the consequence; never a demand where a question works; always at least one genuine positive that taught you something ("TIL `COUNT(*) OVER()` — nice").

## Drill

Review your own last PR (any repo) against the five layers and write yourself three comments, one of which must be blocking. If you can't find a blocking comment in your own recent work, review harder — interviewers running review rounds ([08/05](../08-interview-prep/05-debugging-and-code-review-rounds.md)) report that self-blindness, not missing knowledge, is what fails candidates.
