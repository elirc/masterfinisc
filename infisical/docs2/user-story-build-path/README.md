# User Story Build Path

Use these stories like real tickets. Each story names likely files, acceptance criteria, implementation steps, tips, and failure modes. Start with Story 1 even if it feels small; the early stories teach safe edits before the later stories ask you to cross UI, API, backend, and database boundaries.

Difficulty progression:

- Stories 1-3: easy UI/type changes in one or two files.
- Stories 4-5: medium-easy UI features that read existing data.
- Stories 6-7: medium features needing a new hook, endpoint, or state path.
- Stories 8-9: hard full-stack changes across frontend, backend, and persistence.
- Story 10: expert architectural work involving performance, caching, or auth implications.

A story is done when every acceptance criterion is independently verifiable, the touched files follow local patterns, and you can explain the change by citing the same kinds of anchors used here: route/page code [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:105-1150], API hooks [frontend/src/hooks/api/secrets/mutations.tsx:25-210], backend routes [backend/src/server/routes/v4/secret-router.ts:47-730], and persistence [backend/src/db/schemas/secrets.ts:10-38].

When you get stuck, ask an assistant for coaching, not a solution:

```text
I'm working on Story X. I'm stuck on Y. Here is what I've tried: Z.
Don't give me the solution. Ask me questions that help me figure it out.
Use this repo's patterns and point me to files or line ranges I should re-read.
```

