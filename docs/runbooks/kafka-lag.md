# Kafka Lag

1. Identify the lagging consumer:
   - `registry-outbox-publisher`
   - `gateway-consumer`
   - `gateway-dlq-replayer`
2. Check current lag, restart count, and recent error logs.
3. If `gateway-consumer` is lagging:
   - inspect PostgreSQL and Redis health
   - inspect `gateway.dlq.v1` volume
   - validate that projection errors are not looping
4. If `registry-outbox-publisher` is lagging:
   - inspect `outbox_events` backlog
   - inspect Kafka connectivity and broker health
5. Scale the affected deployment up within its allowed limits if the issue is throughput only.
6. If lag is caused by poison events:
   - fix the root cause first
   - use the gateway DLQ replay runbook only after the fix is confirmed
7. Close the incident only after lag returns to normal and no new error spikes appear.

## Signals to watch

- Kafka consumer lag
- `registry` outbox backlog
- DB connection saturation
- DLQ publish rate
