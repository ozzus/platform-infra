# Rollback

1. Revert the image tag change in `platform-infra`.
2. Let ArgoCD synchronize the previous revision.
3. Validate health, readiness, and key dashboards.
