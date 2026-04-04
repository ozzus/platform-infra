# Local Stack

This stack starts a runnable local contour of the platform without Kubernetes.

It includes:

- `diasoft-registry`
- `diasoft-gateway`
- `diasoft-web`
- PostgreSQL
- Redis
- Redpanda
- MinIO
- Keycloak

Default local mode is intentionally **no-auth** for application flows:

- `diasoft-web` runs with `VITE_AUTH_ENABLED=false`
- `diasoft-registry` runs with `APP_SECURITY_ENABLED=false`

This keeps local startup simple and lets you test the full import -> Kafka -> gateway projection flow immediately.
Keycloak is still started for inspection and future live-auth experiments.

## Ports

- web: `http://localhost:8082`
- gateway: `http://localhost:8080`
- registry: `http://localhost:8081`
- keycloak: `http://localhost:8083`
- minio api: `http://localhost:9000`
- minio console: `http://localhost:9001`
- redpanda external broker: `localhost:19092`

## Start

```sh
cd platform-infra/local
cp .env.example .env
docker compose up --build
```

## Stop

```sh
docker compose down
```

To remove volumes too:

```sh
docker compose down -v
```

## Happy path

1. Open `http://localhost:8082`.
2. Go to the university cabinet.
3. Upload [samples/diplomas-itmo.csv](./samples/diplomas-itmo.csv).
4. Wait for the import job to become `completed`.
5. Open the HR page and verify:
   - diploma number: `D-2026-0001`
   - university code: `ITMO`
6. Open the student cabinet and create a share link.

## CLI smoke

Create import:

```sh
curl -F "file=@./samples/diplomas-itmo.csv" \
  http://localhost:8081/api/v1/universities/11111111-1111-1111-1111-111111111111/imports
```

Verify diploma:

```sh
curl -X POST http://localhost:8080/api/v1/public/verify \
  -H 'Content-Type: application/json' \
  -d '{"diplomaNumber":"D-2026-0001","universityCode":"ITMO"}'
```

## Notes

- `diasoft-gateway` uses env-only config fallback in containers, so no mounted YAML is required.
- Redpanda topics are created by the one-shot `kafka-init` service.
- Gateway schema is created by the PostgreSQL init scripts in `local/postgres/init`.
- Keycloak realm import is in `local/keycloak/diasoft-realm.json`.
- If you change ports, update `.env`.
