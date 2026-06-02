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

## Notes

- **HTTP only / by IP** for now. To add a domain + HTTPS later: point DNS at the
  IP, add `server_name` + a certbot/Let's Encrypt companion (or Caddy/Traefik)
  in front. Ask and I'll wire it.
- The **Flutter client** (`apps/client`) is a mobile app — it isn't part of this
  server deploy. It ships as an APK / to the stores, or as a separate web build.
- The backend is currently a **skeleton** (`/api/health` + stubbed resource
  endpoints). It deploys and runs, ready to grow real logic + a database.
- To add a database later, add a `db` service (e.g. Postgres) to
  `docker-compose.yml` and a volume; the `api` service can read its URL from an
  env var.
