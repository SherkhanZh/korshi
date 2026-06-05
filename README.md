# Korshi — Monorepo

Korshi connects KSK (housing cooperative) chairmen and residents to report and
resolve neighborhood problems.

This repository is a **monorepo** containing all parts of the product.

## Layout

```
ksk/
├── apps/
│   ├── client/         # Resident mobile app (Flutter) — the main app
│   └── admin_app/      # Chairman mobile app (Flutter) — TODO
├── web/
│   └── admin_panel/    # Admin web panel — TODO
├── server/             # Backend / API server — TODO (stack TBD)
├── packages/
│   └── shared/         # Shared Dart code (models, theme, l10n) — TODO
└── docs/               # Architecture & product docs
```

## Projects

| Path                | What it is                              | Status        |
|---------------------|-----------------------------------------|---------------|
| `apps/client`       | Resident Flutter app                    | ✅ Live data   |
| `apps/admin_app`    | Chairman Flutter app                    | 🔲 Planned    |
| `web/admin_panel`   | Web admin panel (React + Vite)          | ✅ Live data   |
| `server`            | Backend API (Node + Express + SQLite)   | ✅ Persistent  |
| `packages/shared`   | Models, theme tokens, l10n shared by apps| 🔲 Planned    |

## Accounts

The backend seeds a super admin, one neighborhood admin, and a few residents on
first boot.

- **Super admin (you):** `superadmin@korshi.kz` / `super123` — logs into the same
  panel and gets a **Районы** screen to create neighborhoods. Creating a
  neighborhood means: set its name + the neighborhood admin's login and password.
- **Neighborhood admin:** `admin@korshi.kz` / `admin123` — manages one
  neighborhood ("мкр Кок-Тобе"): its reports, residents, polls, announcements,
  contacts and cover.
- **Resident app:** phone `+7 777 123 45 67`, invite code `AB12-48` (residents log
  in with phone + invite code; they may set a personal password, and the invite
  code keeps working as a password until they do).

### Multi-neighborhood isolation

Every neighborhood is a separate tenant. A neighborhood admin only ever sees its
own data, and residents only see their own neighborhood's announcements, polls,
contacts and cover. The super admin manages neighborhoods but not their day-to-day
content.

Auth uses JWTs (the token carries the principal's role + neighborhood). Set
`JWT_SECRET` in production (see `docker-compose.yml`). Data persists in SQLite on
the `korshi_data` Docker volume; existing single-tenant databases migrate
automatically into the default neighborhood on first boot.

## Deployment

Single Ubuntu host, Docker Compose, HTTP on port 80 (`web` = admin panel + `/api`
proxy, `api` = backend). One-time: `deploy/server-setup.sh` on the box. Then:

```bash
./deploy/deploy.sh <SERVER_IP>
```

Full guide: [deploy/README.md](deploy/README.md).

## Getting started (client)

```bash
cd apps/client
flutter pub get
flutter run
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the high-level design and
how the pieces fit together.
