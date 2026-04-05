# One-Server Multi-Team Deploy

This document describes the target bootstrap path for a single public host that runs:

- global host-level `Caddy`
- `k3s` single-node
- shared ingress / cert-manager / ArgoCD / observability
- isolated team application stacks behind separate root domains

## Target model

- only `22`, `80`, and `443` are public
- `Caddy` is the only public edge on the host
- `Caddy` proxies to `ingress-nginx` on a fixed local upstream
- all service pods stay internal to `k3s`
- each team gets:
  - its own root domain
  - its own `web`, `verify`, `registry`, and `auth` hosts
  - its own app and auth namespaces
  - its own pre-created Kubernetes secrets

Selected root domains:

- `team1` -> `diplomverify.ru`
- `team2` -> `edu-proof.ru`

## Bootstrap order

1. Prepare the server and install base packages with `scripts/bootstrap-host.sh`.
2. Install `k3s` without Traefik using `scripts/bootstrap-k3s.sh`.
3. Apply bootstrap manifests for `ClusterIssuer` and `ClusterSecretStore`.
4. Sync shared addon Applications in ArgoCD.
5. Render and apply tenant secrets using `scripts/render-tenant-secrets.sh`.
6. Sync the tenant-specific `keycloak`, `gateway`, `registry`, and `web` Applications.
7. Point both root domains to the same server IP.
8. Validate HTTPS and app isolation for both teams.

## CI/CD prerequisites

Before this model can be used as the canonical deploy path, GitHub must provide:

- repositories for `diasoft-gateway`, `diasoft-registry`, `diasoft-web`, and `platform-infra`
- GitHub Actions enabled for all four repositories
- GHCR package publishing for service images
- protected `main` branches and manual production approvals
- repository or organization secrets for cross-repo reads, `platform-infra` promotion, and live smoke

Service repo promotion jobs expect these variables:

- `PLATFORM_INFRA_REPO_URL`
- `PLATFORM_INFRA_PUSH_URL`
- `PLATFORM_INFRA_BASE_BRANCH`
- `PLATFORM_INFRA_GITHUB_REPO`
- `PLATFORM_INFRA_GITHUB_TOKEN`
- `CROSS_REPO_GITHUB_TOKEN`
- `GHCR_TOKEN`

Bootstrap and live smoke jobs expect:

- `BOOTSTRAP_SSH_PRIVATE_KEY`
- `TEAM1_BASE_DOMAIN`
- `TEAM2_BASE_DOMAIN`
- `SERVER_PUBLIC_IP`
- `ACME_EMAIL`

## Important notes

- For a single-host public deployment, use the `single-node` addon overlays.
- For service promotion, `platform-infra` is the deploy source of truth.
- Canonical CI/CD is now `GitHub Actions -> GHCR -> platform-infra -> ArgoCD`.
- Team 1 service repos should update only the `helm/tenants/team1/*` overlays.
- Team 2 can use the same deployment model with different images and root domains.
