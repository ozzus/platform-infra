# Import Backlog

1. Check `registry-import-worker` replica count, CPU, memory, and recent error logs.
2. Inspect `import_jobs` status distribution:
   - `pending`
   - `processing`
   - `partially_failed`
   - `failed`
3. Validate object storage access and PostgreSQL health.
4. If backlog is throughput-bound and the system is healthy:
   - scale `registry-import-worker` up within allowed limits
5. If backlog is error-bound:
   - inspect stable row error codes
   - confirm whether the problem is data quality or runtime failure
6. Check whether `outbox_events` backlog is also increasing.
7. After mitigation, verify:
   - new imports move forward
   - `gateway` starts receiving projections
   - error rate is back to baseline

## Escalate when

- imports stop progressing for more than 10 minutes
- repeated worker restarts occur
- `pending + processing` keeps growing after scale-up
