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
| `apps/client`       | Resident Flutter app                    | ✅ In progress |
| `apps/admin_app`    | Chairman Flutter app                    | 🔲 Planned    |
| `web/admin_panel`   | Web admin panel (super-admin / ops)     | 🔲 Planned    |
| `server`            | Backend API (Node + Express + TS)       | ✅ Skeleton    |
| `packages/shared`   | Models, theme tokens, l10n shared by apps| 🔲 Planned    |

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
