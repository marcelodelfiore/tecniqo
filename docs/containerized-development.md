# Containerized development stack

The complete local stack runs from the production Rails image so startup also exercises
the deployable artifact:

```text
Rails + Thruster + Solid Queue
PostgreSQL 17
Garage 2.3
Mailpit
```

## Start

Docker is the only host prerequisite. From the repository root:

```sh
docker compose up --build
```

No `.env` is required for local use. Compose contains clearly development-only defaults.
To override ports or credentials, copy `.env.example` to `.env` first.

After every service is healthy:

- Técniqo: <http://localhost:3000>
- Rails health: <http://localhost:3000/up>
- Mailpit: <http://localhost:8026>
- Garage S3 API: `127.0.0.1:3900`
- Garage admin API: `127.0.0.1:3903`

PostgreSQL is available only on the internal Compose network. Rails waits for healthy
PostgreSQL, Garage, and Mailpit, runs `db:prepare`, loads idempotent demo data, and starts
Thruster/Puma with Solid Queue inside Puma.

Seeded identities:

- `founder@tecniqo.local`
- `joao.technician@tecniqo.local`

Request a passwordless login link in Técniqo and open it from Mailpit.

## Operations

```sh
docker compose ps
docker compose logs -f web
docker compose exec web bin/rails console
docker compose exec web bin/rails db:seed
docker compose restart
docker compose down
```

`docker compose down` preserves PostgreSQL and Garage named volumes. This next command is
a destructive local reset and must only be used when all local database/evidence data may
be discarded:

```sh
docker compose down --volumes
docker compose up --build
```

Set `SEED_DATABASE=false` to skip seeds. `LOAD_DEMO_DATA` is separately gated so
production-mode seeds create demo records only when Compose explicitly enables them.

## Boundaries

Compose defaults are local-only and must not be reused on a VPS. Kamal remains the
production deployment path. A same-host Garage volume is primary storage, not backup;
production evidence requires independent backup and tested restoration.
