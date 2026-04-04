#!/usr/bin/env sh

set -eu

usage() {
  cat <<'EOF'
Usage:
  bootstrap-host.sh <domains-env-file>

Bootstraps a single Ubuntu host for the one-server multi-team deployment:
  - installs Caddy and base host packages
  - configures a default-deny firewall with only 22/80/443 open
  - installs k3s without Traefik
  - renders /etc/caddy/Caddyfile from the repo template

Example:
  ./scripts/bootstrap-host.sh deploy/one-server/domains.env.example
EOF
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

DOMAINS_ENV_FILE=$1

if [ ! -f "$DOMAINS_ENV_FILE" ]; then
  echo "domains env file not found: $DOMAINS_ENV_FILE" >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required" >&2
  exit 1
fi

sudo apt-get update
sudo apt-get install -y curl ca-certificates gnupg jq caddy ufw

sh ./scripts/bootstrap-k3s.sh

mkdir -p deploy/one-server/rendered
sh ./scripts/render-caddyfile.sh "$DOMAINS_ENV_FILE" > deploy/one-server/rendered/Caddyfile

sudo install -d /etc/caddy
sudo install -m 0644 deploy/one-server/rendered/Caddyfile /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
sudo systemctl restart caddy

if command -v ufw >/dev/null 2>&1; then
  sudo ufw --force reset
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow 22/tcp
  sudo ufw allow 80/tcp
  sudo ufw allow 443/tcp
  sudo ufw --force enable
fi

echo "Host bootstrap completed."
