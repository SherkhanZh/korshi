# Korshi — Architecture

## Overview

Korshi has four surfaces talking to one backend:

```
        ┌──────────────────┐         ┌──────────────────┐
        │  Resident app    │         │  Chairman app    │
        │  apps/client     │         │  apps/admin_app  │
        │  (Flutter)       │         │  (Flutter)       │
        └────────┬─────────┘         └─────────┬────────┘
                 │                             │
                 │            HTTPS / WebSocket │
                 └──────────────┬──────────────┘
                                │
                        ┌───────▼────────┐        ┌────────────────────┐
                        │    server      │◄───────│   web/admin_panel  │
                        │  (REST + RT)   │        │  (ops / super-admin)│
                        └───────┬────────┘        └────────────────────┘
                                │
                          ┌─────▼─────┐
                          │  Database │
                          └───────────┘
```

## Surfaces

- **apps/client** — resident app. Browse updates, submit issue reports, vote in
  polls, view trusted contacts, track their own requests.
- **apps/admin_app** — chairman app. Receive/triage reports, post updates &
  announcements, manage polls, update report statuses, message residents.
- **web/admin_panel** — operator/super-admin panel. Manage neighborhoods,
  chairmen, partners, and view analytics across the platform.
- **server** — single source of truth: auth, reports, updates, polls, contacts,
  notifications. Exposes an API consumed by all three clients.

## Shared code

`packages/shared` will hold Dart code reused by **client** and **admin_app**:
domain models, status/category enums, theme tokens (`AppColors`, `AppTheme`),
and the localization layer. Today these live in `apps/client/lib/`; they should
be promoted to `packages/shared` once the chairman app starts, so both apps
depend on one definition.

Suggested extraction order when `admin_app` begins:
1. `theme/` (colors + theme) → `packages/shared/lib/theme/`
2. `models/` (enums + data classes) → `packages/shared/lib/models/`
3. `l10n/` (strings + delegate) → `packages/shared/lib/l10n/`
4. `widgets/common.dart` (badges, cards, chips) → `packages/shared/lib/widgets/`

## Backend

Stack is **not decided yet**. The API contract (endpoints + JSON shapes) should
be defined first and documented here so the Flutter apps can be built against a
stable contract (mock server / OpenAPI) before the real backend lands.

Core resources the API will expose:
`auth`, `neighborhoods`, `residents`, `reports`, `updates`, `polls`,
`contacts`, `partners`, `notifications`.

## Conventions

- Two languages live in the apps from day one (RU/KK/EN); keep all user-facing
  strings in the localization map, never hardcoded.
- The monorepo can be managed with [Melos](https://melos.invertase.dev) once
  there is more than one Dart package (see `melos.yaml`).
