# Korshi — Backend (`server`)

API server for Korshi. **Node + Express + TypeScript.** Currently a skeleton:
health check + stubbed resource endpoints, ready to grow real logic and a
database. Deploys via Docker (see `deploy/README.md`).

## Run locally

```bash
cd server
npm install
npm run dev        # http://localhost:3000  (watch mode)
# build + run:
npm run build && npm start
```

## Endpoints (current)

| Method | Path                      | Status                         |
|--------|---------------------------|--------------------------------|
| GET    | `/api/health`             | ✅ real (status/version/time)  |
| GET    | `/api/reports`            | 🔲 stub (empty)                |
| GET    | `/api/announcements`      | 🔲 stub                        |
| GET    | `/api/polls`              | 🔲 stub                        |
| GET    | `/api/residents`          | 🔲 stub                        |
| POST   | `/api/residents/invite`   | ✅ returns a 6-char activation code (never expires) |

The invite endpoint mirrors the admin panel's flow: `{ phone, address, name? }`
→ `{ activationCode, expires: null }`. The code works as the resident's password
until they change it.

## Next steps

1. Add a database (e.g. Postgres) — add a `db` service + volume to the root
   `docker-compose.yml` and read `DATABASE_URL` from env.
2. Add auth (admin login for the panel; phone + code/password for residents).
3. Flesh out the stubbed resources with real CRUD.
