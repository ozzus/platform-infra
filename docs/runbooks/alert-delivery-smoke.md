# Alert Delivery Smoke

1. Use `nonprod` first.
2. Create a temporary alert with a short `for` window in the `platform-observability` manifests.
3. Sync the observability application through ArgoCD.
4. Confirm the alert appears in Prometheus and Alertmanager.
5. Verify the configured receiver gets the alert and the resolved notification.
6. Remove the temporary alert and sync again.
7. Repeat in `stage` before any `prod` cutover.

## Expected result

- alert is visible in Prometheus
- Alertmanager routes it to the configured receiver
- resolved notification is delivered after the alert clears
