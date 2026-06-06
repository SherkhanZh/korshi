# Korshi — Chairman App (`apps/admin_app`)

Flutter app for KSK **chairmen** (neighborhood admins) to triage resident
reports, post bilingual announcements, run polls, manage residents, and update
the neighborhood cover. It talks to the same backend as the resident app and web
panel, using the **admin** JWT endpoints (`/api/admin/*`, `/api/auth/admin/login`).

Status: **first cut** — login, dashboard, reports triage (status/reply/contractor/
photo), announcements, polls (with visibility), residents + invite, cover upload.

## Layout

```
lib/
├── main.dart            # app entry + auth-gated routing
├── theme.dart           # palette, Panel, Pill, category/status helpers
├── api.dart             # ApiConfig, Api client, admin session (JWT)
├── models.dart          # typed models (reports, polls, announcements, residents)
├── repo.dart            # typed API calls
├── widgets.dart         # Loader (async + pull-to-refresh), Header
└── screens/
    ├── login.dart
    ├── shell.dart       # bottom-nav shell
    ├── dashboard.dart   # stats + cover upload
    ├── reports.dart     # triage + detail sheet
    ├── announcements.dart
    ├── polls.dart
    └── residents.dart
```

## Run

This directory contains source + `pubspec.yaml` but no platform folders yet.
Generate them once, then run:

```bash
cd apps/admin_app
flutter create --org com.korshi --project-name korshi_admin .
flutter pub get
flutter run
```

`flutter create` only adds the missing `android/`, `ios/`, etc. — it won't
overwrite the existing `lib/` or `pubspec.yaml`.

Point at a local backend if needed:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

Default account: `admin@korshi.kz` / `admin123` (seeded neighborhood admin).
The super admin manages neighborhoods in the **web panel**, not here.
