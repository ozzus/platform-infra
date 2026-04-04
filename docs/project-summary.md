# Project Summary

## Product goal from the specification

The platform verifies diploma authenticity for three primary actors:

- university operators import and manage diploma registries
- students receive QR verification and temporary share links
- HR users verify diplomas through public pages and API

Architectural constraints remain fixed:

- raw import rows are persisted in the source-of-truth system before event publication
- Kafka is only for inter-service synchronization
- public verification goes only through `diasoft-gateway`
- target runtime is production-grade: Kubernetes, PostgreSQL, Redis, Kafka, GitOps, CI/CD, OIDC, and observability

## Repository state by area

### `diasoft-gateway`

Implemented:

- public verify API and HTML routes
- PostgreSQL read model
- Redis cache and rate limiting
- Kafka consumer, DLQ, and replay worker
- Prometheus metrics and OpenTelemetry tracing
- managed Kafka SCRAM runtime config
- Docker-backed integration harness
- published-contract pull path

Main remaining gaps:

- prove live runtime against managed Kafka/Redis/PostgreSQL in nonprod
- finish infra-side alerting and rollout rehearsal

### `diasoft-registry`

Implemented:

- JWT-scoped internal APIs
- import jobs, worker, and outbox publisher
- CSV and XLSX import
- object storage integration
- Kafka schema and internal OpenAPI contracts
- Docker-backed integration slice
- Spring Kafka SASL runtime wiring for managed Kafka

Main remaining gaps:

- live CI/runtime verification is still the first hard proof point
- stage rehearsal for import, revoke, and outbox propagation still needs to happen

### `diasoft-web`

Implemented:

- OIDC runtime with `react-oidc-context`
- protected routing and `/api/v1/me` bootstrap
- live registry and gateway integrations
- generated types from contracts
- component tests and Playwright smoke

Main remaining gaps:

- live Keycloak-backed smoke in running `dev/stage`
- final UX/error polish

### `platform-infra`

Implemented:

- real Yandex resource model in Terraform for `nonprod` and `prod`
- managed service topology for Kubernetes, PostgreSQL, Redis, Kafka, object storage, IAM, and Lockbox
- addon Argo applications for ingress, cert-manager, external-secrets, external-dns, monitoring, logging, and tracing
- repo-managed addon values files consumed by Argo for every addon/environment
- local cluster bootstrap manifests for issuer, secret store, alert rules, and Alertmanager routing
- environment overlays for `dev`, `stage`, and `prod`
- app sync ordering and namespace creation in Argo
- manual live smoke jobs in CI for `dev` and `stage` endpoint checks
- cutover-oriented runbooks and checklist
- explicit stage rehearsal runbook for pre-prod validation
- local compose-based single-host stack for developer onboarding and smoke checks

Main remaining gaps:

- live apply / sync / smoke validation
- external-secrets and external-dns bootstrap secrets still need real environment provisioning
- bootstrap secret rendering is now scripted from Terraform outputs
- restore, rollback, and alert delivery must still be exercised in `stage`

## Production-ready assessment

### Overall readiness

Current overall platform readiness is approximately **90%**.

This is close to `prod cutover ready`, but not yet there because the remaining blockers are live-runtime and rehearsal blockers, not code-structure blockers.

### Approximate readiness by repository

- `diasoft-gateway`: **91%**
- `diasoft-web`: **91%**
- `diasoft-registry`: **84%**
- `platform-infra`: **88%**

### What still blocks 100%

The platform is not yet `prod cutover ready` because the following are still open:

- Terraform and Argo changes have not yet been proven against live Yandex Cloud resources
- bootstrap secrets for external-secrets and external-dns still need environment provisioning
- live `dev` and `stage` must validate OIDC, imports, projection, revoke, share-link, and QR flows
- restore, rollback, and alert delivery must be exercised in a running environment

## Bottom line

The codebase is now broadly production-shaped.
The main remaining gap is no longer repository structure or missing core code, but live platform execution and cutover rehearsal.
