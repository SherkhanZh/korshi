# Korshi — Admin Panel (`web/admin_panel`)

Operator / super-admin web panel for Korshi. React + Vite + TypeScript +
Tailwind, styled to match the resident app's green/cream design. UI in Russian.
Currently runs on **mock data** (no backend yet).

## Run

```bash
cd web/admin_panel
npm install
npm run dev        # http://localhost:5174
```

Login is mocked — any email + password works.

## Sections

- **Обзор (Dashboard)** — KPIs + charts (reports by category, status breakdown), recent reports.
- **Заявки (Reports)** — table with status filters & search, detail modal, status changes.
- **Новости (Updates)** — create/pin neighborhood announcements & events.
- **Опросы (Polls)** — create polls, view vote breakdowns.
- **Жители (Residents)** — list + **invite flow**: enter phone + address → server
  generates a 6-char code → resident logs into the client app with phone + code.
  The code works as their password and stays valid until they choose to set
  their own (optional — kept simple for elderly residents who may never change it).
- **Справочник (Directory)** — neighborhoods, contacts, trusted partners.

## Notes

- Mock data lives in `src/data/mockData.ts`; swap for API calls when the
  backend lands. The 6-char code generator (`generateInviteCode`) mocks the
  server side of the invite flow.
- Design tokens are in `tailwind.config.js` (mirrors `apps/client` `AppColors`).
