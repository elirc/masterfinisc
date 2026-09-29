# 06 — Contribution Practice

Realistic work, scaled by difficulty. Every item answers the contribution-realism questions: why useful, why small blast radius, which existing pattern it follows, how it's tested, and what would make a maintainer reject it. Every item ends with **Interview story potential** — the STAR story completing it would produce ([08-interview-prep/06](../08-interview-prep/06-behavioral-star-stories.md)).

| File | Contents |
| --- | --- |
| [01-good-first-tickets.md](01-good-first-tickets.md) | 15 junior tickets across the repo |
| [02-mid-level-feature-tickets.md](02-mid-level-feature-tickets.md) | 10 cross-layer tickets requiring design notes |
| [03-senior-build-projects.md](03-senior-build-projects.md) | 5 multi-week projects with full plans |
| [04-refactor-and-design-katas.md](04-refactor-and-design-katas.md) | 8 senior katas with self-grading |

Note on this training clone: these tickets are written as *practice* against this working copy. If you actually want to upstream one, first check github.com/infisical/infisical for existing issues/PRs, read [CONTRIBUTING.md](../../CONTRIBUTING.md), and expect that some gaps identified here are already fixed upstream. The practice value is identical either way.

House rules for every ticket: run `make reviewable-api`/`reviewable-ui` before calling it done; migrations always get `generate:schema`; new routes copy the shape of a sibling route; and no ticket may grow beyond its acceptance criteria mid-flight (scope discipline is part of the exercise).
