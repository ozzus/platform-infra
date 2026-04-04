# Keycloak Outage

1. Confirm whether the issue is:
   - ingress/TLS
   - Keycloak pod health
   - PostgreSQL connectivity
   - secret resolution
2. Check:
   - `keycloak` readiness/liveness
   - DB credentials from External Secrets
   - ingress and certificate status
3. If the outage is caused by a bad release:
   - revert the `keycloak` image tag or values change in `platform-infra`
   - let ArgoCD sync the previous revision
4. If the outage is DB-related:
   - validate managed PostgreSQL availability
   - rotate or re-sync DB secret refs if needed
5. Validate recovery with:
   - browser login
   - token issuance for `diasoft-web`
   - `/api/v1/me` session bootstrap in `diasoft-registry`

## Escalation criteria

- login unavailable in `stage` or `prod` for more than 5 minutes
- repeated readiness failures after rollback
- certificate or DNS mismatch for `auth.<env>.<domain>`
