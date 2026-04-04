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

Bootstrap secret manifests can be rendered from Terraform outputs with:

```sh
sh scripts/render-bootstrap-secrets.sh /path/to/terraform-output.json nonprod
```

For a single-host local stack without Kubernetes, see [local/README.md](./local/README.md).
