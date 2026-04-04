#!/usr/bin/env sh

set -eu

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required" >&2
  exit 1
fi

if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | sudo INSTALL_K3S_EXEC="server --disable traefik --write-kubeconfig-mode 644" sh -
fi

sudo systemctl enable --now k3s

for ns in argocd ingress-nginx cert-manager external-secrets monitoring; do
  sudo k3s kubectl create namespace "$ns" --dry-run=client -o yaml | sudo k3s kubectl apply -f -
done

sudo k3s kubectl get nodes
