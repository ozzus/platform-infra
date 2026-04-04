# Bootstrap Secrets

Before Argo can fully reconcile `external-secrets` and `external-dns`, the target cluster
needs two bootstrap secrets created manually from Terraform outputs:

- `yandex-lockbox-authorized-key` in namespace `external-secrets`
- `yc-externaldns-auth` in namespace `external-dns`

These are the only intentionally manual bootstrap secrets in the cutover path.
Everything else is expected to come from `ExternalSecret` objects backed by Yandex Lockbox.

## Source of truth

Terraform outputs them from `bootstrap_authorized_keys` in:

- `terraform/yandex/envs/nonprod`
- `terraform/yandex/envs/prod`

## Render manifest

```sh
terraform -chdir=terraform/yandex/envs/nonprod output -json > /tmp/nonprod-outputs.json
sh scripts/render-bootstrap-secrets.sh /tmp/nonprod-outputs.json nonprod > /tmp/nonprod-bootstrap-secrets.yaml
```

For prod:

```sh
terraform -chdir=terraform/yandex/envs/prod output -json > /tmp/prod-outputs.json
sh scripts/render-bootstrap-secrets.sh /tmp/prod-outputs.json prod > /tmp/prod-bootstrap-secrets.yaml
```

## Apply

```sh
kubectl apply -f /tmp/nonprod-bootstrap-secrets.yaml
kubectl apply -f /tmp/prod-bootstrap-secrets.yaml
```

## Validation

```sh
kubectl -n external-secrets get secret yandex-lockbox-authorized-key
kubectl -n external-dns get secret yc-externaldns-auth
```

Only after these secrets exist should Argo sync:

- `external-secrets-*`
- `external-dns-*`
- `platform-bootstrap-*`
