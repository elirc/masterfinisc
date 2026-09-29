# Domain Glossary

Product nouns, mapped to code. The fastest way to sound like you belong in a codebase — or an interview about it — is using its nouns precisely.

| Term | Meaning | Code location |
| --- | --- | --- |
| **Organization (org)** | Top-level tenant. Everything hangs off an org; most requests are rejected without org context | `req.permission.orgId` set in [inject-permission.ts:16-20](../../backend/src/server/plugins/auth/inject-permission.ts); org check in [verify-auth.ts:27-29](../../backend/src/server/plugins/auth/verify-auth.ts) |
| **Sub-organization** | Orgs can nest; requests carry `rootOrgId` and `parentOrgId` | [inject-permission.ts:17-19](../../backend/src/server/plugins/auth/inject-permission.ts) |
| **Project** | A workspace inside an org holding secrets/certs/etc. Older code says `workspaceId` — same thing | Project routes/pages: [frontend/src/routes.ts:19](../../frontend/src/routes.ts) (`.../projects/secret-management/$projectId`) |
| **Environment** | Named slice of a project (dev/staging/prod), referenced by `slug` | `projectEnvDAL` in [secret-service.ts:114](../../backend/src/services/secret/secret-service.ts); env in query keys [queries.tsx:35-41](../../frontend/src/hooks/api/secrets/queries.tsx) |
| **Folder / secret path** | Secrets live in folder trees per environment; `secretPath` like `/app/db` resolves to a folder id | `folderDAL.findBySecretPath` call in [secret-v2-bridge-service.ts:304](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) |
| **Secret (Shared vs Personal)** | `SecretType.Shared` is the team value; `SecretType.Personal` is a per-user override that must shadow an existing shared secret | Enum in [db/schemas/models.ts:363](../../backend/src/db/schemas/models.ts); the shadow rule enforced in [secret-v2-bridge-service.ts:312-329](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts) |
| **Secret version** | Every update bumps `version`; enforced by the DAL's `update` override | [secret-dal.ts:14-21](../../backend/src/services/secret/secret-dal.ts) |
| **Identity** | A *machine* actor (CI job, server) that authenticates via identity auth methods and gets an `IDENTITY_ACCESS_TOKEN` | Actor branch in [inject-permission.ts:25-33](../../backend/src/server/plugins/auth/inject-permission.ts); dozens of `identity-*-auth` services in [backend/src/services/](../../backend/src/services/) |
| **Service token** | *Deprecated* machine auth (`st.`-prefixed Bearer). Exists for compat; do not use in new code | [CLAUDE.md](../../CLAUDE.md) auth section; still handled in [inject-identity.ts](../../backend/src/server/plugins/auth/inject-identity.ts) |
| **v2 bridge** | The *current* secrets engine (`secret-v2-bridge/`). "Bridge" is migration residue from moving off the blind-index engine in `services/secret/` | [secret-v2-bridge-service.ts](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts); migration entry `startSecretV2Migration` in [secret-service.ts:123-126](../../backend/src/services/secret/secret-service.ts) |
| **Blind index** | Legacy: a keyed hash of a secret name enabling lookup-by-name over encrypted rows without decrypting | `secretBlindIndexDAL` in [secret-service.ts:120](../../backend/src/services/secret/secret-service.ts) |
| **Approval policy / approval request** | Changes to protected paths require review before applying — a PR workflow for secrets | `secretApprovalPolicyService` / `secretApprovalRequestService` deps in [secret-service.ts:130-134](../../backend/src/services/secret/secret-service.ts) |
| **Snapshot / folder commit** | Point-in-time capture of a folder for history/rollback; commits power the CommitsPage UI | `snapshotService.performSnapshot` dep in [secret-service.ts:122](../../backend/src/services/secret/secret-service.ts); commits routes in [frontend/src/routes.ts:27-35](../../frontend/src/routes.ts) |
| **Secret sync / integration** | Pushing secrets outward to third parties (GitHub, AWS, ...) via queue jobs | [secret-queue.ts:594-660](../../backend/src/services/secret/secret-queue.ts) |
| **Secret reference** | A secret whose value interpolates another secret; forms a tree | `SecretReferenceNodeTree` in [secret-router.ts:40-44](../../backend/src/server/routes/v4/secret-router.ts) |
| **KMS / data key** | Envelope encryption: per-project data keys wrapped by a root key; services get `createCipherPairWithDataKey` | dep in [webhook-service.ts:33](../../backend/src/services/webhook/webhook-service.ts) |
| **Actor** | Who a request acts as: `USER`, `IDENTITY`, `SERVICE`, `SCIM_CLIENT`, `GATEWAY` | All five branches in [inject-permission.ts:12-79](../../backend/src/server/plugins/auth/inject-permission.ts) |

## Confusing near-synonyms (interviewers love asking you to disambiguate)

- **AuthMode vs Actor**: AuthMode is *how* you authenticated (JWT, IDENTITY_ACCESS_TOKEN...); Actor is *what kind of principal* you are (USER, IDENTITY...). One actor type can arrive via multiple auth modes.
- **projectId vs workspaceId**: same entity, different eras. Expect both in DTOs.
- **environment (slug) vs folder**: environment is the named top-level slice; folders nest *inside* an environment. `secretPath` is meaningless without both.
- **secret sync vs secret replication**: sync pushes to external integrations; replication copies between Infisical projects/environments (separate queue, [secret-queue.ts:582-591](../../backend/src/services/secret/secret-queue.ts)).
- **permission vs privilege**: permission is the CASL ability computed from roles; "additional privilege" / "assumed privilege" are scoped escalations layered on top ([inject-assume-privilege.ts](../../backend/src/server/plugins/auth/inject-assume-privilege.ts), checked in [permission-service.ts:429+](../../backend/src/ee/services/permission/permission-service.ts)).

## Drill

Explain to a rubber duck why a *personal* secret creation fails if no shared secret with that key exists (anchor: [secret-v2-bridge-service.ts:324-329](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)) — then say what invariant this protects. Strong answer: personal secrets are *overrides*, so an orphan personal secret would be invisible to teammates and leak divergence between what the user sees and what the team ships.
