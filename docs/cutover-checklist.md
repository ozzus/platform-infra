# Prod Cutover Checklist

Use this checklist only after `stage` is green.

Reference rehearsal:

- [Stage Rehearsal](./runbooks/stage-rehearsal.md)

## Contracts and artifacts

- image tags are pinned in `platform-infra`
- registry and gateway contract versions are pinned
- all publish jobs for contracts and images are green
- images are signed
- SBOM artifacts are available

## Environment state

- Argo applications are healthy in `prod`
- ingress, cert-manager, external-secrets, monitoring, logging, and tracing addons are healthy
- External Secrets resolved successfully
- Keycloak is healthy and production bootstrap users are absent
- certificates are issued for:
  - `auth`
  - `web`
  - `registry`
  - `verify`

## Functional rehearsal from `stage`

- import `1000` diplomas completed or partially failed with queryable row errors
- projection reached gateway
- revoke propagation stayed within `p95 <= 30s`
- share-link flow passed
- QR flow passed
- public HR verify passed

## Operational rehearsal from `stage`

- rollback runbook executed successfully
- PostgreSQL restore drill executed successfully
- alert delivery smoke passed
- Kafka lag handling verified
- DLQ replay path verified

## Approval gate

- stage sign-off recorded
- production approval recorded
- rollback owner assigned
- incident contacts available for cutover window
