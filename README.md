# ICantCook

## Backend deployment baseline

The production backend runs on a self-hosted Coolify instance, served at `https://api.idontcook.app` (see "Deploying to Coolify" below). The Coolify service runs the gunicorn web process only; background work runs in-process (there is no separate Celery worker). The runtime commands below still apply if a dedicated worker is ever deployed.

### Runtime commands

- Web: `cd api && gunicorn api.wsgi:application --log-file -`
- Worker: `cd api && celery -A api worker --loglevel=info`

### Required environment variables

- `ENVIRONMENT=production`
- `DEBUG=false`
- `DJANGO_SECRET_KEY`
- `DATABASE_URL`
- `ALLOWED_HOSTS`
- `CELERY_BROKER_URL` or `REDIS_URL`
- `CELERY_RESULT_BACKEND` or `REDIS_URL`

### Optional environment variables

- `CORS_ALLOWED_ORIGINS`
- `CSRF_TRUSTED_ORIGINS`
- `FRONTEND_URL`
- `PUBLIC_DOMAIN` (legacy `RAILWAY_PUBLIC_DOMAIN` is still honoured as a fallback)
- `OPENAI_API_KEY`
- `USDA_API_KEY`
- `GS_BUCKET_NAME`
- `GOOGLE_APPLICATION_CREDENTIALS_JSON`
- `GOOGLE_APPLICATION_CREDENTIALS`

If Google Cloud Storage credentials are not provided, media files fall back to local filesystem storage. In production, configure both `GS_BUCKET_NAME` and one of the Google credentials variables if media uploads must persist across deploys.

## Deploying to Coolify (self-hosted)

The backend also runs on a self-hosted [Coolify](https://coolify.io) instance (home-lab Mac mini). Coolify builds from this repo's `master` branch and serves the API publicly through a Cloudflare tunnel at `https://api.idontcook.app`.

### Topology

- **Coolify app:** `idontcook-web` (resource UUID `tau8jky19w9tjnqqto0phxlo`)
- **Branch:** `master` — each deploy pulls the latest commit and rebuilds.
- **Datastores:** Coolify-managed Postgres and Redis on the internal Docker network.
- **Public URL:** `https://api.idontcook.app`. TLS is terminated at the Cloudflare edge; the Cloudflare tunnel forwards plain HTTP to Coolify's Traefik proxy on the private Docker network.
- **Dashboard/API:** `http://127.0.0.1:8000` on the Coolify host (not publicly exposed — reach it over an SSH tunnel).

### Environment

Set `ENVIRONMENT=staging` (not `production`) for this deployment. Behind the Cloudflare tunnel the origin link is plain HTTP on a private network, so the production-only hardening must be relaxed:

- it avoids forcing `sslmode=require` on the internal Postgres (which does not serve TLS), and
- it disables `SECURE_SSL_REDIRECT` / secure cookies / HSTS, which otherwise cause an HTTP→HTTPS redirect loop with the tunnel.

`DEBUG` is still set explicitly to `false`. All other variables follow the baseline above (`DJANGO_SECRET_KEY`, `DATABASE_URL`, `REDIS_URL`, etc.) and are configured in Coolify's environment settings. **Never commit secrets to this repo.**

### Redeploying

Two ways to ship the latest `master`:

**1. Coolify dashboard (UI)** — from a workstation, tunnel to the dashboard, then click Redeploy:

```bash
ssh -L 8000:127.0.0.1:8000 <user>@<coolify-host>
# open http://localhost:8000 → app "idontcook-web" → Redeploy
```

**2. Coolify API** — run on the Coolify host (or through the SSH tunnel above):

```bash
curl -X POST \
  -H "Authorization: Bearer <COOLIFY_API_TOKEN>" \
  "http://127.0.0.1:8000/api/v1/deploy?uuid=tau8jky19w9tjnqqto0phxlo"
```

The call returns a `deployment_uuid`; track its status with:

```bash
curl -H "Authorization: Bearer <COOLIFY_API_TOKEN>" \
  "http://127.0.0.1:8000/api/v1/deployments/<deployment_uuid>"
```

`<COOLIFY_API_TOKEN>` is created in Coolify (Keys & Tokens) and kept in your secrets manager — not in this repo.

### Domain configuration

The app's domain is set in Coolify (`fqdn`). Because the Cloudflare tunnel forwards plain HTTP, configure it as `http://api.idontcook.app` (not `https://`) so Traefik does not add an HTTP→HTTPS redirect that loops with the tunnel — Cloudflare still serves real HTTPS to clients at the edge. Redeploy after changing it.