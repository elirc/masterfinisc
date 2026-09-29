# Architectural Cartographer

This suite is a top-down map for learning this Infisical codebase as a system. It starts with the app shape, then drills into frontend entry, backend entry, routing, API hooks, permissions, state, persistence, and the secrets-management flow. The core evidence comes from the Vite/TanStack Router frontend entry [frontend/src/main.tsx:1-100], the root provider route [frontend/src/pages/root.tsx:1-35], the Fastify backend bootstrap [backend/src/main.ts:35-148], the Fastify app factory [backend/src/server/app.ts:59-207], and the v4 secrets router [backend/src/server/routes/v4/secret-router.ts:47-248].

Read in this order:

1. `JOURNAL.md` for the inspection notes and why the chosen anchors matter.
2. `00-reading-map.md` for the shortest path through the repo.
3. `01-junior-engineer.md` for setup, folders, entry points, and basic anatomy.
4. `02-mid-level-engineer.md` for contracts, state, and end-to-end tracing.
5. `03-senior-engineer.md` for critique, risks, tests, and ownership.
6. `04-reference-suite.md` when you are actively reviewing, debugging, or planning a feature.

For checkpoints, answer before reading the rubric, then compare against the self-grade section. The goal is not memorization. The goal is to learn how a senior engineer asks, "Where does this data enter, who validates it, who is allowed to touch it, where is it persisted, and how does the UI recover when it changes?"

