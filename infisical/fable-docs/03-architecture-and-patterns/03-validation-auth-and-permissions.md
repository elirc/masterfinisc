# Validation, Auth, and Permissions

## The validation stack — five layers, five different jobs

| Layer | Job | Real anchor | If it's missing |
| --- | --- | --- | --- |
| 1. UI form (react-hook-form + Zod) | UX: instant feedback | form schemas across `frontend/src/pages/` | Annoying UX; **zero** security impact |
| 2. Route schema (Zod) | Contract: shape, types, parsing, limits | `metadataFilter` transform + `superRefine` max-10 rule, [secret-router.ts:64-120](../../backend/src/server/routes/v4/secret-router.ts) | Garbage reaches services; 500s instead of 400s |
| 3. Service business rules | Invariants: folder exists, no duplicate shared secret, personal-shadows-shared | [secret-v2-bridge-service.ts:304-336](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) | Corrupt domain state |
| 4. Security validators | Trust: SSRF guard on user URLs | [validate-url.ts:13](../../backend/src/lib/validator/validate-url.ts), used by webhooks ([webhook-service.ts:9](../../backend/src/services/webhook/webhook-service.ts)) | Server becomes an attack proxy |
| 5. DB constraints | Last line: FKs, uniques, not-null | migrations + schemas | Race conditions become corruption |

The junior mistake is believing layer 1 or 2 "already validated it." Each layer defends against a different adversary: 1 against typos, 2 against malformed clients, 3 against valid-but-wrong requests, 4 against hostile input, 5 against concurrency and bugs in 1–4.

## Authentication: who are you

Covered as Flow 3 in [key-flows](../01-codebase-cartography/05-key-flows.md); the short version:

1. [inject-identity.ts:93-155](../../backend/src/server/plugins/auth/inject-identity.ts) — `extractAuth` sniffs `x-api-key` (deprecated) then Bearer JWT, switching on `authTokenType` (line 112) → `req.auth` with an `AuthMode` and an actor.
2. [inject-permission.ts:12-79](../../backend/src/server/plugins/auth/inject-permission.ts) — actor → `req.permission = {type, id, orgId, rootOrgId, parentOrgId}`.
3. [verify-auth.ts:10-32](../../backend/src/server/plugins/auth/verify-auth.ts) — per-route allowlist of auth modes + org-context requirement.

## Authorization: what may you do (CASL)

The ability is built per request in [permission-service.ts:405-470](../../backend/src/ee/services/permission/permission-service.ts) from the actor's roles (+ assumed privileges), then services assert:

```ts
// Real code — backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts:339-347
ForbiddenError.from(permission).throwUnlessCan(
  ProjectPermissionSecretActions.Create,
  subject(ProjectPermissionSub.Secrets, { environment, secretPath, secretName, secretTags })
);
```

Three things to notice, in ascending seniority:

1. The **action vocabulary** is an enum per domain ([project-permission.ts:15](../../backend/src/ee/services/permission/project-permission.ts) general actions; line 45 secret-specific actions; line 323 the subject list) — permissions are structured data, not string soup.
2. Checks are **attribute-based (ABAC)**, not just role-based: the subject carries environment, path, name, and tags, so a role can be scoped to `env=prod, path=/payments/**`. That's why glob/boundary logic has unit tests ([lib/casl/boundary.test.ts](../../backend/src/lib/casl/boundary.test.ts), [glob-subset.test.ts](../../backend/src/lib/casl/glob-subset.test.ts)).
3. **Fail-closed**: `getProjectPermission` throws if org context is missing ([permission-service.ts:416-418](../../backend/src/ee/services/permission/permission-service.ts)); service tokens get a separate, narrower evaluator (line 420-427).

## Tenant and resource isolation (IDOR)

*IDOR* — Insecure Direct Object Reference: I pass *your* resource's id and the server forgets to check it's yours. Defenses in this repo:

- Org scoping rides on every request (`req.permission.orgId`), and project permission construction requires it.
- Object lookups resolve through project/environment/folder chains rather than trusting a bare id (folder lookup by `projectId + environment + path`, [secret-v2-bridge-service.ts:304](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)).
- The frontend mirrors checks for UX only — `useProjectPermission()` ([OverviewPage.tsx:300](../../frontend/src/pages/secret-manager/OverviewPage/OverviewPage.tsx)) hides buttons; the server decision is the real one.

**What a junior misses vs what a senior checks**: junior sees `verifyAuth` on the route and calls it secured. Senior asks: (a) does the *service* check the CASL action for this specific resource, (b) is the resource looked up scoped to the caller's org/project, (c) do *both* the id-based route (`GET /id/:secretId`, [secret-router.ts:252-274](../../backend/src/server/routes/v4/secret-router.ts)) and the name-based route enforce the same scoping, (d) what do error messages leak (404 vs 403 semantics — does "not found" vs "forbidden" reveal existence?).

## Drills

1. For `POST /api/v4/secrets/:secretName`, write the five-layer table above filled in with this route's actual specifics, from memory first.
2. Find the CASL check for secret *deletion* in [secret-v2-bridge-service.ts](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) (grep `throwUnlessCan` — hits at 560, 580, 599, 846...) and name its action + subject attributes.
3. Adversarial: sketch how you'd *test* for IDOR on the secret-by-id route (two users, two orgs, swap ids) — then check whether [e2e-test/routes/v3/auth-idp-attacks.spec.ts](../../backend/e2e-test/routes/v3/auth-idp-attacks.spec.ts) style exists for secrets (attack-style secret tests: not found — candidate contribution).

Self-grade — Basic: filled the table. Solid: correct action/subject for delete + coherent IDOR test plan. Strong: articulated 403-vs-404 information leakage and the ABAC scoping story unprompted.

Interview angle: authn-vs-authz, RBAC-vs-ABAC, and IDOR are all standard mid-level security questions — see [08-interview-prep/03](../08-interview-prep/03-api-and-data-modeling-questions.md) Q6–Q8 and [05-security-checklist](../05-quality-engineering/05-security-checklist.md).
