### Mission 18: Reverse-Engineer the Architecture Decisions
**Tier:** Senior
**Time Estimate:** 60 minutes
**Goal:** Infer why the system is shaped this way.
**The Concept:** Architecture is a trail of tradeoffs. Infisical optimizes for explicit contracts around sensitive secrets.
**Design Intent Before You Read the Code:** Look for routing, service factories, typed hooks, generated schemas, audit, and auth boundaries.
**Find It In The Code:** Open [CLAUDE.md:60-68], [backend/src/main.ts:91-104], [backend/src/server/app.ts:180-201], [frontend/src/hooks/api/dashboard/queries.tsx:29-88].

```text
Explicit dependencies + typed hooks + Zod routes + generated schemas = reviewable boundaries for a security product.
```

**The Aha Moment:** The architecture favors traceability over hidden magic.
**Socratic Checkpoint:** Why no broad IoC? Why query-key factories? Why generated schemas? Why route-level audit? Why auth modes at route level?
How to self-grade: strong answers cite [CLAUDE.md:60-68], [backend/src/main.ts:91-104], [backend/src/server/routes/v4/secret-router.ts:168-248].
**Connects To:** Mission 19 and Mission 24.

### Mission 19: Find the Bugs Before They Happen
**Tier:** Senior
**Time Estimate:** 60 minutes
**Goal:** Predict likely regressions from the code shape.
**The Concept:** Senior debugging is seeing stress fractures before the vault door jams.
**Design Intent Before You Read the Code:** Search for duplicated invalidation, mixed responsibilities, casts, and security-sensitive audit data.
**Find It In The Code:** Open [frontend/src/hooks/api/secrets/mutations.tsx:57-210], [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-837], [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:793-801], [backend/src/server/routes/v4/secret-router.ts:515-519].

```text
Bug prediction:
cache drift -> stale UI
pending merge drift -> phantom rows
any cast -> shape bug
audit mask drift -> sensitive log leak
```

**The Aha Moment:** The riskiest code is often the code that coordinates many concerns.
**Socratic Checkpoint:** Which invalidation could be forgotten? Which pending merge branch is hardest to reason about? Where is `any` used? What audit field is sensitive? What extraction would reduce risk?
How to self-grade: strong answers cite all four file ranges above.
**Connects To:** Mission 20 and Mission 23.

### Mission 20: The Bug Injection Challenge
**Tier:** Senior
**Time Estimate:** 70 minutes
**Goal:** Design tests from user-visible symptoms.
**The Concept:** A bug report is smoke; your job is to identify which vault room is burning.
**Design Intent Before You Read the Code:** Symptoms should map to route, hook, cache, permission, or state failures.
**Find It In The Code:** Open [frontend/src/config/request.ts:52-88], [frontend/src/hooks/api/secrets/mutations.tsx:57-86], [backend/src/server/routes/v4/secret-router.ts:170-182], [frontend/src/pages/secret-manager/SecretDashboardPage/components/SecretListView/SecretItem.tsx:175-183].

```text
Symptom -> likely layer:
stale after create -> mutation invalidation
many refresh calls -> Axios refreshPromise
wrong service-token scope -> backend route scope normalization
editable forbidden secret -> UI permission check
```

**The Aha Moment:** Good bug tests start from behavior, then force the suspected layer to prove itself.
**Socratic Checkpoint:** Which symptom belongs to cache? Which belongs to auth? Which belongs to permission UI? Which belongs to token refresh? Which one needs backend e2e?
How to self-grade: strong answers cite the exact ranges above and propose one assertion per symptom.
**Connects To:** Mission 23 and Mission 24.

### Mission 21: Performance X-Ray
**Tier:** Senior
**Time Estimate:** 60 minutes
**Goal:** Identify performance hot spots in the dashboard.
**The Concept:** Performance work is reducing unnecessary vault trips and unnecessary clipboard rewriting.
**Design Intent Before You Read the Code:** Look for render-time merges, broad invalidation, repeated filters, and large child trees.
**Find It In The Code:** Open [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-839], [frontend/src/hooks/api/secrets/mutations.tsx:57-210], [frontend/src/hooks/api/dashboard/queries.tsx:312-376].

```tsx
const mergedSecrets = getMergedSecretsWithPending(); // render-time derived data
const mergedFolders = getMergedFoldersWithPending(); // render-time derived data
// candidate: memoize or extract pure helper with tests
```

**The Aha Moment:** The first performance wins are often in derived state and cache scope.
**Socratic Checkpoint:** Which functions recompute during render? Which invalidations are broad? Where does placeholder data help? What would you memoize? What metric would prove improvement?
How to self-grade: strong answers cite [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-839] and [frontend/src/hooks/api/dashboard/queries.tsx:375-376].
**Connects To:** Mission 23.

### Mission 22: The Security Audit
**Tier:** Senior
**Time Estimate:** 70 minutes
**Goal:** Audit auth, CORS, audit logs, and token refresh.
**The Concept:** Security review is checking every vault entrance and every logbook.
**Design Intent Before You Read the Code:** Sensitive flows should authenticate, validate, mask, and avoid overly broad cross-origin trust.
**Find It In The Code:** Open [frontend/src/config/request.ts:22-130], [backend/src/server/app.ts:114-144], [backend/src/server/routes/v4/secret-router.ts:168-248], [backend/src/server/routes/v4/secret-router.ts:515-519].

```ts
onRequest: verifyAuth([AuthMode.JWT, AuthMode.SERVICE_TOKEN, AuthMode.IDENTITY_ACCESS_TOKEN]); // route entrance check
value: meta.isEncrypted ? AUDIT_LOG_SENSITIVE_VALUE : meta.value; // logbook masking
```

**The Aha Moment:** Security posture is the sum of many small explicit checks.
**Socratic Checkpoint:** Where are auth headers attached? Where are expired tokens refreshed? Which CORS routes are permissive? Which secret routes require auth? Where is metadata masked?
How to self-grade: strong answers cite [frontend/src/config/request.ts:22-130], [backend/src/server/app.ts:114-144], and [backend/src/server/routes/v4/secret-router.ts:168-248].
**Connects To:** Mission 23 and Mission 24.

### Mission 23: Write the Test That Doesn't Exist
**Tier:** Senior
**Time Estimate:** 90 minutes
**Goal:** Specify a high-value test for pending secret merge or route contract.
**The Concept:** A test is a vault drill: prove the door still locks after a change.
**Design Intent Before You Read the Code:** Pick behavior that is risky, deterministic, and close to business value.
**Find It In The Code:** Open [frontend/src/pages/secret-manager/SecretDashboardPage/SecretMainPage.store.tsx:301-483], [frontend/src/pages/secret-manager/SecretDashboardPage/SecretDashboardPage.tsx:696-781], [backend/src/server/routes/v4/secret-router.ts:404-559].

```ts
it("removes a pending update when the user reverts all changed fields", () => {
  // arrange existing secret
  // add pending update
  // add reverted pending update
  // expect pendingChanges.secrets to be empty
});
```

**The Aha Moment:** The best first test protects behavior a user would notice and a reviewer could miss.
**Socratic Checkpoint:** What behavior is risky? What input creates it? What output proves it? Should this be unit or e2e? What refactor makes it easier to test?
How to self-grade: strong answers cite state merge lines and explain why the test is deterministic.
**Connects To:** Mission 24.

### Mission 24: The Git History Tells a Story
**Tier:** Senior
**Time Estimate:** 45 minutes
**Goal:** Learn to infer architecture evolution from commit messages.
**The Concept:** Git history is the vault maintenance log.
**Design Intent Before You Read the Code:** A commit message should imply files, risks, and verification.
**Find It In The Code:** Use these realistic commit messages against anchors [frontend/src/config/request.ts:52-88], [frontend/src/hooks/api/secrets/mutations.tsx:57-210], [backend/src/server/routes/v4/secret-router.ts:404-730], [backend/src/db/schemas/secrets.ts:1-38].

```text
fix(auth): dedupe token refresh retries
feat(secrets): add encrypted metadata filters
perf(dashboard): memoize pending secret merge
security(audit): mask encrypted secret metadata
refactor(api): centralize secret cache invalidation
```

**The Aha Moment:** A good commit title tells you where to inspect first.
**Socratic Checkpoint:** Which files would each commit touch? What tests should accompany each? Which risks are security risks? Which are performance risks? Which are migration risks?
How to self-grade: strong answers map each message to at least two file ranges and one verification command.
**Connects To:** Mission 25 in `04-reference-artifacts.md`.
