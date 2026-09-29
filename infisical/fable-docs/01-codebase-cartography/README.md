# 01 — Codebase Cartography

Before you change code you need a map: what the repo is shaped like, which files to read in what order, what the domain nouns mean, how the tooling works, and how the six most representative flows move through the system.

| File | What it gives you |
| --- | --- |
| [01-system-map.md](01-system-map.md) | Monorepo layout, ownership map, public vs private surfaces |
| [02-file-reading-order.md](02-file-reading-order.md) | 28 files in reading order, split by junior/mid/senior |
| [03-domain-glossary.md](03-domain-glossary.md) | Product nouns → code locations; confusing near-synonyms |
| [04-runtime-and-tooling-map.md](04-runtime-and-tooling-map.md) | Package manager, build, test, dev servers, runtime boundaries |
| [05-key-flows.md](05-key-flows.md) | Six end-to-end traces with risks, drills, and interview angles |

Transferable skill: **cartography is the first thing seniors do in any unfamiliar repo.** The moves are always the same — read the manifests, find the entry points, find where routes/handlers are registered, find the persistence layer, then trace one write path end to end. Practice the moves here so they're automatic in your next codebase (and in a "walk me through a codebase you learned" interview question).
