# Security Checklist

Threat-by-threat map to real code, then a pre-merge checklist. In a secrets manager, security review *is* code review.

| Threat | What it is | Where this repo defends | Notes for review |
| --- | --- | --- | --- |
| **Broken authorization** | endpoint forgets to check what, not who | CASL in services, ABAC subjects ([secret-v2-bridge-service.ts:339-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)); vocab in [project-permission.ts](../../backend/src/ee/services/permission/project-permission.ts) | Every new service method: which action+subject does it assert? |
| **IDOR** | acting on someone else's resource by id | scoped lookups (project/env/path chains); org context required ([permission-service.ts:416-418](../../backend/src/ee/services/permission/permission-service.ts)) | id-based routes ([secret-router.ts:252](../../backend/src/server/routes/v4/secret-router.ts)) deserve extra scrutiny |
| **Input validation** | malformed/hostile payloads | Zod on every route; transforms with `superRefine` limits ([secret-router.ts:64-120](../../backend/src/server/routes/v4/secret-router.ts)) | hand-rolled parsers inside schemas need their own tests |
| **SSRF** | server fetches attacker-chosen URL | `blockLocalAndPrivateIpAddresses` / `ssrfSafeGet/Post` ([validate-url.ts:13](../../backend/src/lib/validator/validate-url.ts), exports at [validator/index.ts:13](../../backend/src/lib/validator/index.ts)); unit-tested | check *send-time* revalidation for stored URLs (rebinding) |
| **XSS** | injected script in the UI | React's default escaping; Tailwind (no injected style attrs) | grep any new `dangerouslySetInnerHTML`; secret *values* are user content — never render as HTML |
| **CSRF** | cross-site request with ambient creds | Bearer tokens in headers (not ambient cookies) for API calls ([request.ts:22-44](../../frontend/src/config/request.ts)) | any cookie-based session addition reopens this class |
| **Injection (SQLi)** | string-built queries | Knex parameterized builders throughout `ormify`/DALs | review any `knex.raw` with interpolation; migrations use raw but with static/config values ([20260513182201...](../../backend/src/db/migrations/20260513182201_add-folder-id-indexes-for-snapshot-prune.ts)) |
| **Secrets at rest** | DB dump leaks everything | envelope encryption via KMS data keys (`createCipherPairWithDataKey`, [webhook-service.ts:33](../../backend/src/services/webhook/webhook-service.ts)); HSM support in e2e bootstrap | new sensitive columns must be encrypted like their neighbors (Kata 5) |
| **Token handling** | leaked/eternal credentials | short-lived JWTs + refresh ([request.ts:59-131](../../frontend/src/config/request.ts)); deprecated long-lived modes being phased out ([CLAUDE.md](../../CLAUDE.md)) | never log tokens; check new log lines |
| **Rate limiting** | brute force, scraping | per-route `config.rateLimit` presets (`secretsLimit`, [secret-router.ts:10, 51-52](../../backend/src/server/routes/v4/secret-router.ts)) | new routes must pick a preset consciously |
| **Webhook/outbound** | data exfil via user-configured endpoints | URL validation + encrypted storage + async isolation ([webhook flow](../01-codebase-cartography/05-key-flows.md#flow-5-webhook-trigger-outbound-side-effect--ssrf-defense)) | payload minimization: send events, not secret values |
| **Supply chain** | malicious dependency update | `min-release-age=7` both `.npmrc`s (*verified*); FIPS-conscious dep policy | new deps: justify, pin, check maintenance |
| **Audit** | no forensic trail | audit-log service ([backend/src/ee/services/audit-log/](../../backend/src/ee/services/audit-log/)) | every new mutating endpoint: does it emit an audit event? |

Not deeply mapped here (verify per feature): open redirects (check any redirect param handling in auth pages), file uploads (external-migration import paths), cookie flags ([e2e-test/testUtils/cookies.ts](../../backend/e2e-test/testUtils/cookies.ts) hints at cookie use in auth — investigate flags).

## Pre-merge security checklist (use on every PR you write here)

- [ ] Every new route: `verifyAuth` present with a *deliberate* mode list; rate-limit preset chosen
- [ ] Every new service method: CASL action + subject asserted; actor context threaded, not defaulted
- [ ] Resource lookups scoped to the caller's org/project — no bare `findById(reqParam)` trust
- [ ] All input crosses a Zod schema; no `any` DTOs
- [ ] User-supplied URLs → SSRF validator; user-supplied HTML → nowhere
- [ ] New sensitive data encrypted at rest; nothing sensitive in logs or error messages
- [ ] Errors don't leak existence of other tenants' resources (403 vs 404 policy consistent)
- [ ] Mutating endpoints emit audit events
- [ ] New deps justified; no lockfile surprises
- [ ] Tests include at least one *negative* case (403/400/cross-tenant)

Interview angle: OWASP-style questions ("prevent SSRF/XSS/CSRF?") land constantly at mid-level. Answering with *this repo's* mechanism plus the residual risk (e.g. "blocklist at create-time; rebinding needs send-time checks") beats any memorized definition. Cross-linked from [08-interview-prep/03](../08-interview-prep/03-api-and-data-modeling-questions.md).
