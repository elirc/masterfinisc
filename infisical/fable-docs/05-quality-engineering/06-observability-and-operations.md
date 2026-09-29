# Observability and Operations

*Observability* — can you explain what the system did from its outputs alone? For each mechanism: what exists here, and the question it answers.

## What exists

| Signal | Implementation | Anchor |
| --- | --- | --- |
| **Logs** | pino, structured; pretty-printed in dev; deliberate info logs at security-relevant points | logger lib [backend/src/lib/logger/](../../backend/src/lib/logger/); e.g. per-request actor logging in [inject-permission.ts:22-23](../../backend/src/server/plugins/auth/inject-permission.ts), sync intent log [secret-queue.ts:603](../../backend/src/services/secret/secret-queue.ts) |
| **Metrics** | OpenTelemetry collector + Prometheus configs at repo root | [otel-collector-config.yaml](../../otel-collector-config.yaml), [prometheus.dev.yml](../../prometheus.dev.yml), `make up-dev-metrics` ([Makefile:13-14](../../Makefile)) |
| **Telemetry lib** | in-code hooks | [backend/src/lib/telemetry/](../../backend/src/lib/telemetry/) |
| **Health check** | `GET /api/status` — reports date, email/redis/config flags | [routes/index.ts:3507-3520](../../backend/src/server/routes/index.ts); e2e'd in [status.spec.ts](../../backend/e2e-test/routes/v1/status.spec.ts) |
| **Audit log** | first-class product feature: DAL + queue + service (ClickHouse-backed option) | [backend/src/ee/services/audit-log/](../../backend/src/ee/services/audit-log/); `injectAuditLogInfo` plugin registered with the auth chain ([routes/index.ts:3504](../../backend/src/server/routes/index.ts)) |
| **Failure escalation** | failed-sync notification emails | [secret-queue.ts:652-656](../../backend/src/services/secret/secret-queue.ts) |
| **Error taxonomy** | typed errors per layer with distinct names — logs become self-localizing | [backend/src/lib/errors/](../../backend/src/lib/errors/), plus [lib/error-codes/](../../backend/src/lib/error-codes/) |

Plugin registration order is itself operational knowledge: identity → assume-privilege → permission → rate limits → audit-log info ([routes/index.ts:3500-3504](../../backend/src/server/routes/index.ts)) — audit metadata is attached to *every* request context after auth resolves.

## "How would I know this broke?" — per key flow

| Flow | Detection today | Gap to notice |
| --- | --- | --- |
| Create secret (Flow 1) | 4xx/5xx rates in metrics; audit log entry per mutation | client-side invalidation bugs invisible to server signals |
| List secrets (Flow 2) | latency metrics; slow-query visibility via DB stats | replica lag staleness looks like "no error" everywhere |
| Auth (Flow 3) | 401/403 spikes; distinct error names localize the gate | message-string contract with the client isn't monitored (Scenario 4) |
| Sync fan-out (Flow 4) | retry exhaustion → email; queue depth in Redis | email as the terminal alert channel — pages nobody at 3am |
| Webhooks (Flow 5) | per-webhook failure state (check webhook status fields) | partner-side latency/timeouts need timeout metrics |
| Session refresh (Flow 6) | nothing server-side distinguishes "refresh worked" from "user re-logged-in" | client telemetry gap |

Deploy/rollback: containerized (standalone Dockerfiles, compose files); DB migrations auto-run on boot via [auto-start-migrations.ts](../../backend/src/auto-start-migrations.ts) (it has a colocated test) — meaning **rollback of code that shipped a migration is not just re-deploying the old image**; the migration's `down()` story matters (see [03/02-data-model](../03-architecture-and-patterns/02-data-model-and-persistence.md)).

## Transferable discipline

For every feature you ship, answer in the PR description: (1) what log line/metric proves it's working, (2) what signal fires when it breaks, (3) who sees that signal. If all three answers are "nothing," you shipped a stealth failure mode. This trio is also a killer closing line in system-design interviews.

## Drill

Pick ticket J-anything you plan to do from [06-contribution-practice](../06-contribution-practice/01-good-first-tickets.md) and pre-write its three observability answers. Self-grade — Weak: "I'd add logging." Solid: named the exact log line + where it surfaces. Strong: named the *absence* signal (how silence gets noticed), not just the error signal.
