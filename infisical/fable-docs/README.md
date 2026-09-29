# Fable Docs — Infisical as a Training Lab

A learning curriculum that turns this clone of [Infisical](https://github.com/infisical/infisical) — an open-source secrets management platform — into a hands-on training lab for a **junior fullstack JS engineer** who wants to reach mid-level fast, build senior judgment, and pass interviews for mid-level fullstack roles.

Every page teaches two things at once:

1. **This codebase** — where things live, how its real flows work, with exact file/line anchors.
2. **Transferable skill** — why the pattern exists, alternatives, failure modes, and how to talk about it in an interview.

## What Infisical is (the 60-second version)

Infisical is a secrets management platform: teams store API keys, database credentials, and certificates in projects/environments/folders, and machines fetch them at runtime. It is a TypeScript monorepo: a **Fastify 4 API server** ([backend/](../backend/)) with PostgreSQL via Knex and BullMQ job queues on Redis, and a **React 18 SPA** ([frontend/](../frontend/)) built with Vite, TanStack Router, React Query, and Tailwind v4. Enterprise features live in [backend/src/ee/](../backend/src/ee/) and are registered before community routes. Authorization is CASL-based with org-level and project-level permissions. Everything security-relevant — encryption, auth modes, SSRF guards, approval workflows — is first-class, which makes it unusually good interview material: it is a real product where validation, authorization, async reliability, and multi-tenancy are not toy concerns.

## How to use this curriculum

| Time budget | Path |
| --- | --- |
| One weekend | [00-fast-track.md](00-fast-track.md) only |
| Two weeks | Fast track → [01-codebase-cartography](01-codebase-cartography/README.md) → [05-key-flows](01-codebase-cartography/05-key-flows.md) → 2–3 junior tickets from [06-contribution-practice](06-contribution-practice/01-good-first-tickets.md) |
| Eight weeks | All modules in order; one mid-level ticket per week from week 4 |
| Ongoing contributor | Use [06-contribution-practice](06-contribution-practice/README.md) as a backlog, [09-reference](09-reference/learning-rubrics.md) to self-assess monthly |
| **Interview in two weeks** | Go directly to [08-interview-prep/07-two-week-cram-plan.md](08-interview-prep/07-two-week-cram-plan.md) |

### Recommended paths by profile

- **Brand-new junior**: 00 → 01 → 02 → 04 (drills) → 06 (junior tickets). Skip 03-.../06-architecture-critique until later.
- **Junior who knows React/Node**: 00 → 01/05-key-flows → 03 (architecture) → 04 → 06.
- **Mid-level, new to this repo**: 01/01-system-map → 01/05-key-flows → 03/05-pattern-catalog → 03/06-architecture-critique → 06 (mid tickets).
- **Senior doing architecture review**: 03/06-architecture-critique → 09/risk-register → 05/05-security-checklist.
- **Candidate with an interview in two weeks**: [08-interview-prep/07-two-week-cram-plan.md](08-interview-prep/07-two-week-cram-plan.md), which pulls from everything else.

## Modules

| # | Module | What you get |
| --- | --- | --- |
| 00 | [Fast track](00-fast-track.md) | Run it, trace one flow, make one safe change — in a weekend |
| 01 | [Codebase cartography](01-codebase-cartography/README.md) | System map, reading order, glossary, tooling, 6 key flows |
| 02 | [Stack & language mastery](02-stack-and-language-mastery/README.md) | Node/TS/React mental models anchored to real files |
| 03 | [Architecture & patterns](03-architecture-and-patterns/README.md) | Layers, persistence, auth, async reliability, 14 pattern cards, critique |
| 04 | [Code reading gym](04-code-reading-gym/README.md) | Annotation drills, trace tables, fake-code contrasts, review katas |
| 05 | [Quality engineering](05-quality-engineering/README.md) | Testing, debugging, performance, security, observability |
| 06 | [Contribution practice](06-contribution-practice/README.md) | 15 junior tickets, 10 mid tickets, 5 senior projects, katas |
| 07 | [Career & collaboration](07-career-and-collaboration/README.md) | Review mindset, PRs/RFCs, maintainer communication |
| 08 | [Interview prep](08-interview-prep/README.md) | 44+ question cards (60%+ repo-anchored), system design, STAR stories, cram plan |
| 09 | [Reference](09-reference/command-cheatsheet.md) | Commands, risk register, rubrics, verification log |
| — | [25 user stories](25-user-stories.md) | Upskilling backlog for the junior SWE, in story form |

## Conventions

- **File anchors**: `backend/src/lib/knex/index.ts:156-326` means "open that file at those lines." Relative links are given where practical. Line numbers were verified against this working copy on 2026-07-09; if the repo has been updated since, search for the named symbol instead.
- **Fake code**: every snippet not from this repo starts with `// Illustrative fake code: not from this repo.` Everything else is real.
- **Verified vs inferred**: commands marked *verified* were actually run during curriculum authoring; *inferred* means read from config/scripts but not executed (see [09-reference/verification-log.md](09-reference/verification-log.md)).
- **Drills and self-grading**: most sections end with a drill and a Basic/Solid/Strong rubric. Grade yourself honestly; the rubric describes observable behavior, not vibes.
- **Interview angle**: sections flag where the material maps to a real interview question, with junior/mid/senior answer contrasts.

## The mindset ladder

- **Junior asks**: "How do I make it work?"
- **Mid-level asks**: "Is this the right pattern? What are the tradeoffs?"
- **Senior asks**: "What does this commit us to, who pays the cost, and how do we reduce risk?"

Interviews for mid-level roles are testing exactly the second and third questions. When an interviewer asks "how would you design pagination?", they are not checking whether you know `LIMIT/OFFSET` — they are checking whether you know when it breaks, what it costs, and what you'd do instead. Every module here feeds that muscle.
