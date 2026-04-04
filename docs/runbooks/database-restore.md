# Database Restore

1. Identify the environment and the database to restore: `registry`, `gateway`, or `keycloak`.
2. Freeze rollout in `platform-infra`:
   - stop image tag promotion
   - pause ArgoCD auto-sync for the affected application if needed
3. Select the latest known-good managed PostgreSQL backup or PITR target timestamp.
4. Restore into a new database or a new managed cluster first.
5. Run application smoke checks against the restored target:
   - `registry` health and import read paths
   - `gateway` verify by token and share-link read path
   - `keycloak` login and token issuance
6. Switch application secrets or connection endpoints through `platform-infra` values and secret refs.
7. Let ArgoCD reconcile the new runtime configuration.
8. Validate dashboards, error rates, and Kafka lag.
9. Record restore source, timestamps, and impact in the incident log.

## Validation checklist

- health and readiness are green
- auth works if `keycloak` or `registry` was restored
- `gateway` projection and public verify still work
- no unexpected migration reruns happened
- alerts are quiet after the cutover
