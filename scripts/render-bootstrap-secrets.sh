#!/usr/bin/env sh

set -eu

usage() {
  cat <<'EOF'
Usage:
  render-bootstrap-secrets.sh <terraform-output-json> <environment>

Example:
  terraform -chdir=terraform/yandex/envs/nonprod output -json > /tmp/nonprod-outputs.json
  ./scripts/render-bootstrap-secrets.sh /tmp/nonprod-outputs.json nonprod > /tmp/bootstrap-secrets.yaml

The script renders the two bootstrap secrets required before Argo can sync
the External Secrets and External DNS applications:
  - yandex-lockbox-authorized-key
  - yc-externaldns-auth
EOF
}

if [ "${1:-}" = "" ] || [ "${2:-}" = "" ]; then
  usage
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

OUTPUT_JSON=$1
ENVIRONMENT=$2

external_secrets_json=$(jq -r '.bootstrap_authorized_keys.value.external_secrets' "$OUTPUT_JSON")
external_dns_json=$(jq -r '.bootstrap_authorized_keys.value.external_dns' "$OUTPUT_JSON")

cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: yandex-lockbox-authorized-key
  namespace: external-secrets
  labels:
    app.kubernetes.io/part-of: diasoft-platform
    app.kubernetes.io/component: bootstrap
    diasoft.io/environment: ${ENVIRONMENT}
type: Opaque
stringData:
  authorized-key.json: |
$(printf '%s\n' "$external_secrets_json" | jq '.' | sed 's/^/    /')
---
apiVersion: v1
kind: Secret
metadata:
  name: yc-externaldns-auth
  namespace: external-dns
  labels:
    app.kubernetes.io/part-of: diasoft-platform
    app.kubernetes.io/component: bootstrap
    diasoft.io/environment: ${ENVIRONMENT}
type: Opaque
stringData:
  authorized-key.json: |
$(printf '%s\n' "$external_dns_json" | jq '.' | sed 's/^/    /')
EOF
