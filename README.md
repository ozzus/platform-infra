# platform-infra

Infrastructure-as-code and GitOps repository for the Diasoft platform.

## Contents

- Terraform for Yandex Cloud managed infrastructure in `nonprod` and `prod`
- Helm charts and environment overlays for application deployment
- addon values for ingress, certificates, secrets, DNS, monitoring, logging, and tracing
- ArgoCD applications for product services and cluster addons
- Cluster bootstrap and observability manifests
- bootstrap tooling for External Secrets and External DNS
- Runbooks, cutover checklist, and platform summaries
- GitHub Actions validation and live smoke workflows

## CI/CD direction

Canonical platform CI/CD is now:

- `GitHub Actions` for validate, build, publish, and promotion
- `ghcr.io` for service images
- `platform-infra` on GitHub as the deploy source of truth for ArgoCD
- `k3s + ingress-nginx + Caddy` as the target single-node runtime

Bootstrap secret manifests can be rendered from Terraform outputs with:

```sh
sh scripts/render-bootstrap-secrets.sh /path/to/terraform-output.json nonprod
```

For a single-host local stack without Kubernetes, see [local/README.md](./local/README.md).
