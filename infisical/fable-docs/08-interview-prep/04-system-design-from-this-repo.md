# System Design From This Repo

The exercise: **"Design a secrets management platform (like Vault/Infisical) for engineering teams."** You will walk it as a whiteboard interview — and at every step, compare your answer to what this repo actually chose (with anchors). Practicing design against a system whose real tradeoffs you can inspect is the highest-leverage prep there is. Cross-reference: [03/06-architecture-critique](../03-architecture-and-patterns/06-architecture-critique.md).

## Step 1 — Requirements (5 min in the room)

Functional: orgs → projects → environments → folder trees of secrets; human + machine access; versioning/rollback; change approval for protected paths; push to third parties (CI, cloud providers); webhooks; audit everything.
Non-functional: secrets confidential at rest and in logs (encryption, non-negotiable); correctness of authorization > availability; read-heavy (every deploy fetches); writes rare but fan out; self-hostable.
*Junior answer*: jumps to tables. *Mid*: states read/write asymmetry and the security bar. *Senior*: also names the *tenancy model* and compliance/audit as first-class, asks who the actors are (humans AND machines — it changes auth entirely).

## Step 2 — API sketch

Versioned REST, schema-first. `GET/POST/PATCH/DELETE /api/v1/secrets[/:name]` scoped by `projectId + environment + secretPath`; separate auth endpoints; machine identities distinct from users.
What the repo chose: exactly this, times four versions ([routes/index.ts:3572-3591](../../backend/src/server/routes/index.ts)), Zod-schema routes generating OpenAPI ([secret-router.ts:48-170](../../backend/src/server/routes/v4/secret-router.ts)).
Alternative: GraphQL (flexible reads; but versioning/auth-per-field complexity is hostile to a security product); gRPC for machine access (faster, but self-hosted simplicity favors REST).
*Mid*: names auth modes per route. *Senior*: notes response schemas are commitments, plans additive evolution to *avoid* v5.

## Step 3 — Data model

Spine: `orgs → projects → environments → folders (tree) → secrets → secret_versions`; memberships with roles; personal overrides as typed rows; tags m:n.
What the repo chose: exactly this spine ([glossary](../01-codebase-cartography/03-domain-glossary.md)); versions as immutable rows with a DAL-enforced counter ([secret-dal.ts:14-21](../../backend/src/services/secret/secret-dal.ts)); 272 tables total because every feature (approvals, snapshots, integrations) gets real tables.
Alternative: JSONB blobs per environment (simpler, but kills per-secret permissions, versioning granularity, and indexes); a KV store like Vault's (operationally different beast).
*Mid*: gets the spine + versions right. *Senior*: talks invariant placement (shadow rule, unique-shared-key) and *where* each is enforced — plus the check-then-insert race if only enforced in code.

## Step 4 — Security architecture (the differentiating step)

AuthN: short-lived JWTs for humans; identity tokens for machines (issued via cloud-native auth: AWS/GCP/K8s attestation — see the dozen `identity-*-auth` services in [backend/src/services/](../../backend/src/services/)).
AuthZ: ABAC — abilities built per request, asserted in the service layer with attribute subjects ([secret-v2-bridge-service.ts:339-347](../../backend/src/services/secret-v2-bridge/secret-v2-bridge-service.ts)).
Encryption: envelope — per-project data keys wrapped by root key/HSM; decrypt in service layer, never at rest or in logs.
*Junior*: "hash passwords, use HTTPS." *Mid*: separates authn/authz, names envelope encryption. *Senior*: adds fail-closed defaults, audit as a product feature, SSRF containment for user URLs ([validate-url.ts:13](../../backend/src/lib/validator/validate-url.ts)), and the deprecation path for legacy credential types.

## Step 5 — Write path and async fan-out

Write: validate → authorize → tx (secret + version) → *then* enqueue sync/webhook/replication jobs with retries, backoff, dedupe ([secret-queue.ts:568-660](../../backend/src/services/secret/secret-queue.ts)).
Alternative: synchronous push (simple, but partner latency in the user's request and no retry story); event streaming (Kafka — heavier ops for self-hosters).
*Mid*: queue with retries + idempotency. *Senior*: at-least-once semantics stated explicitly, dedupe-key design, failure escalation to humans, and the outbox gap called out with its crash window ([critique](../03-architecture-and-patterns/06-architecture-critique.md)).

## Step 6 — Read path and scaling

Reads: replica routing at the data layer ([lib/knex/index.ts:168](../../backend/src/lib/knex/index.ts)), server-side caching with project-scoped invalidation, client caching with staleTime ([reactQuery.tsx:222-224](../../frontend/src/hooks/api/reactQuery.tsx)).
Scaling story at 10x: replicas for reads; queue workers scale horizontally (stateless); Postgres primary is the write bottleneck — fine, writes are rare; permission-build cost per request is the tax to watch.
*Senior*: names the *three* staleness boundaries (client cache, server cache, replica lag) and their bounds; declines to shard prematurely and says why.

## Step 7 — Operability

Health endpoint, structured logs with actor context, metrics via OTel/Prometheus, audit trail, failure emails ([05/06](../05-quality-engineering/06-observability-and-operations.md)). Migrations auto-run at boot — deploy and migrate are coupled; rollback story must be stated.

---

## Variation prompts (practice each as a 10-min delta)

1. **Add multi-region active-active.** (Secrets replication semantics, conflict policy — last-write-wins is scary here; per-region primaries per project?)
2. **10x machines fetch secrets every 60s.** (Read path caching with authz-aware keys; lease/TTL model; CDN is NOT an answer for secrets — why?)
3. **Add real-time collaboration.** (Project P3's design: SSE invalidation hints, least-privilege channels, no values on the wire.)
4. **A customer demands bring-your-own-KMS.** (Key hierarchy abstraction; what breaks in the crypto boundary; blast radius of a bad KMS integration.)
5. **Regulator asks: prove nobody read secret X.** (Audit completeness — read-audit vs write-audit cost; the answer changes the read path's performance budget.)

## Grading yourself (per full run)

**Junior-sounding**: feature list, one big diagram, no failure modes. **Mid**: layered walk with authn/authz split, queue reliability vocabulary, one alternative per major choice. **Senior**: invariants named with enforcement points, staleness boundaries bounded, one deliberate "not building X because Y", and every claim attachable to a real file in this repo if challenged. Run it aloud in 35 minutes, twice, before any real loop.
