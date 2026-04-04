#!/usr/bin/env sh

set -eu

usage() {
  cat <<'EOF'
Usage:
  render-caddyfile.sh <domains-env-file>

Required variables in the env file:
  ACME_EMAIL
  INGRESS_HTTP_UPSTREAM
  TEAM1_BASE_DOMAIN
  TEAM2_BASE_DOMAIN
EOF
}

if [ "${1:-}" = "" ]; then
  usage
  exit 1
fi

ENV_FILE=$1
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

case "$ENV_FILE" in
  /*) ;;
  *) ENV_FILE="$REPO_ROOT/$ENV_FILE" ;;
esac

TEMPLATE_FILE="$REPO_ROOT/deploy/one-server/Caddyfile.tmpl"

if [ ! -f "$ENV_FILE" ]; then
  echo "env file not found: $ENV_FILE" >&2
  exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "template file not found: $TEMPLATE_FILE" >&2
  exit 1
fi

. "$ENV_FILE"

: "${ACME_EMAIL:?}"
: "${INGRESS_HTTP_UPSTREAM:?}"
: "${TEAM1_BASE_DOMAIN:?}"
: "${TEAM2_BASE_DOMAIN:?}"

TEAM1_DEV_HOSTS="web.dev.${TEAM1_BASE_DOMAIN}, verify.dev.${TEAM1_BASE_DOMAIN}, registry.dev.${TEAM1_BASE_DOMAIN}, auth.dev.${TEAM1_BASE_DOMAIN}"
TEAM1_PROD_HOSTS="web.${TEAM1_BASE_DOMAIN}, verify.${TEAM1_BASE_DOMAIN}, registry.${TEAM1_BASE_DOMAIN}, auth.${TEAM1_BASE_DOMAIN}"
TEAM2_DEV_HOSTS="web.dev.${TEAM2_BASE_DOMAIN}, verify.dev.${TEAM2_BASE_DOMAIN}, registry.dev.${TEAM2_BASE_DOMAIN}, auth.dev.${TEAM2_BASE_DOMAIN}"
TEAM2_PROD_HOSTS="web.${TEAM2_BASE_DOMAIN}, verify.${TEAM2_BASE_DOMAIN}, registry.${TEAM2_BASE_DOMAIN}, auth.${TEAM2_BASE_DOMAIN}"

sed \
  -e "s|{{ACME_EMAIL}}|${ACME_EMAIL}|g" \
  -e "s|{{INGRESS_HTTP_UPSTREAM}}|${INGRESS_HTTP_UPSTREAM}|g" \
  -e "s|{{TEAM1_DEV_HOSTS}}|${TEAM1_DEV_HOSTS}|g" \
  -e "s|{{TEAM1_PROD_HOSTS}}|${TEAM1_PROD_HOSTS}|g" \
  -e "s|{{TEAM2_DEV_HOSTS}}|${TEAM2_DEV_HOSTS}|g" \
  -e "s|{{TEAM2_PROD_HOSTS}}|${TEAM2_PROD_HOSTS}|g" \
  "$TEMPLATE_FILE"
