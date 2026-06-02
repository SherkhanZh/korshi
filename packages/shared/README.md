# Korshi — Shared Dart Package (`packages/shared`)

Code shared between the Flutter apps (`apps/client`, `apps/admin_app`):
domain models, status/category enums, theme tokens, localization, and common
widgets.

Status: **planned** — placeholder.

Currently these live in `apps/client/lib/` (`theme/`, `models/`, `l10n/`,
`widgets/common.dart`). When the chairman app starts, promote them here as a
package both apps depend on, so there's a single definition of the design
system and data model.

Scaffold with:

```bash
cd packages
flutter create --template=package shared
```
