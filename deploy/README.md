# Korshi — Deployment

Single Ubuntu 22.04 host, Docker Compose, HTTP on port 80.

The stack (`docker-compose.yml` at the repo root):

| Service | What                                         | Port            |
|---------|----------------------------------------------|-----------------|
| `web`   | nginx serving the built admin panel + `/api` proxy | `80` (public)   |
| `api`   | Express/TypeScript backend                   | internal `3000` |

`web` reverse-proxies `/api/*` to `api`, so the panel and API share one origin
(no CORS, one port exposed).

## First time (once per server)

1. Point SSH access at the box (you'll need root or a sudo user + your SSH key).
2. Bootstrap Docker on the server:
   ```bash
   scp deploy/server-setup.sh root@<SERVER_IP>:~
   ssh root@<SERVER_IP> "bash server-setup.sh"
   ```

## Deploy (every time)

From your machine, at the repo root:
```bash
./deploy/deploy.sh <SERVER_IP>            # ssh user defaults to root
# or:  ./deploy/deploy.sh <SERVER_IP> ubuntu
```

This rsyncs `server/`, `web/`, `docker-compose.yml`, and `deploy/` to
`/opt/korshi` on the host, then runs `docker compose up -d --build`.

When it finishes:
- Panel:  `http://<SERVER_IP>/`
- API:    `http://<SERVER_IP>/api/health`

## Useful server commands

```bash
ssh root@<SERVER_IP>
cd /opt/korshi
docker compose ps             # status
docker compose logs -f web    # nginx logs
docker compose logs -f api    # backend logs
docker compose restart api
docker compose down           # stop everything
```

## HTTPS — domain is `korshiapp.kz` ✅

DNS is set: `korshiapp.kz` and `www.korshiapp.kz` both A → `188.244.115.167`.
The app defaults now point at `https://korshiapp.kz/api` and the cleartext
allowances have been removed, so the last step is to bring up the HTTPS stack:

1. Make sure ports **80** and **443** are open on the server (no Cloudflare proxy —
   Let's Encrypt needs to reach Caddy directly on 80).
2. On the server, add to `/opt/korshi/.env`:
   ```
   DOMAIN=korshiapp.kz
   ```
   (keep the existing `JWT_SECRET` and `FIREBASE_SERVICE_ACCOUNT` lines).
3. Deploy the code, then switch to the HTTPS stack (stop the old HTTP one first so
   port 80 is free for Caddy):
   ```bash
   cd /opt/korshi
   docker compose down                                    # frees :80
   docker compose -f docker-compose.https.yml up -d --build
   docker compose -f docker-compose.https.yml logs -f caddy   # watch cert issue (~30s)
   ```
   Panel + API will be live at `https://korshiapp.kz` (www redirects to root).
4. Rebuild/redistribute the apps — they already default to `https://korshiapp.kz/api`
   with no cleartext, so a plain `flutter build` is enough (no `--dart-define`
   needed anymore).

To go back to plain HTTP: `docker compose -f docker-compose.https.yml down && docker compose up -d`.

## Notes

- **HTTP only / by IP** for now (see HTTPS section above for the domain step).
- The **Flutter client** (`apps/client`) is a mobile app — it isn't part of this
  server deploy. It ships as an APK / to the stores, or as a separate web build.
- The backend is currently a **skeleton** (`/api/health` + stubbed resource
  endpoints). It deploys and runs, ready to grow real logic + a database.
- To add a database later, add a `db` service (e.g. Postgres) to
  `docker-compose.yml` and a volume; the `api` service can read its URL from an
  env var.
