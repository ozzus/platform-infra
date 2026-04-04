# Stage Rehearsal

Run this rehearsal before any `prod` promotion.

## Preconditions

- `nonprod` cluster is healthy
- Argo applications for addons and product services are healthy
- bootstrap secrets for `external-secrets` and `external-dns` are present
- certificates are issued for:
  - `auth.stage`
  - `web.stage`
  - `registry.stage`
  - `verify.stage`

## Functional checks

1. Log in as `university_operator_itmo` through live Keycloak.
2. Upload a file with `1000` diplomas.
3. Wait until the import finishes as `completed` or `partially_failed`.
4. If there are invalid rows, confirm `import_job_errors` are queryable and carry stable codes.
5. Verify newly imported diplomas through `diasoft-gateway`.
6. Revoke one diploma in `diasoft-registry`.
7. Confirm revoke propagation reaches `diasoft-gateway` in `p95 <= 30s`.
8. Log in as `student_001`.
9. Create a share link and open it through `diasoft-gateway`.
10. Open QR verification flow through `GET /v/{verificationToken}`.
11. Validate public HR verify without authentication.

## Operational checks

1. Run the rollback procedure from [rollback.md](./rollback.md).
2. Run the restore drill from [database-restore.md](./database-restore.md).
3. Trigger alert delivery smoke from [alert-delivery-smoke.md](./alert-delivery-smoke.md).
4. Verify Kafka lag handling from [kafka-lag.md](./kafka-lag.md).
5. Verify import backlog handling from [import-backlog.md](./import-backlog.md).
6. Verify DLQ replay path from [dlq-replay.md](./dlq-replay.md).

## Exit criteria

- all critical user flows are green
- rollback and restore were exercised successfully
- alerts were received
- no blocker remains open in `stage`
- stage sign-off is recorded before `prod` promotion
