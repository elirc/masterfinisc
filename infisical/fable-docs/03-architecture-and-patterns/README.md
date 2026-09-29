# 03 — Architecture and Patterns

How this system is shaped, why, and where it creaks. This module is the core of "mid-level judgment": layers and their contracts, persistence discipline, the auth stack, async reliability, a catalog of 14 recognizable patterns, and an honest critique.

| File | Covers |
| --- | --- |
| [01-boundaries-and-layers.md](01-boundaries-and-layers.md) | Route/service/DAL/queue layers; what each owns; leaks |
| [02-data-model-and-persistence.md](02-data-model-and-persistence.md) | Entities, migrations, transactions, safe schema change |
| [03-validation-auth-and-permissions.md](03-validation-auth-and-permissions.md) | Validation layers; authn vs authz; tenant isolation |
| [04-side-effects-async-and-reliability.md](04-side-effects-async-and-reliability.md) | Queues, retries, idempotency, failure visibility |
| [05-pattern-catalog.md](05-pattern-catalog.md) | 14 pattern cards with recognition drills |
| [06-architecture-critique.md](06-architecture-critique.md) | Strengths, risks, what to change — doubles as system-design prep |

Vocabulary you'll exercise here (define each aloud before starting): *invariant* — a condition that must always hold; *boundary* — a line where assumptions change; *contract* — the promises an interface makes; *blast radius* — how much breaks when something fails; *idempotency* — safe to apply twice.
