#!/usr/bin/env sh

set -eu

usage() {
  cat <<'EOF'
Usage:
  render-tenant-secrets.sh <team> <environment> <secrets-env-file>

Required env variables:
  GATEWAY_DATABASE_URL
  GATEWAY_REDIS_ADDR
  GATEWAY_REDIS_PASSWORD
  GATEWAY_KAFKA_BROKERS
  REGISTRY_DATABASE_URL
  REGISTRY_DATABASE_USERNAME
  REGISTRY_DATABASE_PASSWORD
  REGISTRY_KAFKA_BOOTSTRAP_SERVERS
  REGISTRY_OBJECT_STORAGE_ACCESS_KEY
  REGISTRY_OBJECT_STORAGE_SECRET_KEY
  KEYCLOAK_ADMIN_USERNAME
  KEYCLOAK_ADMIN_PASSWORD
  KEYCLOAK_DB_HOST
  KEYCLOAK_DB_PORT
  KEYCLOAK_DB_USERNAME
  KEYCLOAK_DB_PASSWORD

The script renders pre-created Kubernetes Secrets for a single team/environment.
EOF
}

if [ "${1:-}" = "" ] || [ "${2:-}" = "" ] || [ "${3:-}" = "" ]; then
  usage
  exit 1
fi

TEAM=$1
ENVIRONMENT=$2
SECRETS_FILE=$3

if [ ! -f "$SECRETS_FILE" ]; then
  echo "secrets env file not found: $SECRETS_FILE" >&2
  exit 1
fi

. "$SECRETS_FILE"

: "${GATEWAY_DATABASE_URL:?}"
: "${GATEWAY_REDIS_ADDR:?}"
: "${GATEWAY_REDIS_PASSWORD:?}"
: "${GATEWAY_KAFKA_BROKERS:?}"
: "${REGISTRY_DATABASE_URL:?}"
: "${REGISTRY_DATABASE_USERNAME:?}"
: "${REGISTRY_DATABASE_PASSWORD:?}"
: "${REGISTRY_KAFKA_BOOTSTRAP_SERVERS:?}"
: "${REGISTRY_OBJECT_STORAGE_ACCESS_KEY:?}"
: "${REGISTRY_OBJECT_STORAGE_SECRET_KEY:?}"
: "${KEYCLOAK_ADMIN_USERNAME:?}"
: "${KEYCLOAK_ADMIN_PASSWORD:?}"
: "${KEYCLOAK_DB_HOST:?}"
: "${KEYCLOAK_DB_PORT:?}"
: "${KEYCLOAK_DB_USERNAME:?}"
: "${KEYCLOAK_DB_PASSWORD:?}"

APP_NAMESPACE="${TEAM}-${ENVIRONMENT}-app"
AUTH_NAMESPACE="${TEAM}-${ENVIRONMENT}-auth"

cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${TEAM}-gateway-${ENVIRONMENT}-secrets
  namespace: ${APP_NAMESPACE}
type: Opaque
stringData:
  database_url: ${GATEWAY_DATABASE_URL}
  redis_addr: ${GATEWAY_REDIS_ADDR}
  redis_password: ${GATEWAY_REDIS_PASSWORD}
  kafka_brokers: ${GATEWAY_KAFKA_BROKERS}
---
apiVersion: v1
kind: Secret
metadata:
  name: ${TEAM}-registry-${ENVIRONMENT}-secrets
  namespace: ${APP_NAMESPACE}
type: Opaque
stringData:
  database_url: ${REGISTRY_DATABASE_URL}
  database_username: ${REGISTRY_DATABASE_USERNAME}
  database_password: ${REGISTRY_DATABASE_PASSWORD}
  kafka_bootstrap_servers: ${REGISTRY_KAFKA_BOOTSTRAP_SERVERS}
  kafka_username: ""
  kafka_password: ""
  object_storage_access_key: ${REGISTRY_OBJECT_STORAGE_ACCESS_KEY}
  object_storage_secret_key: ${REGISTRY_OBJECT_STORAGE_SECRET_KEY}
---
apiVersion: v1
kind: Secret
metadata:
  name: ${TEAM}-keycloak-${ENVIRONMENT}-secrets
  namespace: ${AUTH_NAMESPACE}
type: Opaque
stringData:
  username: ${KEYCLOAK_ADMIN_USERNAME}
  password: ${KEYCLOAK_ADMIN_PASSWORD}
  db_host: ${KEYCLOAK_DB_HOST}
  db_port: ${KEYCLOAK_DB_PORT}
  db_username: ${KEYCLOAK_DB_USERNAME}
  db_password: ${KEYCLOAK_DB_PASSWORD}
EOF
